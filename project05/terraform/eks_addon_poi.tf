resource "aws_iam_policy" "aws_load_balancer_controller" {
  name   = "${local.project_name}-aws-load-balancer-controller-policy"
  policy = file("${path.module}/manifests/aws-load-balancer-controller-policy.json")
}

# EKS Pod Identity용 AssumeRole 정책
# VPC CNI, EBS CSI, AWS Load Balancer Controller의 Pod Identity 역할에 공통으로 사용
# eks-pod-identity-agent 애드온에서 발급하는 토큰을 신뢰하도록 구성
# SourceArn 조건으로 동일 클러스터의 Pod Identity Association에서만 호출 허용
# SourceAccount 조건으로 현재 계정에서만 허용하도록 제한
# 리소스는 for_each를 사용하여 각 서비스 별로 생성
# - ebs_csi: aws-ebs-csi-driver 컨트롤러
# - vpc_cni: aws-node 데몬셋
# - aws_load_balancer_controller: ALB 컨트롤러 헬름 릴리스
# https://docs.aws.amazon.com/eks/latest/userguide/pod-identity.html
# https://docs.aws.amazon.com/ko_kr/eks/latest/userguide/pod-id-assume-role.html
# Pod Identity를 사용할 경우 OIDC 공급자 없이도 STS를 사용할 수 있음
# 하지만 다른 구성 요소에서 OIDC를 사용할 수 있으므로 기존 설정은 유지함
# 이 문서는 Pod Identity Agent 애드온이 설치된 이후에만 유효
# 따라서 association 리소스에서 애드온에 대한 depends_on을 지정함
# assume role 정책에는 TagSession 권한도 포함하여 AWS Load Balancer Controller의 태깅 요구 사항 충족
# session tagging을 사용하면 리소스에 컨트롤러가 태그를 추가할 수 있음
# Terraform에서는 toset을 활용하여 고정된 세 가지 항목에 대해 반복 생성
# 필요 시 향후 다른 애드온도 쉽게 추가 가능
# 역할 이름은 프로젝트 이름 기반으로 고유하게 생성
# 정책 문서는 aws_iam_policy_document 데이터 소스를 사용하여 JSON 생성
# 각 역할은 해당 서비스가 필요로 하는 AWS 관리형 정책을 연결
# Pod Identity association 리소스는 namespace와 service account를 지정하여 EKS와 연결

# Pod Identity용 AssumeRole 정책 문서
# (위 설명 주석은 유지, 아래 리소스는 실제 정의)
data "aws_iam_policy_document" "pod_identity_assume_role" {
  for_each = toset([
    "ebs_csi",
    "vpc_cni",
    "aws_load_balancer_controller",
  ])

  statement {
    actions = [
      "sts:AssumeRole",
      "sts:TagSession",
    ]
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["pods.eks.amazonaws.com"]
    }

    condition {
      test     = "ArnLike"
      variable = "aws:SourceArn"
      values = [
        "arn:aws:eks:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:podidentityassociation/${aws_eks_cluster.this.name}/*",
      ]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [data.aws_caller_identity.current.account_id]
    }
  }
}

# EBS CSI Controller를 위한 Pod Identity 역할
resource "aws_iam_role" "ebs_csi" {
  name               = "${local.project_name}-ebs-csi-role"
  assume_role_policy = data.aws_iam_policy_document.pod_identity_assume_role["ebs_csi"].json
}

resource "aws_iam_role_policy_attachment" "ebs_csi" {
  role       = aws_iam_role.ebs_csi.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
}

resource "aws_eks_pod_identity_association" "ebs_csi" {
  cluster_name    = aws_eks_cluster.this.name
  namespace       = "kube-system"
  service_account = "ebs-csi-controller-sa"
  role_arn        = aws_iam_role.ebs_csi.arn

  depends_on = [
    aws_eks_addon.pod_identity,
    aws_eks_addon.ebs_csi,
  ]
}

# VPC CNI를 위한 Pod Identity 역할
resource "aws_iam_role" "vpc_cni" {
  name               = "${local.project_name}-vpc-cni-role"
  assume_role_policy = data.aws_iam_policy_document.pod_identity_assume_role["vpc_cni"].json
}

resource "aws_iam_role_policy_attachment" "vpc_cni" {
  role       = aws_iam_role.vpc_cni.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

resource "aws_eks_pod_identity_association" "vpc_cni" {
  cluster_name    = aws_eks_cluster.this.name
  namespace       = "kube-system"
  service_account = "aws-node"
  role_arn        = aws_iam_role.vpc_cni.arn

  depends_on = [
    aws_eks_addon.pod_identity,
    aws_eks_addon.vpc_cni,
  ]
}

# AWS Load Balancer Controller를 위한 Pod Identity 역할
resource "aws_iam_role" "aws_load_balancer_controller" {
  name               = "${local.project_name}-aws-load-balancer-controller"
  assume_role_policy = data.aws_iam_policy_document.pod_identity_assume_role["aws_load_balancer_controller"].json
}

resource "aws_iam_role_policy_attachment" "aws_load_balancer_controller" {
  policy_arn = aws_iam_policy.aws_load_balancer_controller.arn
  role       = aws_iam_role.aws_load_balancer_controller.name
}

resource "kubernetes_service_account" "aws_load_balancer_controller" {
  metadata {
    name      = "aws-load-balancer-controller"
    namespace = "kube-system"
    labels = {
      "app.kubernetes.io/name"      = "aws-load-balancer-controller"
      "app.kubernetes.io/component" = "controller"
    }
  }
}

resource "aws_eks_pod_identity_association" "aws_load_balancer_controller" {
  cluster_name    = aws_eks_cluster.this.name
  namespace       = "kube-system"
  service_account = kubernetes_service_account.aws_load_balancer_controller.metadata[0].name
  role_arn        = aws_iam_role.aws_load_balancer_controller.arn

  depends_on = [
    aws_eks_addon.pod_identity,
    kubernetes_service_account.aws_load_balancer_controller,
  ]
}

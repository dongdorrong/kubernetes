# EKS Pod Identity용 AssumeRole 정책
# EBS CSI, AWS Load Balancer Controller 등 Pod Identity 역할에 공통으로 사용
# eks-pod-identity-agent 애드온에서 발급하는 토큰을 신뢰하도록 구성
# SourceArn 조건으로 동일 클러스터의 Pod Identity Association에서만 호출 허용
# SourceAccount 조건으로 현재 계정에서만 허용하도록 제한
# 리소스는 for_each를 사용하여 각 서비스 별로 생성
# - ebs_csi: aws-ebs-csi-driver 컨트롤러
# (VPC CNI는 노드 IAM 역할로 관리하기로 결정하여 Pod Identity 리스트에서 제외)
# - aws_load_balancer_controller: ALB 컨트롤러 헬름 릴리스
# - network_flow_monitor: AWS Network Flow Monitor Agent
# - node_monitoring: EKS Node Monitoring Agent
# - privateca_connector: AWS Private CA Connector for Kubernetes
# - mountpoint_s3_csi: Mountpoint for Amazon S3 CSI 드라이버 컨트롤러
# - efs_csi: Amazon EFS CSI 드라이버 컨트롤러
# https://docs.aws.amazon.com/eks/latest/userguide/pod-identity.html
# https://docs.aws.amazon.com/ko_kr/eks/latest/userguide/pod-id-assume-role.html
# Pod Identity를 사용할 경우 OIDC 공급자 없이도 STS를 사용할 수 있음
# 하지만 다른 구성 요소에서 OIDC를 사용할 수 있으므로 기존 설정은 유지함
# 이 문서는 Pod Identity Agent 애드온이 설치된 이후에만 유효
# 따라서 association 리소스에서 애드온에 대한 depends_on을 지정함
# assume role 정책에는 TagSession 권한도 포함하여 AWS Load Balancer Controller의 태깅 요구 사항 충족
# session tagging을 사용하면 리소스에 컨트롤러가 태그를 추가할 수 있음
# Terraform에서는 toset을 활용하여 고정된 여러 항목에 대해 반복 생성
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
      "aws_load_balancer_controller",
      "network_flow_monitor",
      "node_monitoring",
      "privateca_connector",
      "mountpoint_s3_csi",
      "efs_csi",
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

# AWS Network Flow Monitor Agent를 위한 Pod Identity 역할
resource "aws_iam_policy" "network_flow_monitor" {
    name   = "${local.project_name}-network-flow-monitor-policy"
    policy = file("${path.module}/manifests/network-flow-monitor-policy.json")
}

resource "aws_iam_role" "network_flow_monitor" {
    name               = "${local.project_name}-network-flow-monitor"
    assume_role_policy = data.aws_iam_policy_document.pod_identity_assume_role["network_flow_monitor"].json
}

resource "aws_iam_role_policy_attachment" "network_flow_monitor" {
    policy_arn = aws_iam_policy.network_flow_monitor.arn
    role       = aws_iam_role.network_flow_monitor.name
}

resource "aws_eks_pod_identity_association" "network_flow_monitor" {
    cluster_name    = aws_eks_cluster.this.name
    namespace       = "kube-system"
    service_account = "aws-network-flow-monitoring-agent"
    role_arn        = aws_iam_role.network_flow_monitor.arn

    depends_on = [
      aws_eks_addon.pod_identity,
      aws_eks_addon.network_flow_monitor,
    ]
}

# 노드 모니터링 에이전트를 위한 Pod Identity 역할
resource "aws_iam_policy" "node_monitoring" {
    name   = "${local.project_name}-node-monitoring-policy"
    policy = file("${path.module}/manifests/node-monitoring-policy.json")
}

resource "aws_iam_role" "node_monitoring" {
    name               = "${local.project_name}-node-monitoring"
    assume_role_policy = data.aws_iam_policy_document.pod_identity_assume_role["node_monitoring"].json
}

resource "aws_iam_role_policy_attachment" "node_monitoring" {
    policy_arn = aws_iam_policy.node_monitoring.arn
    role       = aws_iam_role.node_monitoring.name
}

resource "aws_eks_pod_identity_association" "node_monitoring" {
    cluster_name    = aws_eks_cluster.this.name
    namespace       = "kube-system"
    service_account = "eks-node-monitoring-agent"
    role_arn        = aws_iam_role.node_monitoring.arn

    depends_on = [
      aws_eks_addon.pod_identity,
      aws_eks_addon.node_monitoring,
    ]
}

# AWS Private CA Connector for Kubernetes를 위한 Pod Identity 역할
resource "aws_iam_policy" "privateca_connector" {
    name   = "${local.project_name}-privateca-connector-policy"
    policy = file("${path.module}/manifests/aws-privateca-connector-policy.json")
}

resource "aws_iam_role" "privateca_connector" {
    name               = "${local.project_name}-privateca-connector"
    assume_role_policy = data.aws_iam_policy_document.pod_identity_assume_role["privateca_connector"].json
}

resource "aws_iam_role_policy_attachment" "privateca_connector" {
    policy_arn = aws_iam_policy.privateca_connector.arn
    role       = aws_iam_role.privateca_connector.name
}

resource "aws_eks_pod_identity_association" "privateca_connector" {
    cluster_name    = aws_eks_cluster.this.name
    namespace       = "aws-pca-connector"
    service_account = "aws-privateca-connector-for-kubernetes"
    role_arn        = aws_iam_role.privateca_connector.arn

    depends_on = [
      aws_eks_addon.pod_identity,
      aws_eks_addon.privateca_connector,
    ]
}

# Mountpoint for Amazon S3 CSI 드라이버를 위한 Pod Identity 역할
resource "aws_iam_policy" "mountpoint_s3_csi" {
    name   = "${local.project_name}-mountpoint-s3-csi-policy"
    policy = file("${path.module}/manifests/mountpoint-s3-csi-policy.json")
}

resource "aws_iam_role" "mountpoint_s3_csi" {
    name               = "${local.project_name}-mountpoint-s3-csi"
    assume_role_policy = data.aws_iam_policy_document.pod_identity_assume_role["mountpoint_s3_csi"].json
}

resource "aws_iam_role_policy_attachment" "mountpoint_s3_csi" {
    policy_arn = aws_iam_policy.mountpoint_s3_csi.arn
    role       = aws_iam_role.mountpoint_s3_csi.name
}

resource "aws_eks_pod_identity_association" "mountpoint_s3_csi" {
    cluster_name    = aws_eks_cluster.this.name
    namespace       = "kube-system"
    service_account = "mountpoint-s3-csi-controller-sa"
    role_arn        = aws_iam_role.mountpoint_s3_csi.arn

    depends_on = [
      aws_eks_addon.pod_identity,
      aws_eks_addon.mountpoint_s3_csi,
    ]
}

# Amazon EFS CSI 드라이버를 위한 Pod Identity 역할
resource "aws_iam_role" "efs_csi" {
    name               = "${local.project_name}-efs-csi-role"
    assume_role_policy = data.aws_iam_policy_document.pod_identity_assume_role["efs_csi"].json
}

resource "aws_iam_role_policy_attachment" "efs_csi" {
    policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEFSCSIDriverPolicy"
    role       = aws_iam_role.efs_csi.name
}

resource "aws_eks_pod_identity_association" "efs_csi" {
    cluster_name    = aws_eks_cluster.this.name
    namespace       = "kube-system"
    service_account = "efs-csi-controller-sa"
    role_arn        = aws_iam_role.efs_csi.arn

    depends_on = [
      aws_eks_addon.pod_identity,
      aws_eks_addon.efs_csi,
    ]
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
# 2025-09-27 
# - 기본 노드 그룹, Karpenter의 노드 IAM 역할에 부여한 정책으로 관리하고 있음
# - Pod Identity를 통해서 관리할 경우, 정책 마이그레이션이 필요하여 복잡성을 야기함.
# - 그래서 VPC CNI의 경우 Pod Identity로 관리하지 않기로 함
# resource "aws_iam_role" "vpc_cni" {
#     name               = "${local.project_name}-vpc-cni-role"
#     assume_role_policy = data.aws_iam_policy_document.pod_identity_assume_role["vpc_cni"].json
# }

# resource "aws_iam_role_policy_attachment" "vpc_cni" {
#     role       = aws_iam_role.vpc_cni.name
#     policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
# }

# resource "aws_eks_pod_identity_association" "vpc_cni" {
#     cluster_name    = aws_eks_cluster.this.name
#     namespace       = "kube-system"
#     service_account = "aws-node"
#     role_arn        = aws_iam_role.vpc_cni.arn

#     depends_on = [
#       aws_eks_addon.pod_identity,
#       aws_eks_addon.vpc_cni,
#     ]
# }

# AWS Load Balancer Controller를 위한 Pod Identity 역할
resource "aws_iam_role" "aws_load_balancer_controller" {
    name               = "${local.project_name}-aws-load-balancer-controller"
    assume_role_policy = data.aws_iam_policy_document.pod_identity_assume_role["aws_load_balancer_controller"].json
}

resource "aws_iam_policy" "aws_load_balancer_controller" {
    name   = "${local.project_name}-aws-load-balancer-controller-policy"
    policy = file("${path.module}/manifests/aws-load-balancer-controller-policy.json")
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

resource "aws_iam_policy" "aws_load_balancer_controller" {
    name = "${local.project_name}-aws-load-balancer-controller-policy"
    policy = file("${path.module}/manifests/aws-load-balancer-controller-policy.json")
}

# EKS Pod Identity용 AssumeRole 정책
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
        effect  = "Allow"

        principals {
            identifiers = ["pods.eks.amazonaws.com"]
            type        = "Service"
        }

        condition {
            test     = "ArnLike"
            variable = "aws:SourceArn"
            values = [
                "arn:aws:eks:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:podidentityassociation/${aws_eks_cluster.this.name}/*"
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

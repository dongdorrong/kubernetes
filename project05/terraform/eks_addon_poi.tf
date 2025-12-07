data "aws_iam_policy_document" "pod_identity_assume_role" {
  statement {
    effect = "Allow"

    principals {
      identifiers = ["pods.eks.amazonaws.com"]
      type        = "Service"
    }

    actions = [
      "sts:AssumeRole",
      "sts:TagSession"
    ]
  }
}

####################################################
# VPC-CNI
####################################################
resource "aws_iam_role" "vpc_cni" {
  name               = "${local.project_name}-vpc-cni-role"
  assume_role_policy = data.aws_iam_policy_document.pod_identity_assume_role.json
}

resource "aws_iam_role_policy_attachment" "vpc_cni" {
  role       = aws_iam_role.vpc_cni.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

####################################################
# EBS CSI Controller
####################################################
resource "aws_iam_role" "ebs_csi" {
  name               = "${local.project_name}-ebs-csi-role"
  assume_role_policy = data.aws_iam_policy_document.pod_identity_assume_role.json
}

resource "aws_iam_role_policy_attachment" "ebs_csi" {
  role       = aws_iam_role.ebs_csi.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
}

####################################################
# AWS Load Balancer Controller
####################################################
resource "aws_iam_role" "aws_load_balancer_controller" {
  name               = "${local.project_name}-aws-load-balancer-controller"
  assume_role_policy = data.aws_iam_policy_document.pod_identity_assume_role.json
}

resource "aws_iam_policy" "aws_load_balancer_controller" {
  name   = "${local.project_name}-aws-load-balancer-controller-policy"
  policy = file("${path.module}/manifests/aws-load-balancer-controller-policy.json")
}

resource "aws_iam_role_policy_attachment" "aws_load_balancer_controller" {
  policy_arn = aws_iam_policy.aws_load_balancer_controller.arn
  role       = aws_iam_role.aws_load_balancer_controller.name
}

resource "kubernetes_service_account_v1" "aws_load_balancer_controller" {
  metadata {
    name      = "aws-load-balancer-controller"
    namespace = "kube-system"
    labels = {
      "app.kubernetes.io/name"      = "aws-load-balancer-controller"
      "app.kubernetes.io/component" = "controller"
    }
  }

  depends_on = [aws_eks_cluster.this]
}

# AWS Load Balancer Controller Pod Identity Association
resource "aws_eks_pod_identity_association" "aws_load_balancer_controller" {
  cluster_name    = aws_eks_cluster.this.name
  namespace       = "kube-system"
  service_account = kubernetes_service_account_v1.aws_load_balancer_controller.metadata[0].name
  role_arn        = aws_iam_role.aws_load_balancer_controller.arn

  depends_on = [
    aws_eks_addon.pod_identity,
    kubernetes_service_account_v1.aws_load_balancer_controller,
    aws_iam_role.aws_load_balancer_controller
  ]
}

####################################################
# Mountpoint for Amazon S3 CSI 드라이버
####################################################
resource "aws_iam_role" "s3_csi" {
  name               = "${local.project_name}-s3-csi-role"
  assume_role_policy = data.aws_iam_policy_document.pod_identity_assume_role.json
}

resource "aws_iam_policy" "s3_csi" {
  name = "${local.project_name}-s3-csi-policy"
  policy = templatefile("${path.module}/manifests/s3-csi-policy.json", {
    s3_bucket_arn = aws_s3_bucket.app_data.arn
  })

  depends_on = [aws_s3_bucket.app_data]
}

resource "aws_iam_role_policy_attachment" "s3_csi" {
  policy_arn = aws_iam_policy.s3_csi.arn
  role       = aws_iam_role.s3_csi.name
}

# ####################################################
# # AWS Network Flow Monitor
# ####################################################
# resource "aws_iam_role" "network_flow" {
#     name = "${local.project_name}-network-flow-role"
#     assume_role_policy = data.aws_iam_policy_document.pod_identity_assume_role.json
# }

# resource "aws_iam_role_policy_attachment" "network_flow" {
#     role       = aws_iam_role.network_flow.name
#     policy_arn = "arn:aws:iam::aws:policy/CloudWatchNetworkFlowMonitorAgentPublishPolicy"
# }

# ####################################################
# # AWS Private CA Connector for Kubernetes
# ####################################################
# resource "aws_iam_role" "private_ca" {
#     name = "${local.project_name}-private-ca-role"
#     assume_role_policy = data.aws_iam_policy_document.pod_identity_assume_role.json
# }

# resource "aws_iam_role_policy_attachment" "private_ca" {
#     role       = aws_iam_role.private_ca.name
#     policy_arn = "arn:aws:iam::aws:policy/AWSPrivateCAConnectorForKubernetesPolicy"
# }

# IRSA for AWS Load Balancer Controller
resource "aws_iam_policy" "aws_load_balancer_controller" {
  name   = "${var.project_name}-aws-load-balancer-controller-policy"
  policy = file("${path.module}/../../manifests/aws-load-balancer-controller-policy.json")
}

resource "aws_iam_role" "aws_load_balancer_controller" {
  name = "${var.project_name}-aws-load-balancer-controller"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = var.oidc_provider_arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "${local.oidc_issuer_path}:aud" = "sts.amazonaws.com"
            "${local.oidc_issuer_path}:sub" = "system:serviceaccount:kube-system:aws-load-balancer-controller"
          }
        }
      }
    ]
  })
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
    annotations = {
      "eks.amazonaws.com/role-arn" = aws_iam_role.aws_load_balancer_controller.arn
    }
  }
}

resource "helm_release" "aws_load_balancer_controller" {
  name       = "aws-load-balancer-controller"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  namespace  = "kube-system"

  values = [
    yamlencode({
      region      = var.region
      vpcId       = var.vpc_id
      clusterName = var.cluster_name
      serviceAccount = {
        create = false
        name   = kubernetes_service_account_v1.aws_load_balancer_controller.metadata[0].name
      }
    })
  ]

  depends_on = [
    aws_iam_policy.aws_load_balancer_controller,
    aws_iam_role.aws_load_balancer_controller,
    aws_iam_role_policy_attachment.aws_load_balancer_controller,
    kubernetes_service_account_v1.aws_load_balancer_controller
  ]
}

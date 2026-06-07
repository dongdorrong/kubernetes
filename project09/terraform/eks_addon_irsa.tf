# ACK/ACM IRSA를 위한 OIDC/provider + 정책 문서
locals {
  mgmt_namespace = "${local.environment}-n-mgmt"
}

data "aws_iam_policy_document" "ack_acm_controller_policy" {
  statement {
    sid    = "AckAcmControllerPermissions"
    effect = "Allow"

    actions = [
      "route53:*",
      "elasticloadbalancing:*",
      "apigatewayv2:*",
      "apigatewaymanagementapi:*",
      "apigateway:*",
      "acm:*",
      "acm-pca:*"
    ]

    resources = ["*"]
  }
}

data "tls_certificate" "this" {
  url = aws_eks_cluster.this.identity[0].oidc[0].issuer
}

resource "aws_iam_openid_connect_provider" "this" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.this.certificates[0].sha1_fingerprint]
  # OIDC provider URL은 issuer URL(https 포함)을 그대로 사용해야 함
  url = aws_eks_cluster.this.identity[0].oidc[0].issuer

  tags = {
    Name = "${local.cluster_name}-oidc"
  }
}

data "aws_iam_policy_document" "fargate_pod_execution" {
  statement {
    sid    = "FargatePodExecution"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["eks-fargate-pods.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

data "aws_iam_policy_document" "ack_acm_irsa_assume_role" {
  statement {
    effect = "Allow"

    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.this.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "${replace(aws_eks_cluster.this.identity[0].oidc[0].issuer, "https://", "")}:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringLike"
      variable = "${replace(aws_eks_cluster.this.identity[0].oidc[0].issuer, "https://", "")}:sub"
      values = [
        "system:serviceaccount:${local.mgmt_namespace}:ack-acm-controller",
        "system:serviceaccount:${local.mgmt_namespace}:acm-cert-importer",
        "system:serviceaccount:${local.mgmt_namespace}:acm-secret-sync",
        "system:serviceaccount:${local.mgmt_namespace}:acm-aws-sync",
      ]
    }
  }
}

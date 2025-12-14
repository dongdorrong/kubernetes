############################################
# HardenEKS GitHub Actions integration
############################################

resource "aws_iam_openid_connect_provider" "hardeneks_github" {
  count = local.hardeneks_enabled ? 1 : 0

  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = ["1b511abead59c6ce207077c0bf0e0043b1382612"]
}

data "aws_iam_policy_document" "hardeneks_assume_role" {
  count = local.hardeneks_enabled ? 1 : 0

  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.hardeneks_github[count.index].arn]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values   = var.hardeneks_github_subjects
    }
  }
}

resource "aws_iam_role" "hardeneks" {
  count = local.hardeneks_enabled ? 1 : 0

  name               = "${var.project_name}-hardeneks-role"
  assume_role_policy = data.aws_iam_policy_document.hardeneks_assume_role[count.index].json
}

resource "aws_iam_policy" "hardeneks" {
  count = local.hardeneks_enabled ? 1 : 0

  name = "${var.project_name}-hardeneks-policy"
  policy = templatefile("${path.module}/../../manifests/hardeneks-policy.json", {
    CLUSTER_ARN = var.cluster_arn
  })
}

resource "aws_iam_role_policy_attachment" "hardeneks" {
  count = local.hardeneks_enabled ? 1 : 0

  role       = aws_iam_role.hardeneks[count.index].name
  policy_arn = aws_iam_policy.hardeneks[count.index].arn
}

resource "aws_eks_access_entry" "hardeneks" {
  count = local.hardeneks_enabled ? 1 : 0

  cluster_name  = var.cluster_name
  principal_arn = aws_iam_role.hardeneks[count.index].arn
  user_name     = "hardeneks-runner"
  type          = "STANDARD"
  kubernetes_groups = [
    "hardeneks:runner"
  ]

  depends_on = [aws_iam_role_policy_attachment.hardeneks]
}

resource "aws_eks_access_policy_association" "hardeneks" {
  count = local.hardeneks_enabled ? 1 : 0

  cluster_name  = var.cluster_name
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSViewPolicy"
  principal_arn = aws_iam_role.hardeneks[count.index].arn

  access_scope {
    type = "cluster"
  }

  depends_on = [aws_eks_access_entry.hardeneks]
}

resource "kubernetes_cluster_role_v1" "hardeneks_runner" {
  count = local.hardeneks_enabled ? 1 : 0

  metadata {
    name = "hardeneks-runner"
  }

  rule {
    api_groups = [""]
    resources  = ["namespaces", "resourcequotas", "persistentvolumes", "pods", "services", "nodes"]
    verbs      = ["list"]
  }

  rule {
    api_groups = [""]
    resources  = ["secrets"]
    verbs      = ["get", "list"]
  }

  rule {
    api_groups = ["rbac.authorization.k8s.io"]
    resources  = ["clusterroles", "clusterrolebindings", "roles", "rolebindings"]
    verbs      = ["list"]
  }

  rule {
    api_groups = ["networking.k8s.io"]
    resources  = ["networkpolicies"]
    verbs      = ["list"]
  }

  rule {
    api_groups = ["storage.k8s.io"]
    resources  = ["storageclasses"]
    verbs      = ["list"]
  }

  rule {
    api_groups = ["apps"]
    resources  = ["deployments", "daemonsets", "statefulsets"]
    verbs      = ["list", "get"]
  }

  rule {
    api_groups = ["autoscaling"]
    resources  = ["horizontalpodautoscalers"]
    verbs      = ["list"]
  }

  depends_on = [aws_eks_access_policy_association.hardeneks]
}

resource "kubernetes_cluster_role_binding_v1" "hardeneks_runner" {
  count = local.hardeneks_enabled ? 1 : 0

  metadata {
    name = "hardeneks-runner-binding"
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = kubernetes_cluster_role_v1.hardeneks_runner[count.index].metadata[0].name
  }

  subject {
    kind      = "Group"
    name      = "hardeneks:runner"
    api_group = "rbac.authorization.k8s.io"
  }

  depends_on = [aws_eks_access_policy_association.hardeneks]
}

############################################################
# GitHub의 OIDC 공급자
############################################################
resource "aws_iam_openid_connect_provider" "github" {
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = [ "sts.amazonaws.com" ]
  thumbprint_list = [ "1b511abead59c6ce207077c0bf0e0043b1382612" ]
}

############################################################
# AWS IAM
############################################################
data "aws_iam_policy_document" "hardeneks_assume_role" {
    statement {
        actions = [ "sts:AssumeRoleWithWebIdentity" ]
        effect  = "Allow"
        principals {
            type        = "Federated"
            identifiers = [ aws_iam_openid_connect_provider.github.arn ]
        }

        condition {
            test     = "StringEquals"
            variable = "token.actions.githubusercontent.com:aud"
            values   = [ "sts.amazonaws.com" ]
        }

        # GitHub repo/브랜치 스코프 제한 (필요에 맞게 조정)
        condition {
            test     = "StringLike"
            variable = "token.actions.githubusercontent.com:sub"
            values   = [ "repo:dongdorrong/hardeneks-test:ref:refs/heads/*" ]
        }
    }
}

resource "aws_iam_role" "hardeneks" {
    name               = "${local.project_name}-hardeneks-role"
    assume_role_policy = data.aws_iam_policy_document.hardeneks_assume_role.json
}

resource "aws_iam_policy" "hardeneks" {
    name   = "${local.project_name}-hardeneks-policy"
    policy = templatefile("${path.module}/manifests/hardeneks-policy.json", {
      CLUSTER_ARN = aws_eks_cluster.this.arn
    })
}

resource "aws_iam_role_policy_attachment" "hardeneks" {
    role       = aws_iam_role.hardeneks.name
    policy_arn = aws_iam_policy.hardeneks.arn
}

############################################################
# EKS Access Entry
############################################################
resource "aws_eks_access_entry" "hardeneks" {
    cluster_name  = aws_eks_cluster.this.name
    principal_arn = aws_iam_role.hardeneks.arn

    user_name         = "hardeneks-runner"
    kubernetes_groups = ["hardeneks:runner"]
    type              = "STANDARD"

    depends_on = [ aws_eks_cluster.this ]
}


resource "aws_eks_access_policy_association" "hardeneks" {
    cluster_name  = aws_eks_cluster.this.name
    policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSViewPolicy"
    principal_arn = aws_iam_role.hardeneks.arn

    access_scope {
        type = "cluster"
    }

    depends_on = [ aws_eks_access_entry.hardeneks ]
}

############################################################
# K8s RBAC
############################################################
resource "kubernetes_cluster_role" "hardeneks_runner" {
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

    depends_on = [ aws_eks_access_policy_association.hardeneks ]
}

resource "kubernetes_cluster_role_binding" "hardeneks_runner" {
    metadata {
        name = "hardeneks-runner-binding"
    }
    role_ref {
        api_group = "rbac.authorization.k8s.io"
        kind      = "ClusterRole"
        name      = kubernetes_cluster_role.hardeneks_runner.metadata[0].name
    }
    subject {
        kind      = "Group"
        name      = "hardeneks:runner" # Access Entry에서 매핑한 그룹명과 동일
        api_group = "rbac.authorization.k8s.io"
    }

    depends_on = [ aws_eks_access_policy_association.hardeneks ]
}

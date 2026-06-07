# EKS RBAC API access entries (관리자 역할 매핑)
resource "aws_eks_access_entry" "eks_admin" {
  cluster_name  = local.cluster_name
  principal_arn = data.aws_iam_role.eks_admin.arn
  type          = "STANDARD"
  user_name     = "eks-admin"

  depends_on = [aws_eks_cluster.this]
}

resource "aws_eks_access_entry" "terraform_admin" {
  cluster_name  = local.cluster_name
  principal_arn = data.aws_iam_role.terraform_admin.arn
  type          = "STANDARD"
  user_name     = "terraform-admin"

  depends_on = [aws_eks_cluster.this]
}

resource "aws_eks_access_policy_association" "eks_admin" {
  cluster_name  = local.cluster_name
  principal_arn = data.aws_iam_role.eks_admin.arn
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"

  access_scope {
    type = "cluster"
  }

  depends_on = [aws_eks_access_entry.eks_admin]
}

resource "aws_eks_access_policy_association" "terraform_admin" {
  cluster_name  = local.cluster_name
  principal_arn = data.aws_iam_role.terraform_admin.arn
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"

  access_scope {
    type = "cluster"
  }

  depends_on = [aws_eks_access_entry.terraform_admin]
}

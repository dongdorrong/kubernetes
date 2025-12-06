# Terraform 관리자 역할에 대한 EKS Access Entry 설정
resource "aws_eks_access_entry" "terraform_admin" {
    cluster_name      = aws_eks_cluster.this.name
    principal_arn     = data.aws_iam_role.terraform_admin.arn

    type              = "STANDARD"
    user_name         = "terraform-admin"
}

resource "aws_eks_access_policy_association" "terraform_admin" {
    cluster_name  = aws_eks_cluster.this.name
    principal_arn = aws_eks_access_entry.terraform_admin.principal_arn

    policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"

    access_scope {
        type = "cluster"
    }
}

# EKS 관리자 역할에 대한 EKS Access Entry 설정
resource "aws_eks_access_entry" "eks_admin" {
    cluster_name      = aws_eks_cluster.this.name
    principal_arn     = data.aws_iam_role.eks_admin.arn

    type              = "STANDARD"
    user_name         = "eks-admin"
}

resource "aws_eks_access_policy_association" "eks_admin" {
    cluster_name  = aws_eks_cluster.this.name
    principal_arn = aws_eks_access_entry.eks_admin.principal_arn

    policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"

    access_scope {
        type = "cluster"
    }
}
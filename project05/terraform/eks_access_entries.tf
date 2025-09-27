# # EKS Access Entry - Terraform 관리자 역할
# # eks_cluster.this.access_config.bootstrap_cluster_creator_admin_permissions 옵션에 의해서 자동 추가
# resource "aws_eks_access_entry" "terraform_admin" {
#     cluster_name  = aws_eks_cluster.this.name
#     principal_arn = data.aws_iam_role.terraform_admin.arn
# }

# resource "aws_eks_access_policy_association" "terraform_admin_cluster_admin" {
#     cluster_name  = aws_eks_cluster.this.name
#     principal_arn = data.aws_iam_role.terraform_admin.arn
#     policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"

#     access_scope {
#         type = "cluster"
#     }

#     depends_on = [aws_eks_access_entry.terraform_admin]
# }

# EKS Access Entry - EKS 관리자 역할
resource "aws_eks_access_entry" "eks_admin" {
    cluster_name  = aws_eks_cluster.this.name
    principal_arn = data.aws_iam_role.eks_admin.arn
}

resource "aws_eks_access_policy_association" "eks_admin_cluster_admin" {
    cluster_name  = aws_eks_cluster.this.name
    principal_arn = data.aws_iam_role.eks_admin.arn
    policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"

    access_scope {
        type = "cluster"
    }

    depends_on = [aws_eks_access_entry.eks_admin]
}

# EKS Access Entry - 기본 노드 그룹 역할
resource "aws_eks_access_entry" "default_node_group" {
    cluster_name  = aws_eks_cluster.this.name
    principal_arn = aws_iam_role.default_node_group.arn
    type          = "EC2_LINUX"
}

resource "aws_eks_access_policy_association" "default_node_group" {
    cluster_name  = aws_eks_cluster.this.name
    principal_arn = aws_iam_role.default_node_group.arn
    policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSNodeAccessPolicy"

    access_scope {
        type = "cluster"
    }

    depends_on = [aws_eks_access_entry.default_node_group]
}

# EKS Access Entry - Karpenter 노드 역할
resource "aws_eks_access_entry" "karpenter_node" {
    cluster_name  = aws_eks_cluster.this.name
    principal_arn = aws_iam_role.karpenter_node.arn
    type          = "EC2_LINUX"
}

resource "aws_eks_access_policy_association" "karpenter_node" {
    cluster_name  = aws_eks_cluster.this.name
    principal_arn = aws_iam_role.karpenter_node.arn
    policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSNodeAccessPolicy"

    access_scope {
        type = "cluster"
    }

    depends_on = [aws_eks_access_entry.karpenter_node]
}

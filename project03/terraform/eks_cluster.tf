# # EKS 클러스터 생성
# resource "aws_eks_cluster" "this" {
#     name     = local.cluster_name
#     role_arn = aws_iam_role.cluster.arn
#     version  = "1.32"

#     vpc_config {
#         subnet_ids              = local.subnet_ids
#         endpoint_private_access = true
#         endpoint_public_access  = true
#         security_group_ids      = [ aws_security_group.additional.id ]
#     }

#     depends_on = [
#         aws_iam_role_policy_attachment.cluster_AmazonEKSClusterPolicy,
#         aws_iam_role_policy_attachment.cluster_AmazonEKSServicePolicy
#     ]
# }

# 추가 보안 그룹 (사용자 정의 규칙용)
resource "aws_security_group" "additional" {
    name        = "eksstudy-additional-sg"
    description = "Additional security group for EKS cluster"
    vpc_id      = aws_vpc.main.id

    # 노드 그룹과의 통신 규칙 (Karpenter가 생성할 노드들을 위한 규칙)
    ingress {
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = [local.vpc_cidr]
    }

    egress {
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }

    tags = merge(
        local.common_tags,
        {
            Name = "${local.project_name}-additional-sg"
        }
    )
}

# aws-auth ConfigMap 생성
resource "kubernetes_config_map" "aws_auth" {
    metadata {
        name      = "aws-auth"
        namespace = "kube-system"
    }

    data = {
        mapRoles = yamlencode([
            # EKS 관리자 역할
            {
                rolearn  = aws_iam_role.eks_admin.arn
                username = "admin"
                groups   = ["system:masters"]
            }
        ])
    }

    depends_on = [aws_eks_cluster.this]
}

# # EKS 기본 노드 그룹
# resource "aws_eks_node_group" "default" {
#     cluster_name    = aws_eks_cluster.this.name
#     node_group_name = "default"
#     node_role_arn   = aws_iam_role.node.arn
#     subnet_ids      = local.subnet_ids

#     instance_types = ["t3.medium"]
#     ami_type       = "AL2023_x86_64_STANDARD"
#     capacity_type  = "SPOT"

#     scaling_config {
#         desired_size = 1
#         min_size     = 1
#         max_size     = 1
#     }

#     update_config {
#         max_unavailable = 1
#     }

#     depends_on = [
#         aws_iam_role_policy_attachment.node_policy,
#         aws_iam_role_policy_attachment.cni_policy,
#         aws_iam_role_policy_attachment.registry_policy,
#         kubernetes_config_map.aws_auth
#     ]

#     tags = merge(
#         local.common_tags,
#         {
#             Name = "${local.project_name}-default-node"
#         }
#     )
# }
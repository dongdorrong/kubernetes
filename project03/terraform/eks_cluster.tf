resource "aws_eks_cluster" "this" {
    name = var.project_name

    access_config {
        authentication_mode = "CONFIG_MAP"
        bootstrap_cluster_creator_admin_permissions = true
    }

    role_arn = aws_iam_role.cluster.arn
    version  = "1.32"

    vpc_config {
        subnet_ids              = concat(aws_subnet.public[*].id, aws_subnet.private[*].id)
        security_group_ids      = [aws_security_group.additional.id]

        # API 서버 엔드포인트 접근 제어
        endpoint_private_access = true                    # VPC 내부에서 접근 가능
        endpoint_public_access  = true                    # 퍼블릭 접근 허용
        public_access_cidrs     = ["175.198.62.193/32"]   # 관리자 IP만 허용
    }

    depends_on = [
        aws_iam_role.cluster,
        aws_iam_role_policy_attachment.cluster_AmazonEKSClusterPolicy,
        aws_security_group.additional,
    ]
}

resource "aws_iam_role" "cluster" {
    name               = "eksstudy-cluster-role"
    assume_role_policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
            {
                Action = "sts:AssumeRole"
                Effect = "Allow"
                Principal = {
                    Service = "eks.amazonaws.com"
                }
            },
        ]
    })
}

resource "aws_iam_role_policy_attachment" "cluster_AmazonEKSClusterPolicy" {
    policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
    role       = aws_iam_role.cluster.name
}

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
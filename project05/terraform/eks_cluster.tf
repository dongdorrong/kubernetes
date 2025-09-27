# EKS 클러스터 생성
resource "aws_eks_cluster" "this" {
    name     = local.cluster_name
    role_arn = aws_iam_role.cluster.arn
    version  = "1.33"

    vpc_config {
        subnet_ids              = local.subnet_ids
        endpoint_private_access = true
        endpoint_public_access  = true
        security_group_ids      = [ aws_security_group.cluster_additional.id ]
    }

    access_config {
        authentication_mode = "API"
        bootstrap_cluster_creator_admin_permissions = true
    }

    depends_on = [
        aws_iam_role_policy_attachment.cluster_AmazonEKSClusterPolicy,
        aws_iam_role_policy_attachment.cluster_AmazonEKSServicePolicy
    ]
}

# 추가 보안 그룹 (사용자 정의 규칙용)
resource "aws_security_group" "cluster_additional" {
    vpc_id      = aws_vpc.main.id

    # 노드 그룹과의 통신 규칙 (Karpenter가 생성할 노드들을 위한 규칙)
    ingress {
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = [ local.vpc_cidr ]
    }

    egress {
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = [ "0.0.0.0/0" ]
    }

    tags = merge({
        Name = "${local.project_name}-cluster-additional-sg"
    })
}

# EKS 기본 노드 그룹
resource "aws_eks_node_group" "default" {
    # tags로 이름 지정 불가
    node_group_name = "${local.project_name}"

    cluster_name    = aws_eks_cluster.this.name
    node_role_arn   = aws_iam_role.default_node_group.arn
    subnet_ids      = local.subnet_ids

    instance_types = [ "t3.medium" ]
    ami_type       = "BOTTLEROCKET_x86_64"
    capacity_type  = "SPOT"

    scaling_config {
        desired_size = 2
        min_size     = 2
        max_size     = 2
    }

    update_config {
        max_unavailable = 2
    }

    launch_template {
        # id      = aws_launch_template.default.id
        name    = aws_launch_template.default.name
        version = aws_launch_template.default.default_version
    }

    depends_on = [
        aws_launch_template.default,
        aws_iam_role_policy_attachment.default_node_nodePolicy,
        aws_iam_role_policy_attachment.default_node_cniPolicy,
        aws_iam_role_policy_attachment.default_node_registryPolicy
    ]
}

# EKS 기본 노드 그룹의 Launch Template
resource "aws_launch_template" "default" {
    # tags로 이름 지정 불가
    name = "${local.project_name}"

    # 기본 네트워크 설정
    vpc_security_group_ids = [ aws_security_group.worker_default.id ]

    # 태그 설정
    tag_specifications {
        resource_type = "instance"
        tags = merge(
            local.node_tags
        )
    }
}

# 기본 노드 보안 그룹
resource "aws_security_group" "worker_default" {
    vpc_id      = aws_vpc.main.id

    # 노드 간 통신 허용
    ingress {
        description = "Allow nodes to communicate with each other"
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        self        = true
    }

    # 클러스터 컨트롤 플레인에서의 통신 허용
    ingress {
        description     = "Allow cluster control plane to communicate with nodes"
        from_port       = 0
        to_port         = 0
        protocol        = "-1"
        security_groups = [aws_eks_cluster.this.vpc_config[0].cluster_security_group_id]
    }

    # 아웃바운드 트래픽 허용
    egress {
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }

    tags = merge({
        Name = "${local.project_name}-worker-node-sg"
        "karpenter.sh/discovery" = local.cluster_name
    })
}

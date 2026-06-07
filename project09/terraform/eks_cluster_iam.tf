# EKS Cluster/Pod 실행 역할(IAM)
resource "aws_iam_role" "cluster" {
  name = "${local.cluster_name}-cluster-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = "sts:AssumeRole"
        Principal = {
          Service = "eks.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Project = local.cluster_name
  }
}

resource "aws_iam_role_policy_attachment" "cluster_AmazonEKSClusterPolicy" {
  role       = aws_iam_role.cluster.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

resource "aws_iam_role_policy_attachment" "cluster_AmazonEKSServicePolicy" {
  role       = aws_iam_role.cluster.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSServicePolicy"
}

resource "aws_security_group" "cluster_additional" {
  name        = "${local.cluster_name}-cluster-additional-sg"
  description = "Managed by Terraform"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    cidr_blocks = [
      local.vpc_cidr
    ]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${local.cluster_name}-cluster-additional-sg"
  }
}

resource "aws_iam_role" "fargate_pod_execution" {
  name = "${local.cluster_name}-fargate-pod-execution"

  assume_role_policy = data.aws_iam_policy_document.fargate_pod_execution.json

  tags = {
    Project = local.cluster_name
  }
}

resource "aws_iam_role_policy_attachment" "fargate_pod_execution" {
  role       = aws_iam_role.fargate_pod_execution.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSFargatePodExecutionRolePolicy"
}

# ACK/ACM import 연동용 IRSA 역할
resource "aws_iam_role" "ack_acm_irsa" {
  name = "${local.cluster_name}-ack-acm-irsa"

  assume_role_policy = data.aws_iam_policy_document.ack_acm_irsa_assume_role.json

  tags = {
    Project = local.cluster_name
  }
}

resource "aws_iam_policy" "ack_acm_controller" {
  name = "AckAcmControllerPolicy"

  policy = data.aws_iam_policy_document.ack_acm_controller_policy.json
}

resource "aws_iam_role_policy_attachment" "ack_acm_controller" {
  role       = aws_iam_role.ack_acm_irsa.name
  policy_arn = aws_iam_policy.ack_acm_controller.arn
}

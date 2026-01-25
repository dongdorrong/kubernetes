# Core network policies required for EKS control plane and worker nodes.
resource "aws_security_group" "cluster_additional" {
  name        = "${local.project_name}-cluster-additional"
  description = "Additional EKS cluster security group"
  vpc_id      = aws_vpc.main.id

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

  tags = {
    Name = "${local.project_name}-cluster-additional-sg"
  }
}

resource "aws_security_group" "worker_default" {
  name        = "${local.project_name}-worker"
  description = "EKS worker node security group"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "Node to node"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    self        = true
  }

  ingress {
    description     = "Control plane to node"
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    security_groups = [aws_eks_cluster.this.vpc_config[0].cluster_security_group_id]
  }

  ingress {
    description = "NodePort from VPC for LB"
    from_port   = 30000
    to_port     = 32767
    protocol    = "tcp"
    cidr_blocks = [local.vpc_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${local.project_name}-worker-sg"
  }

  depends_on = [aws_eks_cluster.this]
}

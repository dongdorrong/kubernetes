# Network policies for Teleport integrations (DB access, EC2 node access).
resource "aws_security_group" "rds" {
  name        = "${local.project_name}-rds"
  description = "RDS security group"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port       = local.rds_port
    to_port         = local.rds_port
    protocol        = "tcp"
    security_groups = [aws_security_group.worker_default.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${local.project_name}-rds-sg"
  }
}

resource "aws_security_group" "ec2_node" {
  count = local.ec2_enabled ? 1 : 0

  name        = "${local.project_name}-ec2-node"
  description = "Teleport node EC2 security group"
  vpc_id      = aws_vpc.main.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${local.project_name}-ec2-node-sg"
  }
}

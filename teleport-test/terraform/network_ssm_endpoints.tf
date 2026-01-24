# VPC interface endpoints for private SSM access.
resource "aws_security_group" "ssm_endpoints" {
  count = var.ssm_endpoints_enabled ? 1 : 0

  name        = "${local.project_name}-ssm-endpoints"
  description = "SSM VPC endpoint security group"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 443
    to_port     = 443
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
    Name = "${local.project_name}-ssm-endpoints-sg"
  }
}

resource "aws_vpc_endpoint" "ssm" {
  for_each = local.ssm_endpoint_services

  vpc_id              = aws_vpc.main.id
  service_name        = each.value
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true
  subnet_ids          = local.private_subnet_ids
  security_group_ids  = [aws_security_group.ssm_endpoints[0].id]

  tags = {
    Name = "${local.project_name}-${each.key}-endpoint"
  }
}

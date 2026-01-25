# Private bastion host accessed via SSM for administration tasks.
resource "aws_iam_role" "bastion_ssm" {
  count = local.bastion_enabled ? 1 : 0

  name = "${local.project_name}-bastion-ssm-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = "sts:AssumeRole"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "bastion_ssm" {
  count = local.bastion_enabled ? 1 : 0

  role       = aws_iam_role.bastion_ssm[0].name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy" "bastion_eks_describe" {
  count = local.bastion_enabled ? 1 : 0

  name = "${local.project_name}-bastion-eks-describe"
  role = aws_iam_role.bastion_ssm[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["eks:DescribeCluster"]
        Resource = aws_eks_cluster.this.arn
      }
    ]
  })
}

resource "aws_iam_instance_profile" "bastion_ssm" {
  count = local.bastion_enabled ? 1 : 0

  name = "${local.project_name}-bastion-ssm"
  role = aws_iam_role.bastion_ssm[0].name
}

resource "aws_security_group" "bastion" {
  count = local.bastion_enabled ? 1 : 0

  name        = "${local.project_name}-bastion"
  description = "Private bastion security group"
  vpc_id      = aws_vpc.main.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${local.project_name}-bastion-sg"
  }
}

resource "aws_launch_template" "bastion" {
  count = local.bastion_enabled ? 1 : 0

  name_prefix            = "${local.project_name}-bastion-"
  image_id               = data.aws_ami.al2023.id
  instance_type          = local.bastion_instance_type
  key_name               = local.bastion_key_name
  user_data              = base64encode(local.ssm_user_data)
  update_default_version = true

  iam_instance_profile {
    name = aws_iam_instance_profile.bastion_ssm[0].name
  }

  network_interfaces {
    associate_public_ip_address = false
    security_groups             = [aws_security_group.bastion[0].id]
    subnet_id                   = local.private_subnet_ids[0]
  }

  instance_market_options {
    market_type = "spot"
  }
}

resource "aws_instance" "bastion" {
  count = local.bastion_enabled ? 1 : 0

  launch_template {
    id      = aws_launch_template.bastion[0].id
    version = aws_launch_template.bastion[0].latest_version
  }

  tags = {
    Name = "${local.project_name}-bastion"
  }

  depends_on = [aws_eks_cluster.this]
}

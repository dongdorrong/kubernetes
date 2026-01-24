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

resource "aws_instance" "bastion" {
  count = local.bastion_enabled ? 1 : 0

  ami                    = data.aws_ami.al2023.id
  instance_type          = local.bastion_instance_type
  subnet_id              = local.private_subnet_ids[0]
  vpc_security_group_ids = [aws_security_group.bastion[0].id]
  iam_instance_profile   = aws_iam_instance_profile.bastion_ssm[0].name
  key_name               = local.bastion_key_name

  associate_public_ip_address = false

  tags = {
    Name = "${local.project_name}-bastion"
  }
}

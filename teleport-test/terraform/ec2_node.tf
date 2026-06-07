data "aws_ami" "al2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }
}

resource "aws_iam_role" "ec2_ssm" {
  count = local.ec2_enabled ? 1 : 0

  name = "${local.project_name}-ec2-ssm-role"

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

resource "aws_iam_role_policy_attachment" "ec2_ssm" {
  count = local.ec2_enabled ? 1 : 0

  role       = aws_iam_role.ec2_ssm[0].name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "ec2_ssm" {
  count = local.ec2_enabled ? 1 : 0

  name = "${local.project_name}-ec2-ssm"
  role = aws_iam_role.ec2_ssm[0].name
}

resource "aws_instance" "teleport_node" {
  count = local.ec2_enabled ? 1 : 0

  ami                         = data.aws_ami.al2023.id
  instance_type               = local.ec2_instance_type
  subnet_id                   = local.private_subnet_ids[0]
  vpc_security_group_ids      = [aws_security_group.ec2_node[0].id]
  iam_instance_profile        = aws_iam_instance_profile.ec2_ssm[0].name
  key_name                    = local.ec2_key_name
  user_data                   = local.ssm_user_data
  user_data_replace_on_change = true

  instance_market_options {
    market_type = "spot"
  }

  tags = {
    Name = "${local.project_name}-teleport-node"
  }
}

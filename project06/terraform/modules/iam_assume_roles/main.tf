data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

data "aws_iam_role" "terraform" {
  name = var.terraform_role_name
}

data "aws_iam_role" "eks_admin" {
  name = var.eks_role_name
}

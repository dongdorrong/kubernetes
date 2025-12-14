output "account_id" {
  value       = data.aws_caller_identity.current.account_id
  description = "AWS account ID"
}

output "region" {
  value       = data.aws_region.current.name
  description = "AWS region name"
}

output "terraform_role_arn" {
  value       = data.aws_iam_role.terraform.arn
  description = "Terraform assume role ARN"
}

output "eks_role_arn" {
  value       = data.aws_iam_role.eks_admin.arn
  description = "EKS admin assume role ARN"
}

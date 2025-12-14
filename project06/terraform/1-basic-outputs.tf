output "vpc_id" {
  description = "ID of the provisioned VPC"
  value       = module.network.vpc_id
}

output "public_subnet_ids" {
  description = "Public subnets available for load balancers"
  value       = module.network.public_subnet_ids
}

output "private_subnet_ids" {
  description = "Private subnets for workload nodes"
  value       = module.network.private_subnet_ids
}

output "public_subnet_arns" {
  description = "ARNs for public subnets"
  value       = module.network.public_subnet_arns
}

output "private_subnet_arns" {
  description = "ARNs for private subnets"
  value       = module.network.private_subnet_arns
}

output "nat_gateway_id" {
  description = "NAT Gateway ID created for private egress"
  value       = module.network.nat_gateway_id
}

output "acm_certificate_arn" {
  description = "ARN of the ACM certificate reused by ingress components"
  value       = module.acm.arn
}

output "acm_certificate_domain" {
  description = "Primary domain covered by the ACM certificate"
  value       = module.acm.domain_name
}

output "terraform_assume_role_arn" {
  description = "Terraform assume-role ARN for authentication"
  value       = module.iam_assume_roles.terraform_role_arn
}

output "eks_assume_role_arn" {
  description = "EKS administrator assume-role ARN"
  value       = module.iam_assume_roles.eks_role_arn
}

output "account_id" {
  description = "AWS account ID for this environment"
  value       = module.iam_assume_roles.account_id
}

output "aws_region" {
  description = "Primary AWS region"
  value       = module.iam_assume_roles.region
}

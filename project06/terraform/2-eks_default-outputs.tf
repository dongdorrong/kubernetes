output "eks_cluster_name" {
  description = "Deployed EKS cluster name"
  value       = module.eks_default.cluster_name
}

output "eks_cluster_endpoint" {
  description = "API endpoint for the EKS cluster"
  value       = module.eks_default.cluster_endpoint
}

output "eks_cluster_security_group_id" {
  description = "Additional cluster security group ID"
  value       = module.eks_default.cluster_security_group_id
}

output "eks_oidc_provider_arn" {
  description = "OIDC provider ARN for IRSA"
  value       = module.eks_default.oidc_provider_arn
}
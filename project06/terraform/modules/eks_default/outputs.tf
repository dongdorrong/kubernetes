output "cluster_name" {
  value       = aws_eks_cluster.this.name
  description = "EKS cluster name"
}

output "cluster_arn" {
  value       = aws_eks_cluster.this.arn
  description = "ARN of the EKS cluster"
}

output "cluster_endpoint" {
  value       = aws_eks_cluster.this.endpoint
  description = "Endpoint for the EKS API server"
}

output "certificate_authority" {
  value       = aws_eks_cluster.this.certificate_authority[0].data
  description = "Cluster certificate authority data"
}

output "cluster_security_group_id" {
  value       = aws_security_group.cluster_additional.id
  description = "Additional security group ID attached to the cluster"
}

output "worker_security_group_id" {
  value       = aws_security_group.worker_default.id
  description = "Security group ID for worker nodes"
}

output "node_role_arn" {
  value       = aws_iam_role.default_node_group.arn
  description = "IAM role ARN for the default node group"
}

output "cluster_role_arn" {
  value       = aws_iam_role.cluster.arn
  description = "IAM role ARN assumed by the EKS control plane"
}

output "oidc_provider_arn" {
  value       = aws_iam_openid_connect_provider.this.arn
  description = "OIDC provider ARN for the cluster"
}

output "cluster_oidc_issuer" {
  value       = aws_eks_cluster.this.identity[0].oidc[0].issuer
  description = "OIDC issuer URL for the cluster"
}

output "cluster_role_name" {
  value       = aws_iam_role.cluster.name
  description = "IAM role name for the EKS control plane"
}

output "node_role_name" {
  value       = aws_iam_role.default_node_group.name
  description = "IAM role name for the default node group"
}

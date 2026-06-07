output "cluster_name" {
  value = aws_eks_cluster.this.name
}

output "cluster_endpoint" {
  value = aws_eks_cluster.this.endpoint
}

output "cluster_oidc_issuer" {
  value = aws_eks_cluster.this.identity[0].oidc[0].issuer
}

output "cluster_arn" {
  value = aws_eks_cluster.this.arn
}

output "fargate_profile_name" {
  value = aws_eks_fargate_profile.default.fargate_profile_name
}

output "fargate_node_namespace" {
  value = local.mgmt_namespace
}

output "ack_irsa_role_arn" {
  value = aws_iam_role.ack_acm_irsa.arn
}

output "ack_irsa_policy_arn" {
  value = aws_iam_policy.ack_acm_controller.arn
}

output "vpc_id" {
  value = aws_vpc.main.id
}

output "public_subnet_ids" {
  value = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  value = aws_subnet.private[*].id
}

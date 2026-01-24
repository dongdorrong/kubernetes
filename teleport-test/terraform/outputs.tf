output "cluster_name" {
  value = aws_eks_cluster.this.name
}

output "cluster_endpoint" {
  value = aws_eks_cluster.this.endpoint
}

output "oidc_provider_arn" {
  value = aws_iam_openid_connect_provider.this.arn
}

output "kubeconfig_command" {
  value = "aws eks update-kubeconfig --name ${aws_eks_cluster.this.name} --region ${local.region} --profile ${local.profile}"
}

output "rds_endpoint" {
  value = aws_db_instance.teleport.address
}

output "rds_port" {
  value = aws_db_instance.teleport.port
}

output "rds_db_name" {
  value = local.rds_db_name
}

output "rds_username" {
  value = local.rds_username
}

output "rds_password" {
  value     = random_password.rds_password.result
  sensitive = true
}

output "ec2_instance_id" {
  value = try(aws_instance.teleport_node[0].id, null)
}

output "ec2_private_ip" {
  value = try(aws_instance.teleport_node[0].private_ip, null)
}

output "ec2_ssm_start_session" {
  value = local.ec2_enabled ? "aws ssm start-session --target ${aws_instance.teleport_node[0].id} --region ${local.region} --profile ${local.profile}" : null
}

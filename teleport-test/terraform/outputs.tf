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

output "rds_master_password_secret_arn" {
  value     = aws_secretsmanager_secret.rds_master_password.arn
  sensitive = true
}

output "rds_iam_auth_enabled" {
  value = aws_db_instance.teleport.iam_database_authentication_enabled
}

output "access_test_role_arn" {
  value = local.access_test_role_arn != "" ? local.access_test_role_arn : null
}

output "access_test_teleport_user" {
  value = local.access_test_enabled ? local.access_test_teleport_user : null
}

output "access_test_db_user" {
  value = local.access_test_enabled ? local.access_test_db_user : null
}

output "teleport_agent_irsa_role_arn" {
  value = local.teleport_agent_rds_role_arn != "" ? local.teleport_agent_rds_role_arn : null
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

output "bastion_instance_id" {
  value = try(aws_instance.bastion[0].id, null)
}

output "bastion_private_ip" {
  value = try(aws_instance.bastion[0].private_ip, null)
}

output "bastion_ssm_start_session" {
  value = local.bastion_enabled ? "aws ssm start-session --target ${aws_instance.bastion[0].id} --region ${local.region} --profile ${local.profile}" : null
}

output "bastion_ssm_run_command_sequence" {
  value = local.bastion_enabled ? sort(keys(aws_ssm_document.teleport_run_command)) : []
}

output "bastion_ssm_run_commands" {
  value = local.bastion_enabled ? {
    for key in sort(keys(aws_ssm_document.teleport_run_command)) :
    key => "aws ssm send-command --document-name ${aws_ssm_document.teleport_run_command[key].name} --instance-ids ${aws_instance.bastion[0].id} --region ${local.region} --profile ${local.profile}"
  } : {}
}

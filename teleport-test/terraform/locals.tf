locals {
  project_name = var.project_name != "" ? var.project_name : "teleport-test"
  environment  = var.environment != "" ? var.environment : "dev"
  region       = var.region != "" ? var.region : "ap-northeast-2"
  profile      = var.profile != "" ? var.profile : "private"

  vpc_cidr             = var.vpc_cidr != "" ? var.vpc_cidr : "10.10.0.0/16"
  azs                  = length(var.azs) > 0 ? var.azs : ["ap-northeast-2a", "ap-northeast-2c"]
  public_subnet_cidrs  = length(var.public_subnet_cidrs) > 0 ? var.public_subnet_cidrs : ["10.10.1.0/24", "10.10.2.0/24"]
  private_subnet_cidrs = length(var.private_subnet_cidrs) > 0 ? var.private_subnet_cidrs : ["10.10.10.0/24", "10.10.20.0/24"]

  admin_cidrs = length(var.admin_cidrs) > 0 ? var.admin_cidrs : ["${trimspace(data.http.public_ip.response_body)}/32"]

  cluster_name = local.project_name

  subnet_ids         = concat(aws_subnet.public[*].id, aws_subnet.private[*].id)
  private_subnet_ids = aws_subnet.private[*].id
  public_subnet_ids  = aws_subnet.public[*].id

  eks_version         = var.eks_version != "" ? var.eks_version : "1.33"
  node_instance_types = length(var.node_instance_types) > 0 ? var.node_instance_types : ["t3.medium"]
  node_capacity_type  = var.node_capacity_type != "" ? var.node_capacity_type : "SPOT"
  node_ami_type       = var.node_ami_type != "" ? var.node_ami_type : "AL2023_x86_64_STANDARD"
  node_desired_size   = var.node_desired_size > 0 ? var.node_desired_size : 2
  node_min_size       = var.node_min_size > 0 ? var.node_min_size : 2
  node_max_size       = var.node_max_size > 0 ? var.node_max_size : 3

  rds_engine                = var.rds_engine != "" ? var.rds_engine : "postgres"
  rds_engine_version        = var.rds_engine_version != "" ? var.rds_engine_version : data.aws_rds_engine_version.postgres_default.version
  rds_instance_class        = var.rds_instance_class != "" ? var.rds_instance_class : "db.t3.small"
  rds_allocated_storage     = var.rds_allocated_storage > 0 ? var.rds_allocated_storage : 20
  rds_db_name               = var.rds_db_name != "" ? var.rds_db_name : "teleport"
  rds_username              = var.rds_username != "" ? var.rds_username : "teleportadmin"
  rds_port                  = var.rds_port > 0 ? var.rds_port : 5432
  rds_multi_az              = var.rds_multi_az
  rds_backup_retention_days = var.rds_backup_retention_days > 0 ? var.rds_backup_retention_days : 7

  access_test_enabled            = var.access_test_enabled
  access_test_teleport_user      = var.access_test_teleport_user != "" ? var.access_test_teleport_user : "teleport-test-user"
  access_test_db_user            = var.access_test_db_user != "" ? var.access_test_db_user : "teleport_ro"
  access_test_kubernetes_group   = "teleport-k8s-viewer"
  teleport_agent_namespace       = "default"
  teleport_agent_service_account = "teleport-agent"
  teleport_agent_rds_role_arn    = try(aws_iam_role.teleport_agent_rds[0].arn, "")
  access_test_role_arn           = try(aws_iam_role.access_test[0].arn, "")
  rds_master_password_secret_arn = aws_secretsmanager_secret.rds_master_password.arn

  caller_arn              = data.aws_caller_identity.current.arn
  caller_is_assumed_role  = can(regex("^arn:aws:sts::\\d+:assumed-role/.+/.+$", local.caller_arn))
  caller_account_id       = local.caller_is_assumed_role ? element(split(":", local.caller_arn), 4) : null
  caller_assumed_resource = local.caller_is_assumed_role ? element(split(":", local.caller_arn), 5) : null
  caller_role_name        = local.caller_is_assumed_role ? element(split("/", local.caller_assumed_resource), 1) : null
  default_admin_arn       = local.caller_is_assumed_role ? "arn:aws:iam::${local.caller_account_id}:role/${local.caller_role_name}" : local.caller_arn
  admin_principal_arns = length(var.admin_principal_arns) > 0 ? [
    for arn in var.admin_principal_arns : can(regex("^arn:aws:sts::\\d+:assumed-role/.+/.+$", arn)) ? "arn:aws:iam::${element(split(":", arn), 4)}:role/${element(split("/", element(split(":", arn), 5)), 1)}" : arn
  ] : [local.default_admin_arn]

  ssm_endpoint_services = var.ssm_endpoints_enabled ? {
    ssm         = "com.amazonaws.${local.region}.ssm"
    ssmmessages = "com.amazonaws.${local.region}.ssmmessages"
    ec2messages = "com.amazonaws.${local.region}.ec2messages"
  } : {}

  ssm_user_data = templatefile("${path.module}/manifest/ssm_user_data.sh.tftpl", {
    cluster_name                   = local.cluster_name
    region                         = local.region
    rds_endpoint                   = aws_db_instance.teleport.address
    rds_port                       = local.rds_port
    rds_db_name                    = local.rds_db_name
    rds_master_username            = local.rds_username
    rds_master_password_secret_arn = local.rds_master_password_secret_arn
    access_test_enabled            = local.access_test_enabled ? "true" : "false"
    access_test_role_arn           = local.access_test_role_arn
    access_test_teleport_user      = local.access_test_teleport_user
    access_test_db_user            = local.access_test_db_user
    access_test_kubernetes_group   = local.access_test_kubernetes_group
    teleport_agent_irsa_role_arn   = local.teleport_agent_rds_role_arn
    teleport_agent_service_account = local.teleport_agent_service_account
    teleport_agent_namespace       = local.teleport_agent_namespace
  })

  node_name_format = "${local.cluster_name}-node"
  node_tags = {
    Name = local.node_name_format
  }

  ec2_enabled       = var.ec2_enabled
  ec2_instance_type = var.ec2_instance_type != "" ? var.ec2_instance_type : "t3.micro"
  ec2_key_name      = var.ec2_key_name != "" ? var.ec2_key_name : null

  bastion_enabled       = var.bastion_enabled
  bastion_instance_type = var.bastion_instance_type != "" ? var.bastion_instance_type : "t3.micro"
  bastion_key_name      = var.bastion_key_name != "" ? var.bastion_key_name : null
}

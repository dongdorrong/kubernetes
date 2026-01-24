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

  eks_version         = var.eks_version != "" ? var.eks_version : "1.29"
  node_instance_types = length(var.node_instance_types) > 0 ? var.node_instance_types : ["t3.medium"]
  node_capacity_type  = var.node_capacity_type != "" ? var.node_capacity_type : "SPOT"
  node_desired_size   = var.node_desired_size > 0 ? var.node_desired_size : 2
  node_min_size       = var.node_min_size > 0 ? var.node_min_size : 2
  node_max_size       = var.node_max_size > 0 ? var.node_max_size : 3

  rds_engine                = var.rds_engine != "" ? var.rds_engine : "postgres"
  rds_engine_version        = var.rds_engine_version != "" ? var.rds_engine_version : "15.4"
  rds_instance_class        = var.rds_instance_class != "" ? var.rds_instance_class : "db.t3.small"
  rds_allocated_storage     = var.rds_allocated_storage > 0 ? var.rds_allocated_storage : 20
  rds_db_name               = var.rds_db_name != "" ? var.rds_db_name : "teleport"
  rds_username              = var.rds_username != "" ? var.rds_username : "teleportadmin"
  rds_port                  = var.rds_port > 0 ? var.rds_port : 5432
  rds_multi_az              = var.rds_multi_az
  rds_backup_retention_days = var.rds_backup_retention_days > 0 ? var.rds_backup_retention_days : 7

  admin_principal_arns = length(var.admin_principal_arns) > 0 ? var.admin_principal_arns : [data.aws_caller_identity.current.arn]

  node_name_format = "${local.cluster_name}-node"
  node_tags = {
    Name = local.node_name_format
  }

  ec2_enabled       = var.ec2_enabled
  ec2_instance_type = var.ec2_instance_type != "" ? var.ec2_instance_type : "t3.micro"
  ec2_key_name      = var.ec2_key_name != "" ? var.ec2_key_name : null
}

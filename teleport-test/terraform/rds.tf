resource "random_password" "rds_password" {
  length           = 20
  special          = true
  override_special = "_%@-"
}

resource "aws_db_subnet_group" "main" {
  name       = "${local.project_name}-db-subnet"
  subnet_ids = local.private_subnet_ids

  tags = {
    Name = "${local.project_name}-db-subnet"
  }
}

resource "aws_db_instance" "teleport" {
  identifier = "${local.project_name}-db"

  engine         = local.rds_engine
  engine_version = local.rds_engine_version
  instance_class = local.rds_instance_class

  allocated_storage          = local.rds_allocated_storage
  storage_type               = "gp3"
  db_name                    = local.rds_db_name
  username                   = local.rds_username
  password                   = random_password.rds_password.result
  port                       = local.rds_port
  multi_az                   = local.rds_multi_az
  backup_retention_period    = local.rds_backup_retention_days
  auto_minor_version_upgrade = true

  publicly_accessible    = false
  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.rds.id]

  skip_final_snapshot = true
  deletion_protection = false

  tags = {
    Name = "${local.project_name}-db"
  }
}

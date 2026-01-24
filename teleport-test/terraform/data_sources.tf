data "http" "public_ip" {
  url = "https://checkip.amazonaws.com"
}

data "aws_rds_engine_version" "postgres_default" {
  engine       = local.rds_engine
  default_only = true
}

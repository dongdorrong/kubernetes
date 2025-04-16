locals {
  # 프로젝트 관련 설정
  project_name = var.project_name
  environment = var.environment

  # 클러스터 관련 설정
  cluster_name    = "eks-${var.environment}-${var.project_name}"

  # VPC 관련 설정
  vpc_cidr            = var.vpc_cidr
  azs                 = var.azs

  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs

  # VPC 서브넷 ID 목록
  subnet_ids = concat(aws_subnet.public[*].id, aws_subnet.private[*].id)

  # 공통 태그
  common_tags = {
    Environment = var.environment
    Project     = var.project_name
    Terraform   = "true"
    Owner       = var.owner
    ManagedBy   = "terraform"
  }
} 
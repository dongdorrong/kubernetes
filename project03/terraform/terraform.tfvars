# 프로젝트 기본 설정
project_name = "eksstudy"
environment  = "dev"
owner        = "252462902626"
region       = "ap-northeast-2"

# VPC 설정
vpc_cidr = "10.0.0.0/16"
azs      = ["ap-northeast-2a", "ap-northeast-2c"]

# 서브넷 설정
public_subnet_cidrs  = ["10.0.1.0/24", "10.0.2.0/24"]
private_subnet_cidrs = ["10.0.10.0/24", "10.0.20.0/24"]

# 보안 설정
admin_cidrs = ["175.198.62.193/32"]  # EKS API 접근 허용 IP
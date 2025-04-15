terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  required_version = ">= 1.2.0"

  # 팀 협업을 위한 원격 상태 관리 설정 (현재는 로컬 상태 관리 사용)
  # backend "s3" {
  #   bucket         = "eksstudy-terraform-state"
  #   key            = "terraform.tfstate"
  #   region         = "ap-northeast-2"
  #   profile        = "private"
  #   encrypt        = true
  #   dynamodb_table = "eksstudy-terraform-lock"
  # }
}

# AWS Provider 설정
provider "aws" {
  region  = "ap-northeast-2"
  profile = "private"
  alias   = "private"  # private 프로필용 alias 설정

  # 프로필 사용 확인을 위한 기본 태그 설정
  default_tags {
    tags = {
      ManagedBy = "terraform-private-profile"
    }
  }
}

# 프로젝트 전반에 사용될 변수 정의
locals {
  project_name = "eksstudy"
  environment  = "dev"

  vpc_cidr = "10.0.0.0/16"
  azs      = ["ap-northeast-2a", "ap-northeast-2c"]

  public_subnet_cidrs  = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnet_cidrs = ["10.0.10.0/24", "10.0.20.0/24"]

  common_tags = {
    Project     = local.project_name
    Environment = local.environment
    Terraform   = "true"
  }
} 
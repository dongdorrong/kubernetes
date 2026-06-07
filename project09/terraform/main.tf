terraform {
  required_providers {
    aws = {
      source  = "registry.terraform.io/hashicorp/aws"
      version = "~> 5.0"
    }
    tls = {
      source  = "registry.terraform.io/hashicorp/tls"
      version = "~> 4.0"
    }
  }
  required_version = ">= 1.2.0"

  # 로컬 상태 파일 저장 경로 지정
  backend "local" {
    path = "./tfstate/terraform.tfstate"
  }
}

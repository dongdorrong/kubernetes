# 프로젝트 기본 설정
variable "project_name" {
  description = "프로젝트 이름"
  type        = string
  default     = ""
}

variable "environment" {
  description = "환경 (dev, staging, prod)"
  type        = string
  default     = ""
}

variable "owner" {
  description = "리소스 소유자"
  type        = string
  default     = ""
}

variable "region" {
  description = "AWS 리전"
  type        = string
  default     = ""
}

# VPC 관련 변수
variable "vpc_cidr" {
  description = "VPC CIDR 블록"
  type        = string
  default     = ""
}

variable "azs" {
  description = "사용할 가용영역 목록"
  type        = list(string)
  default     = [ "" ]
}

# 서브넷 설정
variable "public_subnet_cidrs" {
  description = "퍼블릭 서브넷 CIDR 블록 목록"
  type        = list(string)
  default     = [ "" ]
}

variable "private_subnet_cidrs" {
  description = "프라이빗 서브넷 CIDR 블록 목록"
  type        = list(string)
  default     = [ "" ]
}

variable "admin_cidrs" {
  description = "EKS API 서버 접근이 허용된 CIDR 블록 목록"
  type        = list(string)
  default     = [ "" ]
}
# 프로젝트 기본 설정
variable "project_name" {
  description = "프로젝트 이름"
  type        = string
}

variable "environment" {
  description = "환경 (dev, staging, prod)"
  type        = string
}

variable "owner" {
  description = "리소스 소유자"
  type        = string
}

variable "region" {
  description = "AWS 리전"
  type        = string
}

# VPC 관련 변수
variable "vpc_cidr" {
  description = "VPC CIDR 블록"
  type        = string
}

variable "azs" {
  description = "사용할 가용영역 목록"
  type        = list(string)
}

# 서브넷 설정
variable "public_subnet_cidrs" {
  description = "퍼블릭 서브넷 CIDR 블록 목록"
  type        = list(string)
}

variable "private_subnet_cidrs" {
  description = "프라이빗 서브넷 CIDR 블록 목록"
  type        = list(string)
}

variable "admin_cidrs" {
  description = "EKS API 서버 접근이 허용된 CIDR 블록 목록"
  type        = list(string)
}

# # EKS 관련 변수 (Karpenter 사용으로 인해 비활성화)
# variable "node_groups" {
#   description = "EKS 노드 그룹 설정"
#   type = map(object({
#     instance_types = list(string)
#     capacity_type  = string
#     disk_size      = number
#     scaling_config = object({
#       desired_size = number
#       max_size     = number
#       min_size     = number
#     })
#   }))
#   validation {
#     condition     = alltrue([for ng in var.node_groups : contains(["ON_DEMAND", "SPOT"], ng.capacity_type)])
#     error_message = "capacity_type은 'ON_DEMAND' 또는 'SPOT'이어야 합니다."
#   }
# } 
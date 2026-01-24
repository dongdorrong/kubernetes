variable "project_name" {
  description = "Project name"
  type        = string
  default     = ""
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = ""
}

variable "region" {
  description = "AWS region"
  type        = string
  default     = ""
}

variable "profile" {
  description = "AWS CLI profile"
  type        = string
  default     = ""
}

variable "vpc_cidr" {
  description = "VPC CIDR block"
  type        = string
  default     = ""
}

variable "azs" {
  description = "Availability zones"
  type        = list(string)
  default     = []
}

variable "public_subnet_cidrs" {
  description = "Public subnet CIDR blocks"
  type        = list(string)
  default     = []
}

variable "private_subnet_cidrs" {
  description = "Private subnet CIDR blocks"
  type        = list(string)
  default     = []
}

variable "admin_cidrs" {
  description = "CIDR blocks allowed to access the EKS API"
  type        = list(string)
  default     = []
}

variable "admin_principal_arns" {
  description = "Additional IAM principal ARNs to grant EKS admin access"
  type        = list(string)
  default     = []
}

variable "eks_version" {
  description = "EKS Kubernetes version"
  type        = string
  default     = ""
}

variable "node_instance_types" {
  description = "EKS node instance types"
  type        = list(string)
  default     = []
}

variable "node_capacity_type" {
  description = "EKS node capacity type (SPOT or ON_DEMAND)"
  type        = string
  default     = ""
}

variable "node_desired_size" {
  description = "EKS node desired size"
  type        = number
  default     = 0
}

variable "node_min_size" {
  description = "EKS node minimum size"
  type        = number
  default     = 0
}

variable "node_max_size" {
  description = "EKS node maximum size"
  type        = number
  default     = 0
}

variable "rds_engine" {
  description = "RDS engine"
  type        = string
  default     = ""
}

variable "rds_engine_version" {
  description = "RDS engine version"
  type        = string
  default     = ""
}

variable "rds_instance_class" {
  description = "RDS instance class"
  type        = string
  default     = ""
}

variable "rds_allocated_storage" {
  description = "RDS allocated storage (GiB)"
  type        = number
  default     = 0
}

variable "rds_db_name" {
  description = "Initial database name"
  type        = string
  default     = ""
}

variable "rds_username" {
  description = "Master username"
  type        = string
  default     = ""
}

variable "rds_port" {
  description = "Database port"
  type        = number
  default     = 0
}

variable "rds_multi_az" {
  description = "Enable multi-AZ RDS"
  type        = bool
  default     = false
}

variable "rds_backup_retention_days" {
  description = "RDS backup retention days"
  type        = number
  default     = 0
}

variable "ec2_enabled" {
  description = "Whether to create a Teleport test EC2 instance"
  type        = bool
  default     = false
}

variable "ec2_instance_type" {
  description = "EC2 instance type for Teleport node"
  type        = string
  default     = ""
}

variable "ec2_key_name" {
  description = "EC2 key pair name (optional)"
  type        = string
  default     = ""
}

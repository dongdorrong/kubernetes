variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "project_name" {
  description = "Project name used for tagging"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where the cluster is deployed"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block of the VPC for security group rules"
  type        = string
}

variable "public_subnet_ids" {
  description = "List of public subnet IDs"
  type        = list(string)
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs"
  type        = list(string)
}

variable "node_tags" {
  description = "Tags applied to worker nodes"
  type        = map(string)
  default     = {}
}

variable "terraform_role_arn" {
  description = "ARN of the Terraform administrator role"
  type        = string
}

variable "eks_role_arn" {
  description = "ARN of the EKS administrator role"
  type        = string
}

variable "node_instance_types" {
  description = "Instance types used by the default node group"
  type        = list(string)
  default     = ["t3.medium"]
}

variable "node_capacity_type" {
  description = "Capacity type for nodes (SPOT or ON_DEMAND)"
  type        = string
  default     = "SPOT"
}

variable "node_desired_size" {
  description = "Desired node count"
  type        = number
  default     = 2
}

variable "node_min_size" {
  description = "Minimum node count"
  type        = number
  default     = 2
}

variable "node_max_size" {
  description = "Maximum node count"
  type        = number
  default     = 2
}

variable "terraform_role_name" {
  description = "Name of the terraform assume role to query"
  type        = string
}

variable "eks_role_name" {
  description = "Name of the EKS admin assume role to query"
  type        = string
}

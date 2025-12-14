variable "cluster_name" {
  type        = string
  description = "Name of the target EKS cluster"
}

variable "cluster_arn" {
  type        = string
  description = "ARN of the target EKS cluster"
}

variable "cluster_identity_oidc_issuer" {
  type        = string
  description = "OIDC issuer URL of the cluster"
}

variable "oidc_provider_arn" {
  type        = string
  description = "ARN of the aws_iam_openid_connect_provider associated with the cluster"
}

variable "vpc_id" {
  type        = string
  description = "VPC ID used by the cluster (for ALB controller)"
}

variable "project_name" {
  type        = string
  description = "Project name used for naming IAM roles/policies"
}

variable "region" {
  type        = string
  description = "AWS region (used by ALB controller values)"
}

variable "node_name_format" {
  type        = string
  description = "Node name format used by Karpenter templates"
}

variable "owner_account_id" {
  type        = string
  description = "AWS account ID used in KMS policies"
}

variable "terraform_role_name" {
  type        = string
  description = "Terraform administrator role name"
}

variable "eks_role_name" {
  type        = string
  description = "EKS administrator role name"
}

variable "cluster_role_name" {
  type        = string
  description = "EKS cluster IAM role name"
}

variable "efs_csi_enabled" {
  type        = bool
  default     = false
  description = "Flag to enable EFS CSI driver addon (reserved for future use)"
}

variable "enable_hardeneks_access" {
  type        = bool
  default     = false
  description = "Whether to create GitHub Actions HardenEKS IAM / RBAC resources"
}

variable "hardeneks_github_subjects" {
  type        = list(string)
  default     = ["repo:dongdorrong/hardeneks-test:ref:refs/heads/*"]
  description = "Allowed GitHub OIDC subjects (token.actions.githubusercontent.com:sub) for HardenEKS runner"
}

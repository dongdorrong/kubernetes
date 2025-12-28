terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 3.0"
    }
  }
  required_version = ">= 1.2.0"

  backend "local" {
    path = "./tfstate/terraform.tfstate"
  }
}

variable "region" {
  type    = string
  default = "ap-northeast-2"
}

variable "profile" {
  type    = string
  default = "private"
}

variable "cluster_name" {
  type    = string
  default = "ekscapabilities"
}

variable "capability_name" {
  type    = string
  default = "cap-kro"
}

variable "delete_propagation_policy" {
  type    = string
  default = "RETAIN"
}

variable "associate_cluster_admin_policy" {
  type    = bool
  default = true
}

variable "cluster_admin_policy_arn" {
  type    = string
  default = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
}

variable "wait_for_active" {
  type    = bool
  default = true
}

variable "wait_timeout_seconds" {
  type    = number
  default = 900
}

provider "aws" {
  region  = var.region
  profile = var.profile
}

locals {
  role_name = "${var.cluster_name}-kro-capability-role"
}

data "aws_iam_policy_document" "capability_assume_role" {
  statement {
    effect = "Allow"
    actions = [
      "sts:AssumeRole",
      "sts:TagSession"
    ]
    principals {
      type        = "Service"
      identifiers = ["capabilities.eks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "capability" {
  name               = local.role_name
  assume_role_policy = data.aws_iam_policy_document.capability_assume_role.json
}

resource "null_resource" "capability" {
  triggers = {
    cluster_name    = var.cluster_name
    capability_name = var.capability_name
    region          = var.region
    role_arn         = aws_iam_role.capability.arn
  }

  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command = <<-EOT
      set -euo pipefail
      command -v aws >/dev/null 2>&1

      if aws eks describe-capability \
        --region ${var.region} \
        --cluster-name ${var.cluster_name} \
        --capability-name ${var.capability_name} >/dev/null 2>&1; then
        echo "Capability ${var.capability_name} already exists. Skipping create."
      else
        aws eks create-capability \
          --region ${var.region} \
          --cluster-name ${var.cluster_name} \
          --capability-name ${var.capability_name} \
          --type KRO \
          --role-arn ${aws_iam_role.capability.arn} \
          --delete-propagation-policy ${var.delete_propagation_policy}
      fi
    EOT
  }

  provisioner "local-exec" {
    when        = destroy
    interpreter = ["/bin/bash", "-c"]
    command = <<-EOT
      set -euo pipefail
      aws eks delete-capability \
        --region ${self.triggers.region} \
        --cluster-name ${self.triggers.cluster_name} \
        --capability-name ${self.triggers.capability_name} || true
    EOT
  }

  depends_on = [aws_iam_role.capability]
}

resource "null_resource" "wait_active" {
  triggers = {
    cluster_name     = var.cluster_name
    capability_name  = var.capability_name
    region           = var.region
    wait_enabled     = tostring(var.wait_for_active)
    wait_timeout_sec = tostring(var.wait_timeout_seconds)
  }

  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command = <<-EOT
      set -euo pipefail
      if [ "${var.wait_for_active}" != "true" ]; then
        echo "wait_for_active=false. Skipping wait."
        exit 0
      fi

      start_ts=$(date +%s)
      while true; do
        status=$(aws eks describe-capability \
          --region ${var.region} \
          --cluster-name ${var.cluster_name} \
          --capability-name ${var.capability_name} \
          --query 'capability.status' \
          --output text 2>/dev/null || true)

        if [ "$status" = "ACTIVE" ]; then
          echo "Capability ${var.capability_name} is ACTIVE."
          exit 0
        fi

        now_ts=$(date +%s)
        elapsed=$((now_ts - start_ts))
        if [ $elapsed -ge ${var.wait_timeout_seconds} ]; then
          echo "Timed out waiting for capability to become ACTIVE (status=$status)."
          exit 1
        fi

        echo "Waiting for capability to become ACTIVE (status=$status)..."
        sleep 15
      done
    EOT
  }

  depends_on = [null_resource.capability]
}

resource "null_resource" "associate_access_policy" {
  count = var.associate_cluster_admin_policy ? 1 : 0

  triggers = {
    cluster_name = var.cluster_name
    region       = var.region
    role_arn      = aws_iam_role.capability.arn
    policy_arn    = var.cluster_admin_policy_arn
  }

  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command = <<-EOT
      set -euo pipefail
      command -v aws >/dev/null 2>&1

      existing=$(aws eks list-associated-access-policies \
        --region ${var.region} \
        --cluster-name ${var.cluster_name} \
        --principal-arn ${aws_iam_role.capability.arn} \
        --query "associatedAccessPolicies[?policyArn=='${var.cluster_admin_policy_arn}'] | length(@)" \
        --output text)

      if [ "$existing" = "0" ]; then
        aws eks associate-access-policy \
          --region ${var.region} \
          --cluster-name ${var.cluster_name} \
          --principal-arn ${aws_iam_role.capability.arn} \
          --policy-arn ${var.cluster_admin_policy_arn} \
          --access-scope type=cluster
      else
        echo "Access policy already associated. Skipping."
      fi
    EOT
  }

  provisioner "local-exec" {
    when        = destroy
    interpreter = ["/bin/bash", "-c"]
    command = <<-EOT
      set -euo pipefail
      aws eks disassociate-access-policy \
        --region ${self.triggers.region} \
        --cluster-name ${self.triggers.cluster_name} \
        --principal-arn ${self.triggers.role_arn} \
        --policy-arn ${self.triggers.policy_arn} \
        --access-scope type=cluster || true
    EOT
  }

  depends_on = [null_resource.wait_active]
}

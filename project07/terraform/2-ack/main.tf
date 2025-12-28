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
  default = "cap-ack"
}

variable "delete_propagation_policy" {
  type    = string
  default = "RETAIN"
}

variable "policy_arns" {
  type        = list(string)
  description = "IAM policies to attach to the ACK capability role"
  default     = ["arn:aws:iam::aws:policy/AdministratorAccess"]
}

provider "aws" {
  region  = var.region
  profile = var.profile
}

locals {
  role_name = "${var.cluster_name}-ack-capability-role"
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

resource "aws_iam_role_policy_attachment" "capability" {
  for_each   = toset(var.policy_arns)
  role       = aws_iam_role.capability.name
  policy_arn = each.value
}

resource "null_resource" "capability" {
  triggers = {
    cluster_name    = var.cluster_name
    capability_name = var.capability_name
    region          = var.region
    role_arn         = aws_iam_role.capability.arn
    policy_arns      = join(",", var.policy_arns)
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
          --type ACK \
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

  depends_on = [aws_iam_role_policy_attachment.capability]
}

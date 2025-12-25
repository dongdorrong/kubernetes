terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.0"
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
  default = "eksciliumtest"
}

variable "cilium_namespace" {
  type    = string
  default = "kube-system"
}

variable "restart_namespaces" {
  type    = list(string)
  default = ["kube-system"]
}

variable "restart_all_pods" {
  type    = bool
  default = false
}

provider "aws" {
  region  = var.region
  profile = var.profile
}

data "aws_eks_cluster" "this" {
  name = var.cluster_name
}

locals {
  k8s_service_host = replace(data.aws_eks_cluster.this.endpoint, "https://", "")
  restart_namespace_list = join(" ", var.restart_namespaces)
  cilium_values = {
    k8sServiceHost       = local.k8s_service_host
    k8sServicePort       = 443
    kubeProxyReplacement = false
    operator             = { replicas = 1 }
    cni = {
      chainingMode = "aws-cni"
      customConf   = false
      exclusive    = false
      install      = true
    }
  }
  cilium_values_hash = sha1(yamlencode(local.cilium_values))
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.this.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.this.certificate_authority[0].data)

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    args        = ["eks", "get-token", "--cluster-name", var.cluster_name, "--profile", var.profile]
    command     = "aws"
  }
}

provider "helm" {
  kubernetes {
    host                   = data.aws_eks_cluster.this.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.this.certificate_authority[0].data)

    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      args        = ["eks", "get-token", "--cluster-name", var.cluster_name, "--profile", var.profile]
      command     = "aws"
    }
  }
}

resource "helm_release" "cilium" {
  name             = "cilium"
  repository       = "https://helm.cilium.io/"
  chart            = "cilium"
  namespace        = var.cilium_namespace
  create_namespace = false

  values = [yamlencode(local.cilium_values)]
}

resource "null_resource" "restart_workloads" {
  triggers = {
    namespaces         = local.restart_namespace_list
    restart_all        = tostring(var.restart_all_pods)
    cilium_values_hash = local.cilium_values_hash
  }

  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command = <<-EOT
      set -euo pipefail
      command -v kubectl >/dev/null 2>&1
      kubectl -n kube-system rollout status ds/cilium --timeout=5m
      for ns in ${local.restart_namespace_list}; do
        if [ "${var.restart_all_pods}" = "true" ]; then
          kubectl -n "$ns" delete pod --all
        else
          kubectl -n "$ns" rollout restart deploy,daemonset,statefulset --all || true
        fi
      done
    EOT
  }

  depends_on = [helm_release.cilium]
}

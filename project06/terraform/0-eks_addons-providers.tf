variable "enable_hardeneks_access" {
  description = "Set to true to create GitHub HardenEKS IAM/RBAC resources"
  type        = bool
  default     = false
}

data "aws_eks_cluster" "addons" {
  name = module.eks_default.cluster_name

  depends_on = [module.eks_default]
}

data "aws_eks_cluster_auth" "addons" {
  name = module.eks_default.cluster_name

  depends_on = [module.eks_default]
}

locals {
  eks_addons_cluster_endpoint = data.aws_eks_cluster.addons.endpoint
  eks_addons_cluster_ca       = base64decode(data.aws_eks_cluster.addons.certificate_authority[0].data)
  eks_addons_cluster_token    = data.aws_eks_cluster_auth.addons.token
}

provider "kubernetes" {
  alias                  = "eks_addons"
  host                   = local.eks_addons_cluster_endpoint
  cluster_ca_certificate = local.eks_addons_cluster_ca
  token                  = local.eks_addons_cluster_token
}

provider "helm" {
  alias = "eks_addons"

  kubernetes {
    host                   = local.eks_addons_cluster_endpoint
    cluster_ca_certificate = local.eks_addons_cluster_ca
    token                  = local.eks_addons_cluster_token
  }
}

provider "kubectl" {
  alias                  = "eks_addons"
  host                   = local.eks_addons_cluster_endpoint
  cluster_ca_certificate = local.eks_addons_cluster_ca
  token                  = local.eks_addons_cluster_token
  load_config_file       = false
}

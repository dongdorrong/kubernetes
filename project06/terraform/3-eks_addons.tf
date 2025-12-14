module "eks_addons" {
  source = "./modules/eks_addons"

  providers = {
    kubernetes = kubernetes.eks_addons
    helm       = helm.eks_addons
    kubectl    = kubectl.eks_addons
  }

  depends_on = [module.eks_default]

  project_name                 = local.project_name
  cluster_name                 = module.eks_default.cluster_name
  cluster_arn                  = module.eks_default.cluster_arn
  cluster_identity_oidc_issuer = module.eks_default.cluster_oidc_issuer
  oidc_provider_arn            = module.eks_default.oidc_provider_arn
  vpc_id                       = module.network.vpc_id
  region                       = "ap-northeast-2"
  node_name_format             = local.node_name_format
  owner_account_id             = module.iam_assume_roles.account_id
  terraform_role_name          = "terraform-assume-role"
  eks_role_name                = "eks-assume-role"
  cluster_role_name            = module.eks_default.cluster_role_name
  enable_hardeneks_access      = var.enable_hardeneks_access
}

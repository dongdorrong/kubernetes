module "network" {
  source = "./modules/network"

  project_name         = local.project_name
  cluster_name         = local.cluster_name
  vpc_cidr             = local.vpc_cidr
  azs                  = local.azs
  public_subnet_cidrs  = local.public_subnet_cidrs
  private_subnet_cidrs = local.private_subnet_cidrs
}

module "acm" {
  source = "./modules/acm"

  domain_name = "dongdorrong.com"
}

module "iam_assume_roles" {
  source = "./modules/iam_assume_roles"

  terraform_role_name = "terraform-assume-role"
  eks_role_name       = "eks-assume-role"
}
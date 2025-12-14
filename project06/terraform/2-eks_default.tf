module "eks_default" {
  source = "./modules/eks_default"

  cluster_name       = local.cluster_name
  project_name       = local.project_name
  vpc_id             = module.network.vpc_id
  vpc_cidr           = local.vpc_cidr
  public_subnet_ids  = module.network.public_subnet_ids
  private_subnet_ids = module.network.private_subnet_ids
  node_tags          = local.node_tags
  terraform_role_arn = module.iam_assume_roles.terraform_role_arn
  eks_role_arn       = module.iam_assume_roles.eks_role_arn

  node_instance_types = ["t3.medium"]
  node_capacity_type  = "SPOT"
  node_desired_size   = 2
  node_min_size       = 2
  node_max_size       = 2
}
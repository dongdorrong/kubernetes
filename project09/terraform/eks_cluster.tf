# EKS Cluster
resource "aws_eks_cluster" "this" {
  name     = local.cluster_name
  role_arn = aws_iam_role.cluster.arn
  version  = "1.33"

  vpc_config {
    subnet_ids              = concat(local.private_subnet_ids, local.public_subnet_ids)
    security_group_ids      = [aws_security_group.cluster_additional.id]
    endpoint_private_access = true
    endpoint_public_access  = true
    public_access_cidrs     = local.admin_cidrs
  }

  access_config {
    authentication_mode                         = "API_AND_CONFIG_MAP"
    bootstrap_cluster_creator_admin_permissions = false
  }

  kubernetes_network_config {
    elastic_load_balancing {
      enabled = false
    }
    ip_family         = "ipv4"
    service_ipv4_cidr = "172.20.0.0/16"
  }

  upgrade_policy {
    support_type = "EXTENDED"
  }

  bootstrap_self_managed_addons = true

  tags = {
    Project = local.cluster_name
  }

  depends_on = [
    aws_iam_role_policy_attachment.cluster_AmazonEKSClusterPolicy,
    aws_iam_role_policy_attachment.cluster_AmazonEKSServicePolicy,
    aws_security_group.cluster_additional,
    aws_iam_role.cluster,
  ]
}

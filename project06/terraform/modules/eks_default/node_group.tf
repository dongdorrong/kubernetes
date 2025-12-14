resource "aws_eks_node_group" "default" {
  node_group_name = var.project_name
  cluster_name    = aws_eks_cluster.this.name
  node_role_arn   = aws_iam_role.default_node_group.arn
  subnet_ids      = local.subnet_ids

  instance_types = var.node_instance_types
  ami_type       = "BOTTLEROCKET_x86_64"
  capacity_type  = var.node_capacity_type

  scaling_config {
    desired_size = var.node_desired_size
    min_size     = var.node_min_size
    max_size     = var.node_max_size
  }

  update_config {
    max_unavailable = 2
  }

  launch_template {
    name    = aws_launch_template.default.name
    version = aws_launch_template.default.default_version
  }

  depends_on = [
    aws_launch_template.default,
    aws_iam_role_policy_attachment.default_node_nodePolicy,
    aws_iam_role_policy_attachment.default_node_cniPolicy,
    aws_iam_role_policy_attachment.default_node_registryPolicy
  ]
}

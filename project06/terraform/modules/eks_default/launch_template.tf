resource "aws_launch_template" "default" {
  name = var.project_name

  vpc_security_group_ids = [aws_security_group.worker_default.id]

  tag_specifications {
    resource_type = "instance"
    tags          = var.node_tags
  }

  depends_on = [aws_eks_cluster.this]
}

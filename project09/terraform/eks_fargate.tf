# Fargate Profile (기본 네임스페이스)
resource "aws_eks_fargate_profile" "default" {
  cluster_name         = aws_eks_cluster.this.name
  fargate_profile_name = "${local.cluster_name}-default"

  pod_execution_role_arn = aws_iam_role.fargate_pod_execution.arn

  subnet_ids = local.private_subnet_ids

  selector {
    namespace = "kube-system"
  }

  selector {
    namespace = "${local.environment}-n-mgmt"
  }

  tags = {
    Project = local.cluster_name
    Name    = "${local.cluster_name}-default"
  }

  depends_on = [
    aws_eks_cluster.this,
    aws_iam_role.fargate_pod_execution,
    aws_iam_role_policy_attachment.fargate_pod_execution,
  ]
}

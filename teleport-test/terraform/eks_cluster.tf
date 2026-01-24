resource "aws_security_group" "cluster_additional" {
  name        = "${local.project_name}-cluster-additional"
  description = "Additional EKS cluster security group"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [local.vpc_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${local.project_name}-cluster-additional-sg"
  }
}

resource "aws_eks_cluster" "this" {
  name     = local.cluster_name
  role_arn = aws_iam_role.cluster.arn
  version  = local.eks_version

  vpc_config {
    subnet_ids              = local.subnet_ids
    endpoint_private_access = true
    endpoint_public_access  = true
    public_access_cidrs     = local.admin_cidrs
    security_group_ids      = [aws_security_group.cluster_additional.id]
  }

  access_config {
    authentication_mode = "API_AND_CONFIG_MAP"
  }

  depends_on = [
    aws_iam_role_policy_attachment.cluster_AmazonEKSClusterPolicy,
    aws_iam_role_policy_attachment.cluster_AmazonEKSServicePolicy,
    aws_security_group.cluster_additional
  ]
}

resource "aws_security_group" "worker_default" {
  name        = "${local.project_name}-worker"
  description = "EKS worker node security group"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "Node to node"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    self        = true
  }

  ingress {
    description     = "Control plane to node"
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    security_groups = [aws_eks_cluster.this.vpc_config[0].cluster_security_group_id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${local.project_name}-worker-sg"
  }

  depends_on = [aws_eks_cluster.this]
}

resource "aws_launch_template" "default" {
  name = "${local.project_name}-node"

  vpc_security_group_ids = [aws_security_group.worker_default.id]

  tag_specifications {
    resource_type = "instance"
    tags          = local.node_tags
  }
}

resource "aws_eks_node_group" "default" {
  node_group_name = local.project_name

  cluster_name  = aws_eks_cluster.this.name
  node_role_arn = aws_iam_role.default_node_group.arn
  subnet_ids    = local.private_subnet_ids

  instance_types = local.node_instance_types
  ami_type       = "AL2_x86_64"
  capacity_type  = local.node_capacity_type

  scaling_config {
    desired_size = local.node_desired_size
    min_size     = local.node_min_size
    max_size     = local.node_max_size
  }

  launch_template {
    name    = aws_launch_template.default.name
    version = aws_launch_template.default.latest_version
  }

  depends_on = [
    aws_launch_template.default,
    aws_iam_role_policy_attachment.default_node_nodePolicy,
    aws_iam_role_policy_attachment.default_node_cniPolicy,
    aws_iam_role_policy_attachment.default_node_registryPolicy,
  ]
}

data "tls_certificate" "this" {
  url = aws_eks_cluster.this.identity[0].oidc[0].issuer
}

resource "aws_iam_openid_connect_provider" "this" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.this.certificates[0].sha1_fingerprint]
  url             = aws_eks_cluster.this.identity[0].oidc[0].issuer

  depends_on = [aws_eks_cluster.this]
}

# Karpenter IAM and deployment
resource "aws_iam_role" "karpenter_node" {
  name = "${var.project_name}-karpenter-node-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "karpenter_node_eks_worker" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.karpenter_node.name
}

resource "aws_iam_role_policy_attachment" "karpenter_node_eks_cni" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.karpenter_node.name
}

resource "aws_iam_role_policy_attachment" "karpenter_node_ecr" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.karpenter_node.name
}

resource "aws_iam_role_policy_attachment" "karpenter_node_ssm" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  role       = aws_iam_role.karpenter_node.name
}

resource "aws_iam_role" "karpenter_controller" {
  name = "${var.project_name}-karpenter-controller-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = var.oidc_provider_arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "${local.oidc_issuer_path}:aud" = "sts.amazonaws.com"
            "${local.oidc_issuer_path}:sub" = "system:serviceaccount:karpenter:karpenter"
          }
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "karpenter_controller" {
  name = "karpenter-policy"
  role = aws_iam_role.karpenter_controller.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "ec2:CreateLaunchTemplate",
          "ec2:CreateFleet",
          "ec2:RunInstances",
          "ec2:CreateTags",
          "ec2:TerminateInstances",
          "ec2:DescribeLaunchTemplates",
          "ec2:DescribeInstances",
          "ec2:DescribeSecurityGroups",
          "ec2:DescribeSubnets",
          "ec2:DescribeInstanceTypes",
          "ec2:DescribeInstanceTypeOfferings",
          "ec2:DescribeAvailabilityZones",
          "ssm:GetParameter",
          "eks:DescribeCluster",
          "ec2:DescribeImages",
          "iam:GetInstanceProfile",
          "iam:ListInstanceProfiles",
          "iam:CreateInstanceProfile",
          "iam:TagInstanceProfile",
          "iam:AddRoleToInstanceProfile",
          "pricing:GetProducts",
          "ec2:DeleteLaunchTemplate",
          "ec2:DescribeSpotPriceHistory"
        ]
        Effect   = "Allow"
        Resource = "*"
      },
      {
        Action   = ["iam:PassRole"]
        Effect   = "Allow"
        Resource = aws_iam_role.karpenter_node.arn
      }
    ]
  })
}

resource "aws_kms_key" "karpenter" {
  policy = templatefile("${path.module}/../../manifests/karpenter-kms-policy.json", {
    OWNER                     = var.owner_account_id
    TERRAFORM_ADMIN_ROLE      = var.terraform_role_name
    EKS_ADMIN_ROLE            = var.eks_role_name
    CLUSTER_ROLE              = var.cluster_role_name
    KARPENTER_CONTROLLER_ROLE = aws_iam_role.karpenter_controller.name
    KARPENTER_NODE_ROLE       = aws_iam_role.karpenter_node.name
  })
}

resource "aws_iam_instance_profile" "karpenter" {
  name = "karpenter-node-profile"
  role = aws_iam_role.karpenter_node.name
}

resource "helm_release" "karpenter" {
  namespace        = "karpenter"
  create_namespace = true
  name             = "karpenter"
  repository       = "oci://public.ecr.aws/karpenter"
  chart            = "karpenter"
  version          = "1.8.3"
  upgrade_install  = true

  values = [
    yamlencode({
      controller = {
        resources = {
          requests = {
            cpu    = "0.5"
            memory = "1Gi"
          }
          limits = {
            cpu    = "0.5"
            memory = "1Gi"
          }
        }
      }
      serviceAccount = {
        annotations = {
          "eks.amazonaws.com/role-arn" = aws_iam_role.karpenter_controller.arn
        }
      }
      settings = {
        clusterName = var.cluster_name
        aws = {
          defaultInstanceProfile = aws_iam_instance_profile.karpenter.name
        }
        interruptionQueueName = "${var.cluster_name}-karpenter"
      }
    })
  ]

  depends_on = [
    aws_iam_role.karpenter_controller,
    aws_iam_role.karpenter_node,
    aws_iam_instance_profile.karpenter
  ]
}

resource "kubectl_manifest" "karpenter_nodepool" {
  yaml_body = templatefile("${path.module}/../../manifests/karpenter-nodepool.yaml", {})

  depends_on = [
    helm_release.karpenter
  ]
}

resource "kubectl_manifest" "karpenter_nodeclass" {
  yaml_body = templatefile("${path.module}/../../manifests/karpenter-nodeclass.yaml", {
    CLUSTER_NAME  = var.cluster_name
    ALIAS_VERSION = "latest"
    NODE_NAME     = var.node_name_format
    KMS_KEY_ARN   = aws_kms_key.karpenter.arn
  })

  depends_on = [
    helm_release.karpenter,
    aws_kms_key.karpenter
  ]
}

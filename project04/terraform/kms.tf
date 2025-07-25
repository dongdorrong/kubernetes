resource "aws_kms_key" "karpenter" {
    policy = templatefile("${path.module}/manifests/karpenter-kms-policy.json", {
        OWNER                     = local.owner
        TERRAFORM_ADMIN_ROLE      = data.aws_iam_role.terraform_admin.name
        EKS_ADMIN_ROLE            = data.aws_iam_role.eks_admin.name
        CLUSTER_ROLE              = aws_iam_role.cluster.name
        KARPENTER_CONTROLLER_ROLE = aws_iam_role.karpenter_controller.name
        KARPENTER_NODE_ROLE       = aws_iam_role.karpenter_node.name
    })
}
resource "aws_kms_key" "karpenter" {
    policy = templatefile("${path.module}/manifests/karpenter-kms-policy.json", {
        OWNER               = local.owner
        KARPENTER_NODE_ROLE = aws_iam_role.karpenter_node.name
    })
}
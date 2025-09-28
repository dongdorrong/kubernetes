# resource "aws_kms_key" "karpenter" {
#     policy = templatefile("${path.module}/manifests/karpenter-kms-policy.json", {
#         OWNER                     = local.owner
#         TERRAFORM_ADMIN_ROLE      = data.aws_iam_role.terraform_admin.name
#         EKS_ADMIN_ROLE            = data.aws_iam_role.eks_admin.name
#         CLUSTER_ROLE              = aws_iam_role.cluster.name
#         KARPENTER_CONTROLLER_ROLE = aws_iam_role.karpenter_controller.name
#         KARPENTER_NODE_ROLE       = aws_iam_role.karpenter_node.name
#     })

#     depends_on = [
#         aws_eks_cluster.this,
#         helm_release.karpenter
#     ]
# }

# resource "aws_kms_alias" "karpenter" {
#     name          = "alias/${local.owner}-karpenter"
#     target_key_id = aws_kms_key.karpenter.key_id

#     depends_on = [
#         aws_kms_key.karpenter
#     ]
# }
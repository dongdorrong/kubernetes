# # OIDC Provider 설정
# data "tls_certificate" "this" {
#     url = aws_eks_cluster.this.identity[0].oidc[0].issuer
# }

# resource "aws_iam_openid_connect_provider" "this" {
#     client_id_list  = ["sts.amazonaws.com"]
#     thumbprint_list = [data.tls_certificate.this.certificates[0].sha1_fingerprint]
#     url             = aws_eks_cluster.this.identity[0].oidc[0].issuer

#     depends_on = [aws_eks_cluster.this]
# }

# # EBS CSI Controller를 위한 IRSA
# data "aws_iam_policy_document" "ebs_csi_assume_role" {
#     statement {
#         actions = ["sts:AssumeRoleWithWebIdentity"]
#         effect  = "Allow"

#         condition {
#             test     = "StringEquals"
#             variable = "${replace(aws_eks_cluster.this.identity[0].oidc[0].issuer, "https://", "")}:sub"
#             values   = ["system:serviceaccount:kube-system:ebs-csi-controller-sa"]
#         }

#         principals {
#             identifiers = [aws_iam_openid_connect_provider.this.arn]
#             type        = "Federated"
#         }
#     }
# }

# resource "aws_iam_role" "ebs_csi" {
#     name = "eks-ebs-csi-role"
#     assume_role_policy = data.aws_iam_policy_document.ebs_csi_assume_role.json
# }

# resource "aws_iam_role_policy_attachment" "ebs_csi" {
#     role       = aws_iam_role.ebs_csi.name
#     policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
# }

# # VPC CNI를 위한 IRSA
# data "aws_iam_policy_document" "vpc_cni_assume_role" {
#     statement {
#         actions = ["sts:AssumeRoleWithWebIdentity"]
#         effect  = "Allow"

#         condition {
#             test     = "StringEquals"
#             variable = "${replace(aws_eks_cluster.this.identity[0].oidc[0].issuer, "https://", "")}:sub"
#             values   = ["system:serviceaccount:kube-system:aws-node"]
#         }

#         principals {
#             identifiers = [aws_iam_openid_connect_provider.this.arn]
#             type        = "Federated"
#         }
#     }
# }

# resource "aws_iam_role" "vpc_cni" {
#     name = "eks-vpc-cni-role"
#     assume_role_policy = data.aws_iam_policy_document.vpc_cni_assume_role.json
# }

# resource "aws_iam_role_policy_attachment" "vpc_cni" {
#     role       = aws_iam_role.vpc_cni.name
#     policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
# } 
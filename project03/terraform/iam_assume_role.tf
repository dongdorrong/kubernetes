# # 테라폼 관리용 역할 (기존 역할을 테라폼으로 관리하기 위한 정의)
# resource "aws_iam_role" "terraform_admin" {
#     name                 = "terraform-assume-role"
#     # name                 = "${local.project_name}-terraform-assume-role"
#     max_session_duration = 43200  # 12시간
#     assume_role_policy   = jsonencode({
#         Version = "2012-10-17"
#         Statement = [
#             {
#                 Effect = "Allow"
#                 Principal = {
#                     AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
#                 }
#                 Action = "sts:AssumeRole"
#                 Condition = {}
#             }
#         ]
#     })
# }

# # 테라폼 역할에 관리자 권한 부여
# resource "aws_iam_role_policy_attachment" "terraform_admin" {
#     role       = aws_iam_role.terraform_admin.name
#     policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
# }

# # EKS 관리자 IAM 역할
# resource "aws_iam_role" "eks_admin" {
#     name                 = "eks-assume-role"
#     # name                 = "${local.project_name}-eks-assume-role"
#     max_session_duration = 43200  # 12시간
#     assume_role_policy   = jsonencode({
#         Version = "2012-10-17"
#         Statement = [
#             {
#                 Effect = "Allow"
#                 Principal = {
#                     AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
#                 }
#                 Action = "sts:AssumeRole"
#             }
#         ]
#     })
# }

# # EKS 관리자 정책
# resource "aws_iam_role_policy" "eks_admin" {
#     name = "eks-admin-policy"
#     role = aws_iam_role.eks_admin.id

#     policy = jsonencode({
#         Version = "2012-10-17"
#         Statement = [
#             {
#                 Effect = "Allow"
#                 Action = [
#                     "eks:DescribeCluster"    # kubeconfig 생성 및 클러스터 접근에 필요
#                 ]
#                 Resource = "*"
#             }
#         ]
#     })
# }

# # EKS 역할에 관리자 권한 부여
# resource "aws_iam_role_policy_attachment" "eks_admin" {
#     role       = aws_iam_role.eks_admin.name
#     policy_arn = aws_iam_role_policy.eks_admin
# }

# AWS 계정 ID를 가져오기 위한 데이터 소스
data "aws_caller_identity" "current" {} 
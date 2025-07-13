# Kubecost IAM 정책 생성
resource "aws_iam_policy" "kubecost" {
    name        = "${local.project_name}-kubecost-policy"
    description = "IAM policy for Kubecost cost analyzer"

    policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
            {
                Effect = "Allow"
                Action = [
                    "ec2:DescribeInstances",
                    "ec2:DescribeVolumes",
                    "ec2:DescribeSnapshots",
                    "ec2:DescribeImages",
                    "ec2:DescribeAddresses",
                    "ec2:DescribeReservedInstances",
                    "ec2:DescribeSpotInstanceRequests",
                    "ec2:DescribeSpotPriceHistory",
                    "ec2:DescribeRegions",
                    "ec2:DescribeAvailabilityZones",
                    "eks:DescribeCluster",
                    "eks:ListClusters",
                    "pricing:GetProducts",
                    "pricing:DescribeServices",
                    "pricing:GetAttributeValues",
                    "sts:GetCallerIdentity"
                ]
                Resource = "*"
            }
        ]
    })
}

# Kubecost IAM 역할 생성
resource "aws_iam_role" "kubecost" {
    name = "${local.project_name}-kubecost-role"

    assume_role_policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
            {
                Effect = "Allow"
                Principal = {
                    Federated = aws_iam_openid_connect_provider.this.arn
                }
                Action = "sts:AssumeRoleWithWebIdentity"
                Condition = {
                    StringEquals = {
                        "${replace(aws_eks_cluster.this.identity[0].oidc[0].issuer, "https://", "")}:sub": "system:serviceaccount:kubecost:kubecost-cost-analyzer"
                        "${replace(aws_eks_cluster.this.identity[0].oidc[0].issuer, "https://", "")}:aud": "sts.amazonaws.com"
                    }
                }
            }
        ]
    })
}

# IAM 역할에 정책 연결
resource "aws_iam_role_policy_attachment" "kubecost" {
    role       = aws_iam_role.kubecost.name
    policy_arn = aws_iam_policy.kubecost.arn
}
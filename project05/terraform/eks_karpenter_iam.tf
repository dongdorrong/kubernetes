# Karpenter 노드 IAM 역할
resource "aws_iam_role" "karpenter_node" {
    name               = "${local.project_name}-karpenter-node-role"
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

# Karpenter 노드 IAM 정책 연결
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

# Karpenter 컨트롤러 IAM 역할
resource "aws_iam_role" "karpenter_controller" {
    name               = "${local.project_name}-karpenter-controller-role"
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
                        "${replace(aws_eks_cluster.this.identity[0].oidc[0].issuer, "https://", "")}:aud": "sts.amazonaws.com",
                        "${replace(aws_eks_cluster.this.identity[0].oidc[0].issuer, "https://", "")}:sub": "system:serviceaccount:karpenter:karpenter"
                    }
                }
            }
        ]
    })
}

# Karpenter 컨트롤러 IAM 정책
resource "aws_iam_role_policy" "karpenter_controller" {
    name = "karpenter-policy"
    role   = aws_iam_role.karpenter_controller.id
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
                Action = [
                    "iam:PassRole",
                ]
                Effect   = "Allow"
                Resource = aws_iam_role.karpenter_node.arn
            }
        ]
    })
}
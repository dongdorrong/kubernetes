/*
# Karpenter 노드 IAM 역할
resource "aws_iam_role" "karpenter_node" {
    name = "eksstudy-karpenter-node-role"

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

# Karpenter 노드 인스턴스 프로파일
resource "aws_iam_instance_profile" "karpenter" {
    name = "eksstudy-karpenter-node-profile"
    role = aws_iam_role.karpenter_node.name
}

# Karpenter 컨트롤러 IAM 역할
resource "aws_iam_role" "karpenter_controller" {
    name = "eksstudy-karpenter-controller-role"

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
    name = "eksstudy-karpenter-policy"
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
                    "ec2:DescribeSpotPriceHistory",
                    "pricing:GetProducts",
                    "ssm:GetParameter",
                    "iam:PassRole",
                    "eks:DescribeCluster"
                ]
                Effect   = "Allow"
                Resource = "*"
            }
        ]
    })
}

# Karpenter Helm 차트 설치
resource "helm_release" "karpenter" {
    namespace        = "karpenter"
    create_namespace = true

    name       = "karpenter"
    repository = "oci://public.ecr.aws/karpenter"
    chart      = "karpenter"
    version    = "v1.3.3"

    timeout = 900 # 15분

    set {
        name  = "settings.aws.defaultInstanceProfile"
        value = aws_iam_instance_profile.karpenter.name
    }

    set {
        name  = "settings.aws.clusterName"
        value = aws_eks_cluster.this.name
    }

    set {
        name  = "settings.aws.clusterEndpoint"
        value = aws_eks_cluster.this.endpoint
    }

    set {
        name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
        value = aws_iam_role.karpenter_controller.arn
    }

    set {
        name  = "settings.aws.interruptionQueueName"
        value = "${aws_eks_cluster.this.name}-karpenter"
    }

    depends_on = [
        aws_eks_cluster.this,
        aws_iam_role.karpenter_controller,
        aws_iam_role.karpenter_node,
        aws_iam_instance_profile.karpenter,
        aws_iam_openid_connect_provider.this
    ]
}

# Karpenter Provisioner 및 NodeClass 설정
resource "kubectl_manifest" "karpenter_provisioner" {
    yaml_body = templatefile("${path.module}/manifests/karpenter-provisioner.yaml", {})

    depends_on = [
        helm_release.karpenter
    ]
}

resource "kubectl_manifest" "karpenter_node_class" {
    yaml_body = templatefile("${path.module}/manifests/karpenter-node-class.yaml", {
        cluster_name = local.cluster_name
    })

    depends_on = [
        helm_release.karpenter
    ]
}
*/ 
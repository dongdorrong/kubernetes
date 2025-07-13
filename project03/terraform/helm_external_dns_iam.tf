
# External DNS IAM 정책 생성
resource "aws_iam_policy" "external_dns" {
    name        = "${local.project_name}-external-dns-policy"
    description = "IAM policy for External DNS to manage Route53 records"

    policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
            {
                Effect = "Allow"
                Action = [
                    "route53:ChangeResourceRecordSets"
                ]
                Resource = "arn:aws:route53:::hostedzone/*"
            },
            {
                Effect = "Allow"
                Action = [
                    "route53:ListHostedZones",
                    "route53:ListResourceRecordSets"
                ]
                Resource = "*"
            }
        ]
    })
}

# External DNS IAM 역할 생성
resource "aws_iam_role" "external_dns" {
    name = "${local.project_name}-external-dns-role"

    assume_role_policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
            {
                Action = "sts:AssumeRoleWithWebIdentity"
                Effect = "Allow"
                Principal = {
                    Federated = aws_iam_openid_connect_provider.this.arn
                }
                Condition = {
                    StringEquals = {
                        "${replace(aws_eks_cluster.this.identity[0].oidc[0].issuer, "https://", "")}:sub" = "system:serviceaccount:${kubernetes_namespace.external_dns.metadata[0].name}:external-dns"
                        "${replace(aws_eks_cluster.this.identity[0].oidc[0].issuer, "https://", "")}:aud" = "sts.amazonaws.com"
                    }
                }
            }
        ]
    })
}

# External DNS IAM 역할에 정책 연결
resource "aws_iam_role_policy_attachment" "external_dns" {
    role       = aws_iam_role.external_dns.name
    policy_arn = aws_iam_policy.external_dns.arn
}

# External DNS 서비스 계정 생성
resource "kubernetes_service_account" "external_dns" {
    metadata {
        name      = "external-dns"
        namespace = kubernetes_namespace.external_dns.metadata[0].name
        annotations = {
            "eks.amazonaws.com/role-arn" = aws_iam_role.external_dns.arn
        }
    }
}
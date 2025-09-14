# EBS CSI Controller를 위한 IRSA
data "aws_iam_policy_document" "ebs_csi_assume_role" {
    statement {
        actions = ["sts:AssumeRoleWithWebIdentity"]
        effect  = "Allow"

        condition {
            test     = "StringEquals"
            variable = "${replace(aws_eks_cluster.this.identity[0].oidc[0].issuer, "https://", "")}:sub"
            values   = ["system:serviceaccount:kube-system:ebs-csi-controller-sa"]
        }

        principals {
            identifiers = [aws_iam_openid_connect_provider.this.arn]
            type        = "Federated"
        }
    }
}

resource "aws_iam_role" "ebs_csi" {
    name               = "${local.project_name}-ebs-csi-role"
    assume_role_policy = data.aws_iam_policy_document.ebs_csi_assume_role.json
}

resource "aws_iam_role_policy_attachment" "ebs_csi" {
    role       = aws_iam_role.ebs_csi.name
    policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
}

# VPC CNI를 위한 IRSA
data "aws_iam_policy_document" "vpc_cni_assume_role" {
    statement {
        actions = ["sts:AssumeRoleWithWebIdentity"]
        effect  = "Allow"

        condition {
            test     = "StringEquals"
            variable = "${replace(aws_eks_cluster.this.identity[0].oidc[0].issuer, "https://", "")}:sub"
            values   = ["system:serviceaccount:kube-system:aws-node"]
        }

        principals {
            identifiers = [aws_iam_openid_connect_provider.this.arn]
            type        = "Federated"
        }
    }
}

resource "aws_iam_role" "vpc_cni" {
    name = "${local.project_name}-vpc-cni-role"
    assume_role_policy = data.aws_iam_policy_document.vpc_cni_assume_role.json
}

resource "aws_iam_role_policy_attachment" "vpc_cni" {
    role       = aws_iam_role.vpc_cni.name
    policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

# AWS Load Balancer Controller를 위한 IRSA
resource "aws_iam_policy" "aws_load_balancer_controller" {
    name = "${local.project_name}-aws-load-balancer-controller-policy"
    policy = file("${path.module}/manifests/aws-load-balancer-controller-policy.json")
}

resource "aws_iam_role" "aws_load_balancer_controller" {
    name = "${local.project_name}-aws-load-balancer-controller"

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
                        "${replace(aws_eks_cluster.this.identity[0].oidc[0].issuer, "https://", "")}:sub": "system:serviceaccount:kube-system:aws-load-balancer-controller"
                    }
                }
            }
        ]
    })
}

resource "aws_iam_role_policy_attachment" "aws_load_balancer_controller" {
    policy_arn = aws_iam_policy.aws_load_balancer_controller.arn
    role       = aws_iam_role.aws_load_balancer_controller.name
}

resource "kubernetes_service_account" "aws_load_balancer_controller" {
    metadata {
        name      = "aws-load-balancer-controller"
        namespace = "kube-system"
        labels = {
            "app.kubernetes.io/name"      = "aws-load-balancer-controller"
            "app.kubernetes.io/component" = "controller"
        }
        annotations = {
            "eks.amazonaws.com/role-arn" = aws_iam_role.aws_load_balancer_controller.arn
        }
    }
}

# Mountpoint for Amazon S3 CSI 드라이버를 위한 IRSA
resource "aws_iam_policy" "s3_csi" {
    name = "${local.project_name}-s3-csi-policy"
    policy = templatefile("${path.module}/manifests/s3-csi-policy.json", {
        s3_bucket_arn = aws_s3_bucket.app_data.arn
    })

    depends_on = [ aws_s3_bucket.app_data ]
}

resource "aws_iam_role" "s3_csi" {
    name = "${local.project_name}-s3-csi-role"

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
                        "${replace(aws_eks_cluster.this.identity[0].oidc[0].issuer, "https://", "")}:sub": "system:serviceaccount:kube-system:mountpoint-s3-csi-controller-sa"
                    }
                }
            }
        ]
    })
}

resource "aws_iam_role_policy_attachment" "s3_csi" {
    policy_arn = aws_iam_policy.s3_csi.arn
    role       = aws_iam_role.s3_csi.name
}

resource "kubernetes_service_account" "s3_csi" {
    metadata {
        name      = "mountpoint-s3-csi-controller-sa"
        namespace = "kube-system"
        labels = {
            "app.kubernetes.io/name"      = "aws-mountpoint-s3-csi-driver"
        }
        annotations = {
            "eks.amazonaws.com/role-arn" = aws_iam_role.s3_csi.arn
        }
    }
}
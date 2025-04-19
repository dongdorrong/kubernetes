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
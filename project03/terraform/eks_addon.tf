# kube-proxy 애드온
resource "aws_eks_addon" "kube_proxy" {
    cluster_name                = aws_eks_cluster.this.name
    addon_name                  = "kube-proxy"
    resolve_conflicts_on_create = "OVERWRITE"
    resolve_conflicts_on_update = "PRESERVE"

    depends_on = [aws_eks_cluster.this]
}

# CoreDNS 애드온
resource "aws_eks_addon" "coredns" {
    cluster_name                = aws_eks_cluster.this.name
    addon_name                  = "coredns"
    resolve_conflicts_on_create = "OVERWRITE"
    resolve_conflicts_on_update = "PRESERVE"

    depends_on = [aws_eks_cluster.this]
}

# VPC CNI 애드온
resource "aws_eks_addon" "vpc_cni" {
    cluster_name                = aws_eks_cluster.this.name
    addon_name                  = "vpc-cni"
    service_account_role_arn    = aws_iam_role.vpc_cni.arn
    resolve_conflicts_on_create = "OVERWRITE"
    resolve_conflicts_on_update = "PRESERVE"

    depends_on = [
        aws_eks_cluster.this,
        aws_iam_openid_connect_provider.this,
        aws_eks_addon.kube_proxy
    ]
}

# EBS CSI 드라이버 애드온
resource "aws_eks_addon" "ebs_csi" {
    cluster_name                = aws_eks_cluster.this.name
    addon_name                  = "aws-ebs-csi-driver"
    service_account_role_arn    = aws_iam_role.ebs_csi.arn
    resolve_conflicts_on_create = "OVERWRITE"
    resolve_conflicts_on_update = "PRESERVE"

    depends_on = [
        aws_eks_cluster.this,
        aws_iam_openid_connect_provider.this,
        aws_eks_addon.coredns
    ]
}

# # EKS Pod Identity Agent 애드온
# - IRSA의 새로운 대안(2023년 말 출시)으로 OIDC 불필요, 성능 향상
# - 현재는 IRSA가 안정적이므로 보류
# resource "aws_eks_addon" "pod_identity" {
#     cluster_name                = aws_eks_cluster.this.name
#     addon_name                  = "eks-pod-identity-agent"
#     resolve_conflicts_on_create = "OVERWRITE"
#     resolve_conflicts_on_update = "PRESERVE"

#     depends_on = [
#         aws_eks_cluster.this,
#         aws_eks_addon.coredns
#     ]
# }

# Metrics Server 설치
resource "helm_release" "metrics_server" {
    name       = "metrics-server"
    repository = "https://kubernetes-sigs.github.io/metrics-server/"
    chart      = "metrics-server"
    namespace  = "kube-system"

    set {
        name  = "args[0]"
        value = "--kubelet-insecure-tls"
    }

    depends_on = [
        aws_eks_cluster.this,
        aws_eks_addon.coredns
    ]
}
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
    resolve_conflicts_on_create = "OVERWRITE"
    resolve_conflicts_on_update = "PRESERVE"

    depends_on = [
        aws_eks_cluster.this,
        aws_eks_addon.kube_proxy
    ]
}

# EBS CSI 드라이버 애드온
resource "aws_eks_addon" "ebs_csi" {
    cluster_name                = aws_eks_cluster.this.name
    addon_name                  = "aws-ebs-csi-driver"
    resolve_conflicts_on_create = "OVERWRITE"
    resolve_conflicts_on_update = "PRESERVE"

    depends_on = [
        aws_eks_cluster.this,
        aws_eks_addon.coredns
    ]
}

# EKS Pod Identity Agent 애드온
# - IRSA를 대체하는 Pod Identity 사용을 위해 필수
resource "aws_eks_addon" "pod_identity" {
    cluster_name                = aws_eks_cluster.this.name
    addon_name                  = "eks-pod-identity-agent"
    resolve_conflicts_on_create = "OVERWRITE"
    resolve_conflicts_on_update = "PRESERVE"

    depends_on = [
        aws_eks_cluster.this,
        aws_eks_addon.coredns
    ]
}

# Metrics Server  애드온
resource "aws_eks_addon" "metrics_server" {
    cluster_name                = aws_eks_cluster.this.name
    addon_name                  = "metrics-server"
    resolve_conflicts_on_create = "OVERWRITE"
    resolve_conflicts_on_update = "PRESERVE"

    depends_on = [aws_eks_cluster.this]
}

# AWS Load Balancer Controller
# - https://docs.aws.amazon.com/ko_kr/eks/latest/userguide/lbc-helm.html
resource "helm_release" "aws_load_balancer_controller" {
    name       = "aws-load-balancer-controller"
    repository = "https://aws.github.io/eks-charts"
    chart      = "aws-load-balancer-controller"
    namespace  = "kube-system"

    set {
        name  = "region"
        value = "ap-northeast-2"
    }

    set {
        name  = "vpcId"
        value = aws_vpc.main.id
    }

    set {
        name  = "clusterName"
        value = aws_eks_cluster.this.name
    }

    set {
        name  = "serviceAccount.create"
        value = "false"
    }

    set {
        name  = "serviceAccount.name"
        value = "aws-load-balancer-controller"
    }


    set {
        name  = "serviceAccount.name"
        value = "aws-load-balancer-controller"
    }

    depends_on = [
        aws_iam_policy.aws_load_balancer_controller,
        aws_iam_role.aws_load_balancer_controller,
        aws_iam_role_policy_attachment.aws_load_balancer_controller,
        kubernetes_service_account.aws_load_balancer_controller,
        aws_eks_pod_identity_association.aws_load_balancer_controller
    ]
}

# StorageClass 생성
resource "kubernetes_manifest" "storageclass" {
    manifest = yamldecode(file("${path.module}/manifests/storageclass.yaml"))
    depends_on = [
        aws_eks_cluster.this,
        aws_eks_addon.ebs_csi
    ]
}

# # Mountpoint for Amazon S3 CSI 드라이버
# resource "aws_eks_addon" "s3_csi" {
#     cluster_name                = aws_eks_cluster.this.name
#     addon_name                  = "aws-mountpoint-s3-csi-driver"
#     service_account_role_arn    = aws_iam_role.s3_csi.arn
#     resolve_conflicts_on_create = "OVERWRITE"
#     resolve_conflicts_on_update = "PRESERVE"
#     configuration_values = jsonencode({
#         node = {
#             tolerateAllTaints = true
#         }
#     })

#     depends_on = [
#         aws_eks_cluster.this,
#         aws_eks_addon.pod_identity,
#         aws_eks_addon.coredns,
#         aws_s3_bucket.app_data
#     ]
# }

# # 노드 모니터링 에이전트
# resource "aws_eks_addon" "node_monitoring" {
#     cluster_name                = aws_eks_cluster.this.name
#     addon_name                  = "eks-node-monitoring-agent"
#     resolve_conflicts_on_create = "OVERWRITE"
#     resolve_conflicts_on_update = "PRESERVE"

#     depends_on = [aws_eks_cluster.this]
# }

# # AWS Network Flow Monitor Agent
# resource "aws_eks_addon" "network_flow" {
#     cluster_name                = aws_eks_cluster.this.name
#     addon_name                  = "aws-network-flow-monitoring-agent"
#     resolve_conflicts_on_create = "OVERWRITE"
#     resolve_conflicts_on_update = "PRESERVE"

#     depends_on = [aws_eks_cluster.this]
# }

# # AWS Private CA Connector for Kubernetes
# resource "aws_eks_addon" "private_ca" {
#     cluster_name                = aws_eks_cluster.this.name
#     addon_name                  = "aws-privateca-connector-for-kubernetes"
#     resolve_conflicts_on_create = "OVERWRITE"
#     resolve_conflicts_on_update = "PRESERVE"

#     depends_on = [aws_eks_cluster.this]
# }
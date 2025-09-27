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

# EKS Pod Identity Agent 애드온
resource "aws_eks_addon" "pod_identity" {
    cluster_name                = aws_eks_cluster.this.name
    addon_name                  = "eks-pod-identity-agent"
    resolve_conflicts_on_create = "OVERWRITE"
    resolve_conflicts_on_update = "PRESERVE"

    depends_on = [
      aws_eks_cluster.this,
      aws_eks_addon.coredns,
    ]
}

# VPC CNI 애드온
resource "aws_eks_addon" "vpc_cni" {
    cluster_name                = aws_eks_cluster.this.name
    addon_name                  = "vpc-cni"
    resolve_conflicts_on_create = "OVERWRITE"
    resolve_conflicts_on_update = "PRESERVE"

    depends_on = [
      aws_eks_cluster.this,
      aws_eks_addon.kube_proxy,
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
      aws_eks_addon.coredns,
    ]
}

# Metrics Server 애드온
resource "aws_eks_addon" "metrics_server" {
    cluster_name                = aws_eks_cluster.this.name
    addon_name                  = "metrics-server"
    resolve_conflicts_on_create = "OVERWRITE"
    resolve_conflicts_on_update = "PRESERVE"

    depends_on = [aws_eks_cluster.this]
}

# AWS Network Flow Monitor 애드온
resource "aws_eks_addon" "network_flow_monitor" {
    cluster_name                = aws_eks_cluster.this.name
    addon_name                  = "aws-network-flow-monitoring-agent"
    resolve_conflicts_on_create = "OVERWRITE"
    resolve_conflicts_on_update = "PRESERVE"

    depends_on = [
      aws_eks_cluster.this,
      aws_eks_addon.pod_identity,
    ]
}

# 노드 모니터링 애드온
resource "aws_eks_addon" "node_monitoring" {
    cluster_name                = aws_eks_cluster.this.name
    addon_name                  = "eks-node-monitoring-agent"
    resolve_conflicts_on_create = "OVERWRITE"
    resolve_conflicts_on_update = "PRESERVE"

    depends_on = [
      aws_eks_cluster.this,
      aws_eks_addon.pod_identity,
    ]
}

# CSI 스냅샷 컨트롤러 애드온
resource "aws_eks_addon" "snapshot_controller" {
    cluster_name                = aws_eks_cluster.this.name
    addon_name                  = "snapshot-controller"
    resolve_conflicts_on_create = "OVERWRITE"
    resolve_conflicts_on_update = "PRESERVE"

    depends_on = [aws_eks_cluster.this]
}

# AWS Private CA Connector for Kubernetes 애드온
resource "aws_eks_addon" "privateca_connector" {
    cluster_name                = aws_eks_cluster.this.name
    addon_name                  = "aws-privateca-connector-for-kubernetes"
    resolve_conflicts_on_create = "OVERWRITE"
    resolve_conflicts_on_update = "PRESERVE"

    depends_on = [
      aws_eks_cluster.this,
      aws_eks_addon.pod_identity,
    ]
}

# Mountpoint for Amazon S3 CSI 드라이버 애드온
# - https://github.com/awslabs/mountpoint-s3-csi-driver/blob/main/docs/INSTALL.md
# - 2025-09-28 Pod Identity 방식으로 Credential 받아오지 못하는 이슈가 있어서 잠정 보류
# resource "helm_release" "mountpoint_s3_csi" {
#     name       = "aws-mountpoint-s3-csi-driver"
#     repository = "https://awslabs.github.io/mountpoint-s3-csi-driver"
#     chart      = "aws-mountpoint-s3-csi-driver"
#     namespace  = "kube-system"
#     upgrade_install  = true

#     depends_on = [
#       aws_iam_policy.mountpoint_s3_csi,
#       aws_iam_role.mountpoint_s3_csi,
#       aws_iam_role_policy_attachment.mountpoint_s3_csi
#     ]
# }

# Amazon EFS CSI 드라이버 애드온
resource "aws_eks_addon" "efs_csi" {
    cluster_name                = aws_eks_cluster.this.name
    addon_name                  = "aws-efs-csi-driver"
    resolve_conflicts_on_create = "OVERWRITE"
    resolve_conflicts_on_update = "PRESERVE"

    depends_on = [
      aws_eks_cluster.this,
      aws_eks_addon.pod_identity,
    ]
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
      value = data.aws_region.current.name
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
      value = kubernetes_service_account.aws_load_balancer_controller.metadata[0].name
    }

    depends_on = [
      aws_iam_policy.aws_load_balancer_controller,
      aws_iam_role.aws_load_balancer_controller,
      aws_iam_role_policy_attachment.aws_load_balancer_controller,
      kubernetes_service_account.aws_load_balancer_controller,
      aws_eks_pod_identity_association.aws_load_balancer_controller,
    ]
}

# StorageClass 생성
resource "kubernetes_manifest" "storageclass" {
    manifest = yamldecode(file("${path.module}/manifests/storageclass.yaml"))
    depends_on = [
      aws_eks_cluster.this,
      aws_eks_addon.ebs_csi,
    ]
}

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

# Metrics Server  애드온
resource "aws_eks_addon" "metrics_server" {
  cluster_name                = aws_eks_cluster.this.name
  addon_name                  = "metrics-server"
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "PRESERVE"

  depends_on = [aws_eks_cluster.this]
}

# 노드 모니터링 에이전트
resource "aws_eks_addon" "node_monitoring" {
  cluster_name                = aws_eks_cluster.this.name
  addon_name                  = "eks-node-monitoring-agent"
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "PRESERVE"

  depends_on = [aws_eks_cluster.this]
}

####################################################
# EKS Pod Identity Agent 애드온
# - IRSA의 새로운 대안(2023년 말 출시)으로 OIDC 불필요, 성능 향상
# - aws_eks_addon.pod_identity 위에 작성한 애드온들은 POI 미설정
####################################################
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

# VPC CNI 애드온
resource "aws_eks_addon" "vpc_cni" {
  cluster_name                = aws_eks_cluster.this.name
  addon_name                  = "vpc-cni"
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "PRESERVE"

  pod_identity_association {
    role_arn        = aws_iam_role.vpc_cni.arn
    service_account = "aws-node"
  }

  depends_on = [
    aws_eks_cluster.this,
    aws_eks_addon.pod_identity
  ]
}

# EBS CSI 드라이버 애드온
resource "aws_eks_addon" "ebs_csi" {
  cluster_name                = aws_eks_cluster.this.name
  addon_name                  = "aws-ebs-csi-driver"
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "PRESERVE"

  pod_identity_association {
    role_arn        = aws_iam_role.ebs_csi.arn
    service_account = "ebs-csi-controller-sa"
  }

  depends_on = [
    aws_eks_cluster.this,
    aws_eks_addon.pod_identity
  ]
}

# EBS StorageClass 생성
resource "kubernetes_manifest" "storageclass_ebs" {
  manifest = yamldecode(file("${path.module}/manifests/storageclass-ebs.yaml"))
  depends_on = [
    aws_eks_cluster.this,
    aws_eks_addon.ebs_csi
  ]
}

# # AWS Load Balancer Controller
# - https://docs.aws.amazon.com/ko_kr/eks/latest/userguide/lbc-helm.html
resource "helm_release" "aws_load_balancer_controller" {
  name       = "aws-load-balancer-controller"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  namespace  = "kube-system"

  values = [
    yamlencode({
      region      = "ap-northeast-2"
      vpcId       = aws_vpc.main.id
      clusterName = aws_eks_cluster.this.name

      serviceAccount = {
        create = false
        name   = "aws-load-balancer-controller"
      }
    })
  ]

  depends_on = [
    aws_eks_cluster.this,
    aws_eks_addon.pod_identity,
    aws_iam_role_policy_attachment.aws_load_balancer_controller,
    kubernetes_service_account_v1.aws_load_balancer_controller,
    aws_eks_pod_identity_association.aws_load_balancer_controller
  ]
}

# Mountpoint for Amazon S3 CSI 드라이버
resource "aws_eks_addon" "s3_csi" {
  cluster_name                = aws_eks_cluster.this.name
  addon_name                  = "aws-mountpoint-s3-csi-driver"
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "PRESERVE"

  pod_identity_association {
    role_arn        = aws_iam_role.s3_csi.arn
    service_account = "s3-csi-driver-sa"
  }

  configuration_values = jsonencode({
    node = {
      tolerateAllTaints = true
    }
  })

  depends_on = [
    aws_eks_cluster.this,
    aws_eks_addon.pod_identity,
    aws_s3_bucket.app_data
  ]
}

# # AWS Network Flow Monitor Agent
# resource "aws_eks_addon" "network_flow" {
#     cluster_name                = aws_eks_cluster.this.name
#     addon_name                  = "aws-network-flow-monitoring-agent"
#     resolve_conflicts_on_create = "OVERWRITE"
#     resolve_conflicts_on_update = "PRESERVE"

#     pod_identity_association {
#         role_arn = aws_iam_role.network_flow.arn
#         service_account = "aws-network-flow-monitor-agent-service-account"
#     }

#     depends_on = [
#         aws_eks_cluster.this,
#         aws_eks_addon.pod_identity
#     ]
# }

# # AWS Private CA Connector for Kubernetes
# resource "aws_eks_addon" "private_ca" {
#     cluster_name                = aws_eks_cluster.this.name
#     addon_name                  = "aws-privateca-connector-for-kubernetes"
#     resolve_conflicts_on_create = "OVERWRITE"
#     resolve_conflicts_on_update = "PRESERVE"

#     pod_identity_association {
#         role_arn = aws_iam_role.private_ca.arn
#         service_account = "aws-privateca-issuer"
#     }

#     depends_on = [
#         aws_eks_cluster.this,
#         aws_eks_addon.pod_identity
#     ]
# }

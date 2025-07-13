# Kubecost Helm 차트 설치
# https://github.com/kubecost/cost-analyzer-helm-chart

# 네임스페이스 생성
resource "kubernetes_namespace" "kubecost" {
    metadata {
        name = "kubecost"
    }
}

# Kubecost 서비스 계정 생성
resource "kubernetes_service_account" "kubecost" {
    metadata {
        name      = "kubecost-cost-analyzer"
        namespace = kubernetes_namespace.kubecost.metadata[0].name
        annotations = {
            "eks.amazonaws.com/role-arn" = aws_iam_role.kubecost.arn
        }
    }
}

resource "helm_release" "kubecost" {
    name            = "kubecost"
    repository      = "https://kubecost.github.io/cost-analyzer/"
    chart           = "cost-analyzer"
    namespace       = kubernetes_namespace.kubecost.metadata[0].name
    upgrade_install = true

    # Version compatibility: 2.3(k8s 1.21-1.30) | 2.4(k8s 1.22-1.31) | 2.5+(k8s 1.22-1.32+)
    # Current k8s version: 1.30+ → 2.8.0 compatible
    version    = "2.8.0"

    # 무료 버전 사용
    values = [
        yamlencode({
            # 서비스 계정 설정
            # 매뉴얼 대로 설치하면, 선언이 안 되어 있고 오류 발생함
            serviceAccount = {
                create = false
                name   = kubernetes_service_account.kubecost.metadata[0].name
            }
            
            kubecostProductConfigs = {
                productKey = {
                    enabled = false
                }
            }
            
            # # 볼륨 설정
            # persistentVolume = {
            #     enabled = true
            #     size = "32Gi"
            #     dbSize = "32Gi"
            # }
            
            # # 인그레스 설정
            # ingress = {
            #     enabled = false
            # }
        })
    ]

    depends_on = [
        aws_eks_cluster.this,
        aws_eks_node_group.default,
        kubernetes_service_account.kubecost,
        aws_iam_role_policy_attachment.kubecost
    ]
}
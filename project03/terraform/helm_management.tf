# Kubecost Helm 차트 설치
# https://github.com/kubecost/cost-analyzer-helm-chart

# 네임스페이스 생성
resource "kubernetes_namespace" "kubecost" {
    metadata {
        name = "kubecost"
    }
}

resource "helm_release" "kubecost" {
    name       = "kubecost"
    repository = "https://kubecost.github.io/cost-analyzer/"
    chart      = "cost-analyzer"
    namespace  = kubernetes_namespace.kubecost.metadata[0].name

    # Version compatibility: 2.3(k8s 1.21-1.30) | 2.4(k8s 1.22-1.31) | 2.5+(k8s 1.22-1.32+)
    # Current k8s version: 1.30+ → 2.8.0 compatible
    version    = "2.8.0"

    upgrade_install = true

    # 무료 버전 사용
    values = [
        yamlencode({
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
        aws_eks_node_group.default
    ]
}
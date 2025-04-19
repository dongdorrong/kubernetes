# 네임스페이스 생성
resource "kubernetes_namespace" "monitoring" {
    metadata {
        name = "monitoring"
    }
}

# Prometheus Helm 차트 설치
resource "helm_release" "prometheus" {
    name       = "prometheus"
    repository = "https://prometheus-community.github.io/helm-charts"
    chart      = "prometheus"
    namespace  = kubernetes_namespace.monitoring.metadata[0].name

    values = [<<-EOT
        server:
            persistentVolume:
                enabled: false
                size: 10Gi
            retention: "3d"

        alertmanager:
            enabled: false

        # Gateway API를 사용할 예정이므로 server.ingress.enabled = false 설정
        extraManifests: []
    EOT
    ]

    depends_on = [ kubernetes_namespace.monitoring ]
}

# Grafana Helm 차트 설치
resource "helm_release" "grafana" {
    name       = "grafana"
    repository = "https://grafana.github.io/helm-charts"
    chart      = "grafana"
    namespace  = kubernetes_namespace.monitoring.metadata[0].name

    values = [<<-EOT
        # Gateway API를 사용할 예정이므로 ingress.enabled = false로 설정
        extraObjects: []
    EOT
    ]

    depends_on = [ 
        kubernetes_namespace.monitoring,
        helm_release.prometheus 
    ]
}

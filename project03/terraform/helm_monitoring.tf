# # 네임스페이스 생성
# resource "kubernetes_namespace" "monitoring" {
#     metadata {
#         name = "monitoring"
#     }
# }

# # Prometheus Helm 차트 설치
# resource "helm_release" "prometheus" {
#     name       = "prometheus"
#     repository = "https://prometheus-community.github.io/helm-charts"
#     chart      = "prometheus"
#     namespace  = kubernetes_namespace.monitoring.metadata[0].name

#     values = [
#         yamlencode({
#             # Gateway API를 사용할 예정이므로 server.ingress.enabled = false 설정

#             server = {
#                 persistentVolume = {
#                     enabled = false
#                     size    = "10Gi"
#                 }
#                 retention   = "3d"

#                 # Grafana Alloy에서 사용할 예정이므로 web.enable-remote-write-receiver 추가
#                 extraFlags  = ["web.enable-remote-write-receiver"]
#             }
            
#             alertmanager = {
#                 enabled = false
#             }

#             extraManifests = []
#         })
#     ]

#     depends_on = [ kubernetes_namespace.monitoring ]
# }

# # Grafana Helm 차트 설치
# resource "helm_release" "grafana" {
#     name       = "grafana"
#     repository = "https://grafana.github.io/helm-charts"
#     chart      = "grafana"
#     namespace  = kubernetes_namespace.monitoring.metadata[0].name

#     values = [
#         yamlencode({
#             # Gateway API를 사용할 예정이므로 ingress.enabled = false로 설정

#             persistence = {
#                 type        = "pvc"
#                 enabled     = false
#                 accessModes = ["ReadWriteOnce"]
#                 size        = "10Gi"
#             }

#             datasources = {
#                 "datasources.yaml" = {
#                     apiVersion = 1
#                     datasources = [
#                         {
#                             name      = "Prometheus"
#                             type      = "prometheus"
#                             url       = "http://prometheus-server"
#                             access    = "proxy"
#                             isDefault = true
#                         },
#                         {
#                             name      = "Loki"
#                             type      = "loki"
#                             access    = "proxy"
#                             url       = "http://loki:3100"
#                             editable  = false
#                         }
#                     ]
#                 }
#             }
            
#             extraObjects = []
#         })
#     ]

#     depends_on = [ 
#         kubernetes_namespace.monitoring,
#         helm_release.prometheus 
#     ]
# }

# # Loki monolithic Helm 차트 설치 (Single Replica)
# resource "helm_release" "loki" {
#     name       = "loki"
#     repository = "https://grafana.github.io/helm-charts"
#     chart      = "loki"
#     namespace  = kubernetes_namespace.monitoring.metadata[0].name

#     values = [
#         yamlencode({
#             loki = {
#                 # 신규 데이터소스 추가할 때 오류 발생하여 추가
#                 auth_enabled = false

#                 commonConfig = {
#                     replication_factor = 1
#                 }
#                 schemaConfig = {
#                     configs = [
#                         {
#                             from         = "2024-04-01"
#                             store        = "tsdb"
#                             object_store = "s3"
#                             schema       = "v13"
#                             index = {
#                                 prefix = "loki_index_"
#                                 period = "24h"
#                             }
#                         }
#                     ]
#                 }
#                 pattern_ingester = {
#                     enabled = true
#                 }
#                 limits_config = {
#                     allow_structured_metadata = true
#                     volume_enabled = true
#                 }
#                 ruler = {
#                     enable_api = true
#                 }
#             }

#             minio = {
#                 enabled = true
#             }

#             deploymentMode = "SingleBinary"

#             singleBinary = {
#                 replicas = 1
#             }

#             backend = {
#                 replicas = 0
#             }
#             read = {
#                 replicas = 0
#             }
#             write = {
#                 replicas = 0
#             }

#             ingester = {
#                 replicas = 0
#             }
#             querier = {
#                 replicas = 0
#             }
#             queryFrontend = {
#                 replicas = 0
#             }
#             queryScheduler = {
#                 replicas = 0
#             }
#             distributor = {
#                 replicas = 0
#             }
#             compactor = {
#                 replicas = 0
#             }
#             indexGateway = {
#                 replicas = 0
#             }
#             bloomCompactor = {
#                 replicas = 0
#             }
#             bloomGateway = {
#                 replicas = 0
#             }
#         })
#     ]

#     depends_on = [
#         kubernetes_namespace.monitoring
#     ]
# }

# # Grafana Alloy Helm 차트 설치
# resource "helm_release" "alloy" {
#     name       = "alloy"
#     repository = "https://grafana.github.io/helm-charts"
#     chart      = "alloy"
#     namespace  = kubernetes_namespace.monitoring.metadata[0].name

#     values = [
#         yamlencode({
#             alloy = {
#                 # Gateway API를 사용할 예정이므로 ingress.enabled = false로 설정

#                 # 커스텀 설정 시, configmap 블럭 주석 해제 필요
#                 configMap = {
#                     content = file("${path.module}/manifests/alloy-configmap.hcl")
#                 }

#                 # 클러스터링 기능 비활성화
#                 clustering = {
#                     enabled = false
#                 }

#                 # # 로그 수집 기능 활성화
#                 # mounts = {
#                 #     varlog           = true
#                 #     dockercontainers = true
#                 # }
#             }

#             extraObjects = []
#         })
#     ]

#     depends_on = [ 
#         kubernetes_namespace.monitoring,
#         helm_release.prometheus 
#     ]
# }
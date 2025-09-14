# # # Kubecost Helm 차트 설치
# # https://github.com/bitnami/charts/tree/main/bitnami/keycloak

# # 네임스페이스 생성
# resource "kubernetes_namespace" "keycloak" {
#     metadata {
#         name = "keycloak"
#     }
# }

# resource "helm_release" "keycloak" {
#     name            = "keycloak"
#     repository      = "oci://registry-1.docker.io/bitnamicharts/keycloak"
#     chart           = "keycloak"
#     namespace       = kubernetes_namespace.keycloak.metadata[0].name
#     upgrade_install = true

#     values = [
#         yamlencode({
#             extraEnvVars = [{
#                 name = "KEYCLOAK_EXTRA_ARGS_PREPENDED"
#                 value = "--spi-login-protocol-openid-connect-legacy-logout-redirect-uri=true"
#             }]

#             resourcesPreset = "large"

#             networkPolicy = {
#                 enabled = false
#             }

#             metrics = {
#                 enabled = true
#                 service = {
#                     ports = {
#                         http = 8080
#                     }
#                     annotations = {
#                         "prometheus.io/scrape" = "true"
#                         "prometheus.io/port" = "{{ .Values.metrics.service.ports.http }}"
#                     }
#                     extraPorts = []
#                 }
#                 serviceMonitor = {
#                     enabled = true
#                     port = "http"
#                     endpoints = [
#                         {
#                             path = "{{ include \"keycloak.httpPath\" . }}metrics"
#                         },
#                         {
#                             path = "{{ include \"keycloak.httpPath\" . }}realms/master/metrics"
#                         }
#                     ]
#                     path = ""
#                     namespace = ""
#                     interval = "30s"
#                     scrapeTimeout = ""
#                     labels = {
#                         release = "prometheus-stack"
#                     }
#                     selector = {}
#                     relabelings = []
#                     metricRelabelings = []
#                     honorLabels = false
#                     jobLabel = ""
#                 }
#                 prometheusRule = {
#                     enabled = true
#                     namespace = ""
#                     labels = {
#                         release = "prometheus-stack"
#                     }
#                     groups = [{
#                         name = "Keycloak"
#                         rules = [{
#                             alert = "KeycloakInstanceNotAvailable"
#                             annotations = {
#                                 message = "Keycloak instance in namespace {{ `{{` }} $labels.namespace {{ `}}` }} has not been available for the last 5 minutes."
#                             }
#                             expr = "absent(kube_pod_status_ready{namespace=\"{{ include \"common.names.namespace\" . }}\", condition=\"true\"} * on (pod) kube_pod_labels{pod=~\"{{ include \"common.names.fullname\" . }}-\\\\d+\", namespace=\"{{ include \"common.names.namespace\" . }}\"}) != 0"
#                             for = "5m"
#                             labels = {
#                                 severity = "critical"
#                             }
#                         }]
#                     }]
#                 }
#             }

#             postgresql = {
#                 enabled = true
#                 auth = {
#                     postgresPassword = ""
#                     username = "bn_keycloak"
#                     password = ""
#                     database = "bitnami_keycloak"
#                     existingSecret = ""
#                 }
#                 architecture = "standalone"
#                 primary = {
#                     resourcesPreset = "medium"
#                     persistence = {
#                         storageClass = "gp3"
#                         accessModes = [
#                             "ReadWriteOnce"
#                         ]
#                         size = "20Gi"
#                     }
#                 }
#                 readReplicas = {
#                     resourcesPreset = "medium"
#                     persistence = {
#                         storageClass = "gp3"
#                         accessModes = [
#                             "ReadWriteOnce"
#                         ]
#                         size = "20Gi"
#                     }
#                 }
#             }

#             # 추가 배포 설정
#             extraDeploy = [{
#                 apiVersion = "networking.istio.io/v1beta1"
#                 kind = "VirtualService"
#                 metadata = {
#                     name = "keycloak-virtualservice"
#                     namespace = "keycloak"
#                 }
#                 spec = {
#                     hosts = [
#                         "keycloak.dongdorrong.com"
#                     ]
#                     http = [{
#                         match = [{
#                             uri = {
#                                 prefix = "/"
#                             }
#                         }]
#                         route = [{
#                             destination = {
#                                 host = "keycloak"
#                                 port = {
#                                     number = 8080
#                                 }
#                             }
#                         }]
#                     }]
#                 }
#             }]
#         })
#     ]

#     depends_on = [
#         aws_eks_cluster.this,
#         aws_eks_node_group.default
#     ]
# }
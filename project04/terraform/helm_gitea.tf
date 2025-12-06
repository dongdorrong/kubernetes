# # 네임스페이스 생성
# resource "kubernetes_namespace" "gitea" {
#     metadata {
#         name = "gitea"
#     }
# }

# # Gitea Helm 차트 설치
# resource "helm_release" "gitea" {
#     name             = "gitea"
#     repository       = "https://dl.gitea.com/charts/"
#     chart            = "gitea"
#     namespace        = kubernetes_namespace.gitea.metadata[0].name
#     upgrade_install  = true

#     values = [
#         yamlencode({
#             # Gateway API를 사용할 예정이므로 server.ingress.enabled = false 설정

#             resource = {
#                 # requests = {
#                 #     cpu = "100m"
#                 #     memory = "128Mi"
#                 # }
#                 # limits = {
#                 #     cpu = "100m"
#                 #     memory = "128Mi"
#                 # }
#             }

#             # persistence = {
#             #     enabled      = true
#             #     create       = true
#             #     mount        = true
#             #     claimName    = "gitea-shared-storage"
#             #     size         = "10Gi"
#             #     ccessModes   = ["ReadWriteOnce"]
#             #     storageClass = ""
#             # }

#             gitea = {
#                 admin = {
#                     existingSecret = ""
#                     username       = "gitea_admin"
#                     password       = "r8sA8CPHD9!bt6d"
#                     email          = "gitea@local.domain"
#                     passwordMode   = "keepUpdated"
#                 }
#                 metrics = {
#                     enabled = false
#                     token = ""
#                     serviceMonitor = {
#                         enabled =  false
#                         # additionalLabels = {
#                         #     prometheus-release = "prom1"
#                         # }
#                         interval = ""
#                         relabelings = []
#                         scheme = ""
#                         scrapeTimeout = ""
#                         tlsConfig = {}
#                     }
#                 }
#             }

#             extraDeploy = []
#         })
#     ]

#     depends_on = [ 
#         kubernetes_namespace.gitea 
#     ]
# }

# # Gitea Actions Helm 차트 설치
# resource "helm_release" "gitea_actions" {
#     name             = "gitea_actions"
#     repository       = "https://dl.gitea.com/charts/"
#     chart            = "actions "
#     namespace        = kubernetes_namespace.gitea.metadata[0].name
#     upgrade_install  = true

#     values = [
#         yamlencode({
#             enabled = false

#             statefulset = {
#                 replicas =  1
#                 timezone = "Etc/UTC"
#                 annotations = {}
#                 labels = {}
#                 resources = {}
#                 nodeSelector = {}
#                 tolerations = []
#                 affinity = {}
#                 extraVolumes = []
#                 securityContext = {}

#                 actRunner = {
#                     extraVolumeMounts = []
#                     extraEnvs = []
#                     # extraEnvs = [
#                     #     {
#                     #         name = "GITEA_RUNNER_NAME"
#                     #         valueFrom = {
#                     #             fieldRef = {
#                     #                 fieldPath = "metadata.name"
#                     #             }
#                     #         }
#                     #     }
#                     # ]

#                     config = <<-EOT
#                         log:
#                         level: debug
#                         cache:
#                         enabled: false
#                         container:
#                         require_docker: true
#                         docker_timeout: 300s
#                     EOT
#                 }


#                 dind = {
#                     registry = ""
#                     repository = "docker"
#                     tag = "28.3.3-dind"
#                     digest = ""
#                     pullPolicy = "IfNotPresent"
#                     fullOverride = ""
#                     extraVolumeMounts: []
#                     extraEnvs = [
#                         # {
#                         #     name  = "DOCKER_IPTABLES_LEGACY"
#                         #     value = "1"
#                         # }
#                     ]
#                 }

#                 persistence = {
#                     size = "1Gi"
#                 }
#             }
#         })
#     ]

#     depends_on = [ 
#         kubernetes_namespace.gitea 
#     ]
# }
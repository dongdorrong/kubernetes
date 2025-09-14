# # Kubecost Helm 차트 설치
# # https://github.com/kubecost/cost-analyzer-helm-chart

# # 네임스페이스 생성
# resource "kubernetes_namespace" "kubecost" {
#     metadata {
#         name = "kubecost"
#     }
# }

# # Kubecost 서비스 계정 생성
# resource "kubernetes_service_account" "kubecost" {
#     metadata {
#         name      = "kubecost-cost-analyzer"
#         namespace = kubernetes_namespace.kubecost.metadata[0].name
#         annotations = {
#             "eks.amazonaws.com/role-arn" = aws_iam_role.kubecost.arn
#         }
#     }
# }

# resource "helm_release" "kubecost" {
#     name            = "kubecost"
#     repository      = "https://kubecost.github.io/cost-analyzer/"
#     chart           = "cost-analyzer"
#     namespace       = kubernetes_namespace.kubecost.metadata[0].name
#     upgrade_install = true

#     # Version compatibility: 2.3(k8s 1.21-1.30) | 2.4(k8s 1.22-1.31) | 2.5+(k8s 1.22-1.32+)
#     # Current k8s version: 1.30+ → 2.8.0 compatible
#     version    = "2.8.0"

#     # 무료 버전 사용
#     values = [
#         yamlencode({
#             # 서비스 계정 설정
#             # 매뉴얼 대로 설치하면, 선언이 안 되어 있고 오류 발생함
#             serviceAccount = {
#                 create = false
#                 name   = kubernetes_service_account.kubecost.metadata[0].name
#             }
            
#             kubecostProductConfigs = {
#                 productKey = {
#                     enabled = false
#                 }
#             }
            
#             # # 볼륨 설정
#             # persistentVolume = {
#             #     enabled = true
#             #     size = "32Gi"
#             #     dbSize = "32Gi"
#             # }
            
#             # # 인그레스 설정
#             # ingress = {
#             #     enabled = false
#             # }
#         })
#     ]

#     depends_on = [
#         aws_eks_cluster.this,
#         aws_eks_node_group.default,
#         kubernetes_service_account.kubecost,
#         aws_iam_role_policy_attachment.kubecost
#     ]
# }

# # External-dns Helm 차트 설치
# # https://kubernetes-sigs.github.io/external-dns/v0.15.0/docs/tutorials/aws/

# # 네임스페이스 생성
# resource "kubernetes_namespace" "external_dns" {
#     metadata {
#         name = "external-dns"
#     }
# }

# resource "helm_release" "external_dns" {
#     name            = "external-dns"
#     repository      = "https://kubernetes-sigs.github.io/external-dns/"
#     chart           = "external-dns"
#     namespace       = kubernetes_namespace.external_dns.metadata[0].name
#     upgrade_install = true

#     values = [
#         yamlencode({
#             # 서비스 계정 설정
#             serviceAccount = {
#                 create = false
#                 name   = kubernetes_service_account.external_dns.metadata[0].name
#             }
            
#             # AWS 프로바이더 설정 (새로운 방식)
#             provider = {
#                 name = "aws"
#             }
            
#             # AWS 리전 설정
#             aws = {
#                 region = "ap-northeast-2"
#             }
            
#             # 도메인 필터 설정 (특정 도메인만 관리)
#             domainFilters = ["dongdorrong.com"]
            
#             # 정책 설정
#             policy = "sync"  # 레코드 생성/업데이트/삭제 모두 허용
#         })
#     ]

#     depends_on = [
#         aws_eks_cluster.this,
#         aws_eks_node_group.default,
#         kubernetes_service_account.external_dns,
#         aws_iam_role_policy_attachment.external_dns
#     ]
# }

# # # Velero Helm 차트 설치
# # https://github.com/vmware-tanzu/helm-charts

# # 네임스페이스 생성
# resource "kubernetes_namespace" "velero" {
#     metadata {
#         name = "velero"
#     }
# }

# resource "helm_release" "velero" {
#     name            = "velero"
#     repository      = "https://vmware-tanzu.github.io/helm-charts"
#     chart           = "velero"
#     namespace       = kubernetes_namespace.velero.metadata[0].name
#     upgrade_install = true

#     values = [
#         yamlencode({

#             initContainers = [{
#                 name = "velero-plugin-for-aws"
#                 image = "velero/velero-plugin-for-aws:v1.9.0"
#                 imagePullPolicy = "IfNotPresent"
#                 volumeMounts = [
#                     {
#                         mountPath = "/target"
#                         name = "plugins"
#                     }
#                 ]
#             }]

#             metrics = {
#                 enabled = true

#                 serviceMonitor = {
#                     autodetect = true
#                     enabled = true
#                     annotations = {}
#                     additionalLabels = {
#                         release = "prometheus-stack"
#                     }
#                 }

#                 prometheusRule = {
#                     autodetect = true
#                     enabled = true
#                     additionalLabels = {
#                         release = "prometheus-stack"
#                     }
#                     namespace = "monitoring"
#                     spec = [
#                         {
#                             alert = "VeleroBackupPartialFailures"
#                             annotations = {
#                                 message = "Velero backup {{ $labels.schedule }} has {{ $value | humanizePercentage }} partialy failed backups."
#                             }
#                             expr = "velero_backup_partial_failure_total{schedule!=\"\"} / velero_backup_attempt_total{schedule!=\"\"} > 0.25"
#                             for = "15m"
#                             labels = {
#                                 severity = "warning"
#                             }
#                         },
#                         {
#                             alert = "VeleroBackupFailures"
#                             annotations = {
#                                 message = "Velero backup {{ $labels.schedule }} has {{ $value | humanizePercentage }} failed backups."
#                             }
#                             expr = "velero_backup_failure_total{schedule!=\"\"} / velero_backup_attempt_total{schedule!=\"\"} > 0.25"
#                             for = "15m"
#                             labels = {
#                                 severity = "warning"
#                             }
#                         }
#                     ]
#                 }
#             }

#             configuration = {
#                 backupStorageLocation = [
#                     {
#                         name = "aws"
#                         provider = "aws"
#                         bucket = "velero-bucket-b2cd0419-0329-4a3d-a7a6-a458610c33c5"
#                         config = {
#                             region = "us-east-1"
#                             s3ForcePathStyle = true
#                             s3Url = "http://rook-ceph-rgw-ceph-objectstore.rook-ceph.svc.cluster.local"
#                             publicUrl = "http://rook-ceph-rgw-ceph-objectstore.rook-ceph.svc.cluster.local"
#                             insecureSkipTLSVerify = true
#                         }
#                     }
#                 ]

#                 defaultBackupStorageLocation = "aws"
#             }

#             credentials = {
#                 useSecret = true
#                 secretContents = {
#                     cloud = <<EOF
#                     [default]
#                     aws_access_key_id=RIksnqalq5to2oFZMR0Q
#                     aws_secret_access_key=RIksnqalq5to2oFZMR0Q
#                     EOF
#                 }
#             }

#             snapshotsEnabled = false
#         })
#     ]
# }

# # kubent 
# # https://github.com/doitintl/kube-no-trouble
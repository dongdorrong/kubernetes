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
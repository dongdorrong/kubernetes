# # Reference : Setting up Istio Ingress With Kubernetes Gateway API
# # - https://devopscube.com/istio-ingress-kubernetes-gateway-api/

# # 네임스페이스 생성
# resource "kubernetes_namespace_v1" "istio_system" {
#   metadata {
#     name = "istio-system"
#   }
# }

# # istio-base 설치
# resource "helm_release" "istio_base" {
#   name            = "istio-base"
#   repository      = "https://istio-release.storage.googleapis.com/charts"
#   chart           = "base"
#   namespace       = kubernetes_namespace_v1.istio_system.metadata[0].name
#   upgrade_install = true

#   values = [
#     yamlencode({
#       defaultRevision = "default"
#     })
#   ]

#   depends_on = [
#     helm_release.aws_load_balancer_controller
#   ]
# }

# # Gateway API CRD 설치
# # [중요] Releases 버전 확인 !!
# # - https://github.com/kubernetes-sigs/gateway-api/releases
# data "http" "gateway_api_crds" {
#   url = "https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.4.1/standard-install.yaml"
# }

# data "kubectl_file_documents" "gateway_api_docs" {
#   content = data.http.gateway_api_crds.response_body
# }

# resource "kubectl_manifest" "gateway_api_crds" {
#   for_each  = data.kubectl_file_documents.gateway_api_docs.manifests
#   yaml_body = each.value

#   depends_on = [
#     helm_release.aws_load_balancer_controller,
#     helm_release.istio_base
#   ]
# }

# # istiod 설치
# resource "helm_release" "istiod" {
#   name            = "istiod"
#   repository      = "https://istio-release.storage.googleapis.com/charts"
#   chart           = "istiod"
#   namespace       = kubernetes_namespace_v1.istio_system.metadata[0].name
#   upgrade_install = true

#   depends_on = [
#     helm_release.aws_load_balancer_controller,
#     helm_release.istio_base,
#     kubectl_manifest.gateway_api_crds
#   ]
# }

# # Gateway-API 배포
# # - https://medium.com/diby-uxresearchops/aws-eks-%ED%99%98%EA%B2%BD%EC%97%90%EC%84%9C-istio%EB%A5%BC-%ED%86%B5%ED%95%9C-gateway-api-%EB%8F%84%EC%9E%85-%EC%82%AC%EB%A1%80-048eef9ce0f2
# resource "kubectl_manifest" "gateway" {
#   yaml_body = templatefile("${path.module}/manifests/gateway-api.yaml", {
#     ACM_CERT_ARN = data.aws_acm_certificate.cert.arn
#   })
#   depends_on = [
#     # 2025-05-13 인증서 생성 완료하여 주석 처리
#     # data.aws_acm_certificate_validation.cert,
#     kubectl_manifest.gateway_api_crds
#   ]
# }


# # 샘플 애플리케이션 네임스페이스
# # - gateway 접근을 위한 레이블 지정 필요!
# resource "kubernetes_namespace_v1" "demo" {
#   metadata {
#     name = "demo"
#     labels = {
#       shared-gateway-access = "true"
#     }
#   }
# }

# # 샘플 애플리케이션 차트 배포
# resource "helm_release" "app" {
#   name             = "demo"
#   chart            = "${path.module}/charts/istio-sidecar-with-gatewayapi"
#   namespace        = kubernetes_namespace_v1.demo.metadata[0].name
#   upgrade_install  = true

#   values = [
#     file("${path.module}/charts/istio-sidecar-with-gatewayapi/values-shared-gateway.yaml")
#   ]

#   depends_on = [
#     helm_release.istiod,
#     kubectl_manifest.gateway_api_crds,
#     kubectl_manifest.gateway,
#     kubernetes_namespace_v1.demo
#   ]
# }

# # 샘플 애플리케이션 도메인 연결
# data "aws_route53_zone" "dongdorrong_com" {
#   name         = "dongdorrong.com"
#   private_zone = false
# }

# data "external" "gateway_lb_dns" {
#   program = ["bash", "-lc", <<EOF
# set -euo pipefail

# dns=""

# # 첫 apply(클러스터/이스티오 설치 전)에는 istio-system이 없을 수 있어서,
# # 실패(exit=1)로 terraform 전체가 멈추지 않게 빈 문자열을 반환합니다.
# if kubectl get ns istio-system --request-timeout=5s >/dev/null 2>&1; then
#   dns="$(kubectl -n istio-system get gateway gateway --request-timeout=5s -o jsonpath='{.status.addresses[0].value}{"\n"}' | tr -d '\n' || true)"
# fi

# jq -n --arg value "$dns" '{value:$value}'
# EOF
#   ]
# }

# locals {
#   gateway_lb_dns = trimspace(try(data.external.gateway_lb_dns.result.value, ""))
# }

# resource "aws_route53_record" "app" {
#     count   = local.gateway_lb_dns != "" ? 1 : 0
#     zone_id = data.aws_route53_zone.dongdorrong_com.zone_id
#     name    = "app.dongdorrong.com"
#     type    = "CNAME"
#     ttl     = 60
#     records = [local.gateway_lb_dns]
#     depends_on = [ 
#         helm_release.app
#     ]
# }

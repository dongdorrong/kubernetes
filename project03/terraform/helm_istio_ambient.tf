# Istio Helm 차트 설치 (Ambient 모드)
# https://istio.io/latest/docs/ambient/install/helm/

# 네임스페이스 생성
resource "kubernetes_namespace" "istio_system" {
    metadata {
        name = "istio-system"
    }
}

# istio-base 설치
resource "helm_release" "istio_base" {
    name            = "istio-base"
    repository      = "https://istio-release.storage.googleapis.com/charts"
    chart           = "base"
    namespace       = kubernetes_namespace.istio_system.metadata[0].name
    upgrade_install = true

    values = [
        yamlencode({
            defaultRevision = "default"
        })
    ]

    depends_on = [
        helm_release.aws_load_balancer_controller
    ]
}

# Gateway API CRD 설치
data "http" "gateway_api_crds" {
    url = "https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.2.1/standard-install.yaml"
}

data "kubectl_file_documents" "gateway_api_docs" {
    content = data.http.gateway_api_crds.response_body
}

resource "kubectl_manifest" "gateway_api_crds" {
    for_each  = data.kubectl_file_documents.gateway_api_docs.manifests
    yaml_body = each.value

    depends_on = [
        helm_release.aws_load_balancer_controller,
        helm_release.istio_base
    ]
}

# istiod 설치
resource "helm_release" "istiod" {
    name            = "istiod"
    repository      = "https://istio-release.storage.googleapis.com/charts"
    chart           = "istiod"
    namespace       = kubernetes_namespace.istio_system.metadata[0].name
    upgrade_install = true

    values = [
        yamlencode({
            profile = "ambient"
        })
    ]

    depends_on = [ 
        helm_release.aws_load_balancer_controller, 
        helm_release.istio_base,
        kubectl_manifest.gateway_api_crds 
    ]
}

# istio-cni 설치
resource "helm_release" "istio_cni" {
    name            = "istio-cni"
    repository      = "https://istio-release.storage.googleapis.com/charts"
    chart           = "cni"
    namespace       = kubernetes_namespace.istio_system.metadata[0].name
    upgrade_install = true

    values = [
        yamlencode({
            profile = "ambient"
        })
    ]

    depends_on = [ 
        helm_release.aws_load_balancer_controller, 
        helm_release.istio_base, 
        kubectl_manifest.gateway_api_crds, 
        helm_release.istiod 
    ]
}

# ztunnel 설치
resource "helm_release" "ztunnel" {
    name            = "ztunnel"
    repository      = "https://istio-release.storage.googleapis.com/charts"
    chart           = "ztunnel"
    namespace       = kubernetes_namespace.istio_system.metadata[0].name
    upgrade_install = true

    depends_on = [
        helm_release.aws_load_balancer_controller,
        helm_release.istio_base,
        kubectl_manifest.gateway_api_crds, 
        helm_release.istiod,
        helm_release.istio_cni
    ]
}

# Gateway-API 배포
# - https://medium.com/diby-uxresearchops/aws-eks-%ED%99%98%EA%B2%BD%EC%97%90%EC%84%9C-istio%EB%A5%BC-%ED%86%B5%ED%95%9C-gateway-api-%EB%8F%84%EC%9E%85-%EC%82%AC%EB%A1%80-048eef9ce0f2
resource "kubectl_manifest" "gateway" {
    yaml_body = templatefile("${path.module}/manifests/gateway-api.yaml", {
        ACM_CERT_ARN = data.aws_acm_certificate.cert.arn
    })
    depends_on = [
        # 2025-05-13 인증서 생성 완료하여 주석 처리
        # data.aws_acm_certificate_validation.cert,
        kubectl_manifest.gateway_api_crds
    ]
}
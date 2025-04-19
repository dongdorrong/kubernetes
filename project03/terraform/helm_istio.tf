# Istio Helm 차트 설치
# https://istio.io/latest/docs/ambient/install/helm/

# istio-base 설치
resource "helm_release" "istio_base" {
    namespace        = "istio-system"
    create_namespace = true

    name       = "istio-base"
    repository = "https://istio-release.storage.googleapis.com/charts"
    chart      = "base"

    upgrade_install = true

    set {
        name  = "defaultRevision"
        value = "default"
    }
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
        helm_release.istio_base
    ]
}

# istiod 설치
resource "helm_release" "istiod" {
    namespace        = "istio-system"
    create_namespace = true

    name       = "istiod"
    repository = "https://istio-release.storage.googleapis.com/charts"
    chart      = "istiod"

    upgrade_install = true

    set {
        name  = "profile"
        value = "ambient"
    }

    depends_on = [ helm_release.istio_base, kubectl_manifest.gateway_api_crds ]
}

# istio-cni 설치
resource "helm_release" "istio_cni" {
    namespace        = "istio-system"
    create_namespace = true

    name       = "istio-cni"
    repository = "https://istio-release.storage.googleapis.com/charts"
    chart      = "cni"

    upgrade_install = true

    set {
        name  = "profile"
        value = "ambient"
    }

    depends_on = [ helm_release.istio_base, kubectl_manifest.gateway_api_crds, helm_release.istiod ]
}

# ztunnel 설치
resource "helm_release" "ztunnel" {
    namespace        = "istio-system"
    create_namespace = true

    name       = "ztunnel"
    repository = "https://istio-release.storage.googleapis.com/charts"
    chart      = "ztunnel "

    upgrade_install = true

    depends_on = [ 
        helm_release.istio_base,
        kubectl_manifest.gateway_api_crds, 
        helm_release.istiod,
        helm_release.istio_cni
    ]
}

# 2025-04-19 인증서 생성 완료하여 주석 처리
/*
# ACM 인증서 생성
resource "aws_acm_certificate" "cert" {
  domain_name       = "dongdorrong.com"
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

# Route53 Zone 데이터 가져오기
data "aws_route53_zone" "zone" {
    name         = "dongdorrong.com"
    private_zone = false
}

# DNS 검증을 위한 Route53 레코드 생성
resource "aws_route53_record" "cert_validation" {
  for_each = {
    for dvo in aws_acm_certificate.cert.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = data.aws_route53_zone.zone.zone_id
}

# 검증 완료 대기
resource "aws_acm_certificate_validation" "cert" {
  certificate_arn         = aws_acm_certificate.cert.arn
  validation_record_fqdns = [for record in aws_route53_record.cert_validation : record.fqdn]
}
*/

data "aws_acm_certificate" "cert" {
    domain   = "dongdorrong.com"
    statuses = ["ISSUED"]
}

# Gateway 배포
# - https://medium.com/diby-uxresearchops/aws-eks-%ED%99%98%EA%B2%BD%EC%97%90%EC%84%9C-istio%EB%A5%BC-%ED%86%B5%ED%95%9C-gateway-api-%EB%8F%84%EC%9E%85-%EC%82%AC%EB%A1%80-048eef9ce0f2
resource "kubectl_manifest" "gateway" {
    yaml_body = templatefile("${path.module}/manifests/gateway-api.yaml", {
        ACM_CERT_ARN = data.aws_acm_certificate.cert.arn
    })
    depends_on = [
        data.aws_acm_certificate_validation.cert,
        helm_release.aws_load_balancer_controller
    ]
}


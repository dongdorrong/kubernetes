# Istio Helm 차트 설치 (Sidecar 모드)
# https://istio.io/latest/docs/setup/install/helm/

# istio-base 설치
resource "helm_release" "istio_base" {
    namespace        = "istio-system"
    create_namespace = true

    name       = "istio-base"
    repository = "https://istio-release.storage.googleapis.com/charts"
    chart      = "base"

    upgrade_install = true

    values = [
        yamlencode({
            defaultRevision = "default"
        })
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

    depends_on = [ helm_release.istio_base ]
}

# istio ingressgateway 설치
resource "helm_release" "istio_ingress" {
    namespace        = "istio-ingress"
    create_namespace = true

    name       = "istio-ingress"
    repository = "https://istio-release.storage.googleapis.com/charts"
    chart      = "gateway"

    upgrade_install = true

    values = [
        yamlencode({
            _internal_defaults_do_not_set = {
                service = {
                    type = "NodePort"
                }
            }
            extraManifests = []
        })
    ]

    depends_on = [ helm_release.istio_base, helm_release.istiod ]
}

# istio 'Gateway' CR 배포
resource "kubectl_manifest" "istio_gateway" {
    yaml_body = file("${path.module}/manifests/istio-gateway.yaml")

    depends_on = [ helm_release.istio_base, helm_release.istiod, helm_release.istio_ingress ]
}

# istio ingressgateway Service의 NodePort 조회를 위한 data 리소스 선언
data "kubernetes_service" "istio_ingressgateway" {
    metadata {
        name      = "istio-ingress"
        namespace = "istio-ingress"
    }

    depends_on = [ helm_release.istio_base, helm_release.istiod, helm_release.istio_ingress, kubectl_manifest.istio_gateway ]
}

# Services Ingress 배포 (ALB)
resource "kubectl_manifest" "ingress_for_services" {
    yaml_body = templatefile("${path.module}/manifests/ingress-for-serivces.yaml", {
        ALB_NAME_SVC                   = "${local.cluster_name}-svc-ingress"
        PUBLIC_SUBNET_IDS              = join(",", aws_subnet.public[*].id)
        ACM_CERT_ARN                   = data.aws_acm_certificate.cert.arn
        ISTIO_INGRESS_HEALTHCHECK_PORT = tostring([
            for p in data.kubernetes_service.istio_ingressgateway.spec[0].port :
              p.node_port if p.port == 15021
        ][0])

        WAF_ACL_ARN                    = ""
    })

    depends_on = [ helm_release.istio_base, helm_release.istiod, helm_release.istio_ingress, kubectl_manifest.istio_gateway,  ]
}

# Addons Ingress 배포 (ALB)
resource "kubectl_manifest" "ingress_for_addons" {
    yaml_body = templatefile("${path.module}/manifests/ingress-for-addons.yaml", {
        ALB_NAME_ADDON                 = "${local.cluster_name}-addon-ingress"
        PUBLIC_SUBNET_IDS              = join(",", aws_subnet.public[*].id)
        ACM_CERT_ARN                   = data.aws_acm_certificate.cert.arn
        ISTIO_INGRESS_HEALTHCHECK_PORT = tostring([
            for p in data.kubernetes_service.istio_ingressgateway.spec[0].port :
              p.node_port if p.port == 15021
        ][0])

        WAF_ACL_ARN                    = ""
    })

    depends_on = [ helm_release.istio_base, helm_release.istiod, helm_release.istio_ingress, kubectl_manifest.istio_gateway ]
}
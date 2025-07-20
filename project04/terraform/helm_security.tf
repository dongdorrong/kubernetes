# # Trivy-Operator Helm 차트 설치
# https://aquasecurity.github.io/trivy-operator/v0.1.5/operator/installation/helm/

# 네임스페이스 생성
resource "kubernetes_namespace" "security" {
    metadata {
        name = "security"
    }
}


resource "helm_release" "trivy_operator" {
    name            = "trivy-operator"
    repository      = "https://aquasecurity.github.io/helm-charts/"
    chart           = "trivy-operator"
    namespace       = kubernetes_namespace.security.metadata[0].name
    upgrade_install = true

    values = [
        yamlencode({
            operator = {
                metricsVulnIdEnabled = true
            }

            serviceMonitor = {
                enabled = true
                namespace = null
                interval = null
                annotations = {}
                labels = {
                    release = "prometheus-stack"
                }
                honorLabels = true
                endpointAdditionalProperties = {}
            }

            trivy = {
                ignoreUnfixed = true
            }

            nodeCollector = {
                tolerations = [
                    {
                        key = "node-role.kubernetes.io/control-plane"
                        effect = "NoSchedule"
                    },
                    {
                        effect = "NoSchedule"
                        key = "node-role.kubernetes.io/master"
                    }
                ]
            }
        })
    ]

    depends_on = [
        aws_eks_cluster.this,
        aws_eks_node_group.default
    ]
}

resource "helm_release" "falco" {
    name            = "falco"
    repository      = "https://falcosecurity.github.io/charts"
    chart           = "falco"
    namespace       = kubernetes_namespace.security.metadata[0].name
    upgrade_install = true

    values = [
        yamlencode({

            tty = true

            driver = {
                enabled = true
                kind = "ebpf"
            }

            falcosidekick = {
                enabled = true
                fullfqdn = false
                listenPort = ""

                config = {
                    # slack = {
                    #     webhookurl = "https://hooks.slack.com/services/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"
                    #     minimumpriority = "error"
                    # }
                    alertmanager = {
                        hostport = "http://alertmanager-operated.monitoring.svc.cluster.local:9093"
                        minimumpriority = "error"
                    }

                    # Ingress 대신 VirtualService 사용하는 방안 검토 필요
                    webui = {
                        enabled = true
                        user = "admin:abcdefghijklmnopqrstuvwxyz"
                        ingress = {
                            enabled = true
                            ingressClassName = "nginx"
                            annotations = {
                                "nginx.ingress.kubernetes.io/whitelist-source-range" = "aaa.bbb.ccc.ddd/32"
                            }
                        }
                        redis = {
                            storageSize = "30Gi"
                            storageClass = "gp3"
                        }
                    }
                }
            }
        })
    ]

    depends_on = [
        aws_eks_cluster.this,
        aws_eks_node_group.default
    ]
}
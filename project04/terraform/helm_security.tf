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

            # serviceMonitor = {
            #     enabled = true
            #     namespace = null
            #     interval = null
            #     annotations = {}
            #     labels = {
            #         release = "prometheus-stack"
            #     }
            #     honorLabels = true
            #     endpointAdditionalProperties = {}
            # }

            trivy = {
                ignoreUnfixed = true
            }

            # nodeCollector = {
            #     tolerations = [
            #         {
            #             key = "node-role.kubernetes.io/control-plane"
            #             effect = "NoSchedule"
            #         },
            #         {
            #             effect = "NoSchedule"
            #             key = "node-role.kubernetes.io/master"
            #         }
            #     ]
            # }
        })
    ]

    depends_on = [
        aws_eks_cluster.this
    ]
}

# # Falco Helm 차트 설치
# https://github.com/falcosecurity/charts
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
                    #     username = "Falco-OnPremise-K8S"
                    # }
                    # alertmanager = {
                    #     hostport = "http://alertmanager-operated.monitoring.svc.cluster.local:9093"
                    #     minimumpriority = "error"
                    # }

                    # Ingress 대신 VirtualService 사용하는 방안 검토 필요
                    webui = {
                        enabled = true
                        user = "admin:abcdefghijklmnopqrstuvwxyz"
                        ingress = {
                            enabled = true
                            ingressClassName = "nginx"
                            # annotations = {
                            #     "nginx.ingress.kubernetes.io/whitelist-source-range" = "aaa.bbb.ccc.ddd/32"
                            # }
                            hosts = [
                                {
                                    host = "falco.dongdorrong.com"
                                    paths = [
                                        {
                                            path = "/"
                                        }
                                    ]
                                }
                            ]
                            tls = [
                                {
                                    secretName = "falco-dongdorrong-com"
                                    hosts = [
                                        "falco.dongdorrong.com"
                                    ]
                                }
                            ]
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
        aws_eks_cluster.this
    ]
}

# # Cert-Manager Helm 차트 설치
# https://github.com/cert-manager/cert-manager
resource "kubernetes_namespace" "cert_manager" {
    metadata {
        name = "cert-manager"
    }
}

resource "helm_release" "cert_manager" {
    name            = "cert-manager"
    repository      = "https://charts.jetstack.io"
    chart           = "cert-manager"
    namespace       = kubernetes_namespace.cert_manager.metadata[0].name
    upgrade_install = true

    values = [
        yamlencode({
            global = {
                logLevel = 2
            }

            installCRDs = true
        })
    ]

    depends_on = [
        aws_eks_cluster.this
    ]
}

# # ClusterIssuer 생성
# resource "kubernetes_manifest" "cert_manager_issuer" {
#     # Staging
#     manifest = {
#         apiVersion = "cert-manager.io/v1"
#         kind = "ClusterIssuer"
#         metadata = {
#             name = "letsencrypt-staging"
#         }
#         spec = {
#             acme = {
#                 email = "admin@dongdorrong.com"
#                 server = "https://acme-staging-v02.api.letsencrypt.org/directory"
#                 privateKeySecretRef = {
#                     name = "letsencrypt-staging"
#                 }
#                 solvers = [
#                     {
#                         http01 = {
#                             ingress = {
#                                 class = "nginx"
#                             }
#                         }
#                     }
#                 ]
#             }
#         }
#     }
#     # Production
#     manifest = {
#         apiVersion = "cert-manager.io/v1"
#         kind = "ClusterIssuer"
#         metadata = {
#             name = "letsencrypt-production"
#         }
#         spec = {
#             acme = {
#                 email = "admin@dongdorrong.com"
#                 server = "https://acme-v02.api.letsencrypt.org/directory"
#                 privateKeySecretRef = {
#                     name = "letsencrypt-production"
#                 }
#                 solvers = [
#                     {
#                         http01 = {
#                             ingress = {
#                                 class = "nginx"
#                             }
#                         }
#                     }
#                 ]
#             }
#         }
#     }
#     # Self-signed
#     manifest = {
#         apiVersion = "cert-manager.io/v1"
#         kind = "ClusterIssuer"
#         metadata = {
#             name = "letsencrypt-selfsigned"
#         }
#         spec = {
#             selfSigned = {}
#         }
#     }
# }

# # octelium 
# https://github.com/octelium/octelium
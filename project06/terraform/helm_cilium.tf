# # cilium 설치
# # - https://docs.cilium.io/en/stable/installation/k8s-install-helm/
# # - https://cilium.io/blog/2025/06/19/eks-eni-install/
# # - https://cilium.io/blog/2025/07/08/byonci-overlay-install/
# resource "helm_release" "cilium" {
#     name            = "cilium"
#     repository      = "https://helm.cilium.io"
#     chart           = "cilium"
#     namespace       = "kube-system"
#     upgrade_install = true

#     values = [
#         yamlencode({
#             cni = {
#                 chainingMode = "aws-cni"
#                 exclusive = false
#             }

#             enableIPv4Masquerade = false

#             routingMode = "native"

#             k8sServiceHost = aws_eks_cluster.this.endpoint

#             k8sServicePort = 443
#         })
#     ]
# }
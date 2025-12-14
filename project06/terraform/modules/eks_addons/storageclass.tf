resource "kubernetes_manifest" "storageclass" {
  manifest = yamldecode(file("${path.module}/../../manifests/storageclass.yaml"))

  depends_on = [
    aws_eks_addon.ebs_csi
  ]
}

# Karpenter 노드 인스턴스 프로파일
resource "aws_iam_instance_profile" "karpenter" {
  name = "${local.project_name}-karpenter-node-profile"
  role = aws_iam_role.karpenter_node.name
}

# 네임스페이스 생성
resource "kubernetes_namespace_v1" "karpenter" {
  metadata {
    name = "karpenter"
  }

  depends_on = [aws_eks_cluster.this]
}

# Karpenter Helm 차트 설치
resource "helm_release" "karpenter" {
    name            = "karpenter"
    repository      = "oci://public.ecr.aws/karpenter"
    chart           = "karpenter"
    namespace       = kubernetes_namespace_v1.karpenter.metadata[0].name
    upgrade_install = true

    # version    = "1.8.0" # https://github.com/kubernetes-sigs/karpenter/releases

    values = [
      yamlencode({
        controller = {
          resources = {
            requests = {
              cpu    = "0.5"
              memory = "1Gi"
            }
            limits = {
              cpu    = "0.5"
              memory = "1Gi"
            }
          }
        }
        serviceAccount = {
          annotations = {
              "eks.amazonaws.com/role-arn" = aws_iam_role.karpenter_controller.arn
          }
        }
        settings = {
          clusterName = aws_eks_cluster.this.name
          aws = {
            defaultInstanceProfile = aws_iam_instance_profile.karpenter.name
          }
          interruptionQueueName = "${aws_eks_cluster.this.name}-karpenter"
        }
      })
    ]

    depends_on = [
      aws_eks_cluster.this,
      aws_iam_role.karpenter_node,
      aws_iam_role.karpenter_controller,
      aws_iam_instance_profile.karpenter,
      aws_eks_node_group.default,
      kubernetes_config_map_v1.aws_auth,
    ]
}

# Karpenter NodePool 설정
resource "kubectl_manifest" "karpenter_nodepool" {
  yaml_body = templatefile("${path.module}/manifests/karpenter-nodepool.yaml", {})

  depends_on = [
    helm_release.karpenter,
    kubernetes_config_map_v1.aws_auth
  ]
}

# Karpenter NodeClass 설정
resource "kubectl_manifest" "karpenter_nodeclass" {
  yaml_body = templatefile("${path.module}/manifests/karpenter-nodeclass.yaml", {
    CLUSTER_NAME  = aws_eks_cluster.this.name
    ALIAS_VERSION = "latest"
    NODE_NAME     = local.node_name_format
    KMS_KEY_ARN   = aws_kms_key.karpenter.arn
  })

  depends_on = [
    helm_release.karpenter,
    kubernetes_config_map_v1.aws_auth,
    aws_kms_key.karpenter
  ]
}

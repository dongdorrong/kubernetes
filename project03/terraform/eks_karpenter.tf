# Karpenter 노드 인스턴스 프로파일
resource "aws_iam_instance_profile" "karpenter" {
    name = "karpenter-node-profile"
    role = aws_iam_role.karpenter_node.name
}

# Karpenter Helm 차트 설치
resource "helm_release" "karpenter" {
    namespace        = "karpenter"
    create_namespace = true

    name       = "karpenter"
    repository = "oci://public.ecr.aws/karpenter"
    chart      = "karpenter"
    version    = "1.4.0"

    upgrade_install = true

    set {
        name  = "controller.resources.requests.cpu"
        value = 0.5
    }

    set {
        name  = "controller.resources.requests.memory"
        value = "1Gi"
    }

    set {
        name  = "controller.resources.limits.cpu"
        value = 0.5
    }

    set {
        name  = "controller.resources.limits.memory"
        value = "1Gi"
    }

    set {
        name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
        value = aws_iam_role.karpenter_controller.arn
    }

    set {
        name  = "settings.clusterName"
        value = aws_eks_cluster.this.name
    }

    set {
        name  = "settings.aws.defaultInstanceProfile"
        value = aws_iam_instance_profile.karpenter.name
    }

    set {
        name  = "settings.interruptionQueueName"
        value = "${aws_eks_cluster.this.name}-karpenter"
    }

    depends_on = [
        aws_eks_cluster.this,
        aws_iam_role.karpenter_controller,
        aws_iam_role.karpenter_node,
        aws_iam_instance_profile.karpenter,
        aws_iam_openid_connect_provider.this,
        aws_eks_node_group.default,
        kubernetes_config_map.aws_auth
    ]
}

# Karpenter NodePool 설정
resource "kubectl_manifest" "karpenter_nodepool" {
    yaml_body = templatefile("${path.module}/manifests/karpenter-nodepool.yaml", {})
    depends_on = [
        helm_release.karpenter,
        kubernetes_config_map.aws_auth
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
        kubernetes_config_map.aws_auth,
        aws_kms_key.karpenter
    ]
}
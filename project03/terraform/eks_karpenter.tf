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
        kubernetes_config_map_v1_data.aws_auth_karpenter_update  # Karpenter 노드 역할 추가 후 Helm 설치
    ]
}

# Karpenter 노드 역할을 aws-auth ConfigMap에 추가
resource "kubernetes_config_map_v1_data" "aws_auth_karpenter_update" {
    metadata {
        name      = "aws-auth"
        namespace = "kube-system"
    }
    
    data = {
        mapRoles = yamlencode(
            concat(
                yamldecode(data.kubernetes_config_map.aws_auth_latest.data.mapRoles),
                [
                    {
                        rolearn  = aws_iam_role.karpenter_node.arn
                        username = "system:node:{{EC2PrivateDNSName}}"
                        groups   = ["system:bootstrappers", "system:nodes"]
                    }
                ]
            )
        )
    }
    
    depends_on = [
        aws_iam_role.karpenter_node,
        data.kubernetes_config_map.aws_auth_latest
    ]
    
    force = true  # 기존 ConfigMap 덮어쓰기
}

# 기존 aws-auth ConfigMap의 역할 정보를 읽어와 Karpenter 역할 추가 시 기존 정보를 보존함
data "kubernetes_config_map" "aws_auth_latest" {
    metadata {
        name      = "aws-auth"
        namespace = "kube-system"
    }
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
    })
    depends_on = [
        helm_release.karpenter,
        kubernetes_config_map.aws_auth
    ]
}
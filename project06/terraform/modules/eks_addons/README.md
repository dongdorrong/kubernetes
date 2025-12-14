# eks_addons module

요약
-----------------------------------------------------------------
EKS 클러스터에 필요한 기본 애드온(VPC CNI, CoreDNS, kube-proxy, Metrics Server, EBS CSI)과 AWS Load Balancer Controller(Helm + IRSA)를 한 번에 배포하기 위한 모듈입니다. IRSA에 필요한 IAM 역할/정책과 ServiceAccount도 포함되어 있어 클러스터 모듈의 출력만 넘기면 바로 사용 가능합니다.

요구 입력
-----------------------------------------------------------------
* `cluster_name`: EKS 클러스터 이름
* `cluster_identity_oidc_issuer`: `aws_eks_cluster.identity[0].oidc[0].issuer` 값
* `oidc_provider_arn`: `aws_iam_openid_connect_provider` ARN
* `vpc_id`: VPC ID (ALB Controller values)
* `project_name`: 자원명/태그 prefix
* `region`: 헬름 values에서 region 지정

출력
-----------------------------------------------------------------
* `alb_controller_role_arn`: ALB Controller IRSA IAM 역할
* `alb_controller_policy_arn`: ALB Controller IAM 정책
* `ebs_csi_role_arn`
* `vpc_cni_role_arn`

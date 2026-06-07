# Project 09 - VPC + EKS 기본 인프라 (운영/테스트 공통)

`project09`는 실험 또는 운영 전 단계에서 공통적으로 재사용 가능한 **VPC + EKS 클러스터**를 빠르게 생성하기 위한 Terraform 구성이며,
현재 기준으로는 EKS Control Plane + Fargate 기본 구성까지 관리합니다.

## 디렉터리 구성

```
project09/
└── terraform/
    ├── main.tf
    ├── provider.tf
    ├── locals.tf
    ├── variables.tf
    ├── vpc.tf
    ├── eks_cluster.tf
    ├── eks_cluster_iam.tf
    ├── eks_cluster_access.tf
    ├── eks_addon.tf
    ├── eks_fargate.tf
    ├── eks_addon_irsa.tf
    ├── iam_assume_role.tf
    ├── outputs.tf
    └── manifests/ (EKS 운영 확장 시 사용되는 템플릿 모음)
```

## 사용 목적

- VPC 생성 (Public/Private subnet, NAT 포함)
  - EKS Control Plane 생성
  - Fargate Profile(`kube-system`, `dev-n-mgmt`) 생성
  - 필수 애드온 기본 등록(kube-proxy)

> 주의: 테스트용 인증서/ACM/ACK/step-ca/Knative 연동 시나리오 코드는 별도 차트/모드로 분리되어 관리하며,
> `project09`에서는 클러스터 인프라 생성과 ACK ACM 브릿지에 필요한 IRSA(Role)까지 제공합니다.

## 실행 순서

1) AWS 자격 증명 전환
```bash
cd /home/dongdorrong/github/private/kubernetes/project09
./setAssumeRoleCredential.sh
```

2) 인프라 초기화
```bash
cd /home/dongdorrong/github/private/kubernetes/project09/terraform
tofu init
```

3) 클러스터 생성
```bash
tofu apply \
  -var project_name=project09-ops01 \
  -var region=ap-northeast-2 \
  -var owner=252462902626 \
  -auto-approve
```

4) Fargate Profile 상태 확인
```bash
cd /home/dongdorrong/github/private/kubernetes/project09/terraform
aws eks list-fargate-profiles \
  --cluster-name project09-ops01 \
  --region ap-northeast-2
```

기대값: `project09-ops01-default` 존재, selectors에 `kube-system`, `dev-n-mgmt` 포함.

5) ACK IRSA Role ARN 확인
```bash
cd /home/dongdorrong/github/private/kubernetes/project09/terraform
tofu output ack_irsa_role_arn
```

예시:
`arn:aws:iam::252462902626:role/project09-ack-acm-irsa`

ACK 차트 배포 시 활용 예시:
```bash
ACK_ROLE_ARN=$(cd /home/dongdorrong/github/private/kubernetes/project09/terraform && tofu output -raw ack_irsa_role_arn)
DOMAINS='a.dongdorrong.com,b.dongdorrong.com,c.dongdorrong.com'
cd /home/dongdorrong/github/private/step-ca-certmanager-test
ACK_ROLE_ARN="${ACK_ROLE_ARN}" EKS_MGMT_NAMESPACE='dev-n-mgmt' DOMAINS="${DOMAINS}" ./scripts/generate-eks-values.sh
```

6) 클러스터 정리
```bash
tofu destroy \
  -var project_name=project09-ops01 \
  -var region=ap-northeast-2 \
  -var owner=252462902626 \
  -auto-approve
```

## 운영 권장 옵션

- 실제 운영 배포에서는 `project_name`, `owner`, `region`, CIDR, Subnet을 환경별로 분리합니다.
- `tfstate`는 기본적으로 `terraform/tfstate/terraform.tfstate`에 저장되므로, 상태 파일 분리 전략을 별도 운영 설계합니다.

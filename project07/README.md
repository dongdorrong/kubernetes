# Project 07 - EKS Capabilities PoC

EKS Capabilities(Argo CD / ACK / KRO)를 각각 분리해서 테스트하는 PoC 구성입니다.
클러스터/노드그룹은 공통으로 만들고, Capability는 모드별 폴더에서 독립적으로 적용합니다.

## 디렉터리 구성

```
project07/
└── terraform/
    ├── (공통) vpc.tf / eks_cluster.tf / eks_addon.tf / eks_addon_irsa.tf / outputs.tf
    ├── 1-argocd/
    ├── 2-ack/
    └── 3-kro/
```

## 전제 조건

- AWS CLI v2, OpenTofu, kubectl 설치
- `private` AWS 프로파일 준비
- `iam_assume_role.tf`에 선언된 `terraform-assume-role`, `eks-assume-role`이 실제로 존재해야 함
- Argo CD Capability 테스트 시 AWS Identity Center(SSO) 설정 필요

## 실행 순서

1) 클러스터 생성(공통)
```bash
cd /home/dongdorrong/github/private/kubernetes/project07/terraform
tofu init
tofu apply
```

2) 원하는 Capability 적용
```bash
cd /home/dongdorrong/github/private/kubernetes/project07/terraform/<mode>
tofu init
tofu apply
```

지원 모드:
- `1-argocd`
- `2-ack`
- `3-kro`

변수 예시:
```bash
tofu apply -var cluster_name=ekscapabilities -var profile=private -var region=ap-northeast-2
```
`cluster_name`은 공통 클러스터와 동일해야 하며, 기본값은 `terraform/locals.tf`의 `project_name`을 따릅니다.

## 모드별 요약

Argo CD (`1-argocd`)
- EKS Capabilities의 Argo CD 생성
- Git 리포지토리를 소스 오브 트루스로 삼아 GitOps 동기화
- AWS Identity Center 연동 필수
- Argo CD CRD(Application, ApplicationSet) 생성 확인

ACK (`2-ack`)
- EKS Capabilities의 ACK 생성
- Kubernetes CRD로 AWS 리소스를 선언/동기화
- 기본 예시는 `AdministratorAccess`를 연결(실무는 최소 권한 권장)
- `services.k8s.aws` 계열 CRD 생성 확인

kro (`3-kro`)
- EKS Capabilities의 KRO 생성
- 여러 리소스를 묶는 상위 API(ResourceGraphDefinition) 제공
- `AmazonEKSClusterAdminPolicy`를 연결해 리소스 생성 권한 부여
- `kro.run` CRD 생성 확인

## 검증

```bash
aws eks list-capabilities --region ap-northeast-2 --cluster-name ekscapabilities
aws eks describe-capability --region ap-northeast-2 --cluster-name ekscapabilities --capability-name <capability-name>
```

## 정리

- 모드별 상태는 각 폴더의 `tfstate/terraform.tfstate`로 분리됩니다.
- 모드 정리: 해당 모드 폴더에서 `tofu destroy`
- 클러스터 정리: 공통 폴더에서 `tofu destroy`
- Capability 삭제 시 CRD/리소스는 남으므로 필요 시 먼저 제거하세요.

## 참고(GitHub)

- Argo CD Capability(awsdocs): https://github.com/awsdocs/amazon-eks-user-guide/blob/mainline/latest/ug/capabilities/argocd-create-cli.adoc
- ACK Capability(awsdocs): https://github.com/awsdocs/amazon-eks-user-guide/blob/mainline/latest/ug/capabilities/ack-create-cli.adoc
- KRO Capability(awsdocs): https://github.com/awsdocs/amazon-eks-user-guide/blob/mainline/latest/ug/capabilities/kro-create-cli.adoc
- ACK S3 Controller 샘플: https://github.com/aws-controllers-k8s/s3-controller

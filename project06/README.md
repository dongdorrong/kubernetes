# Project 06 - Cilium PoC

EKS에서 Cilium 설치 모드(ENI / CNI Chaining / BYOCNI Overlay)를 분리 실행하는 PoC 구성입니다.
클러스터/노드그룹은 공통으로 만들고, Cilium 설치는 모드별 폴더에서 독립적으로 적용합니다.

참고 블로그:
- https://velog.io/@dongdorrong/EKS%EC%97%90%EC%84%9C-Cilium-%EC%84%A4%EC%B9%98-%EB%AA%A8%EB%93%9C-3%EA%B0%80%EC%A7%80-%EB%B9%84%EA%B5%90-ENI-vs-CNI-Chaining-vs-BYOCNIOverlay

## 디렉터리 구성

```
project06/
└── terraform/
    ├── (공통) vpc.tf / eks_cluster.tf / eks_addon.tf / eks_addon_irsa.tf / outputs.tf
    ├── 1-cilium-eni/
    ├── 2-cilium-chaining/
    └── 3-cilium-overlay/
```

## 전제 조건

- AWS CLI, OpenTofu, kubectl 설치
- `private` AWS 프로파일 준비
- `iam_assume_role.tf`에 선언된 `terraform-assume-role`, `eks-assume-role`이 실제로 존재해야 함

## 실행 순서

1) 클러스터 생성(공통)
```bash
cd /home/dongdorrong/github/private/kubernetes/project06/terraform
tofu init
tofu apply
```

2) 원하는 모드 적용
```bash
cd /home/dongdorrong/github/private/kubernetes/project06/terraform/<mode>
tofu init
tofu apply
```

지원 모드:
- `1-cilium-eni`
- `2-cilium-chaining`
- `3-cilium-overlay`

변수 예시:
```bash
tofu apply -var cluster_name=eksciliumtest -var profile=private -var region=ap-northeast-2
```

## 모드별 핵심 차이

ENI (`1-cilium-eni`)
- `vpc-cni`와 공존 불가
- `vpc-cni`/`aws-node` 및 `kube-proxy` 자동 제거 후 Cilium 설치

CNI Chaining (`2-cilium-chaining`)
- `aws-node` 유지
- `vpc-cni` 애드온/IRSA를 이 폴더에서 관리
- `../tfstate/terraform.tfstate` 출력(`oidc_provider_arn`)을 참조
- 설치 후 기존 Pod 재시작 필요

BYOCNI Overlay (`3-cilium-overlay`)
- `vpc-cni`와 공존 불가
- `vpc-cni`/`aws-node` 및 `kube-proxy` 자동 제거 후 Cilium 설치
- `cluster_pool_ipv4_cidrs`가 VPC CIDR과 겹치지 않도록 설정

## 검증

```bash
kubectl -n kube-system get pods -l k8s-app=cilium
cilium status --wait
cilium connectivity test
```

## 정리

- 모드별 상태는 각 폴더의 `tfstate/terraform.tfstate`로 분리됩니다.
- 모드 정리: 해당 모드 폴더에서 `tofu destroy`
- 클러스터 정리: 공통 폴더에서 `tofu destroy`

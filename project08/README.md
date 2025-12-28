# Project 08 - Gateway API PoC

Ingress → Gateway API 전환을 가정하고 Envoy Gateway, Cilium Gateway, Istio Gateway를 비교 테스트하는 PoC입니다.
클러스터/노드그룹은 공통으로 만들고, Gateway 테스트는 모드별 폴더에서 독립적으로 적용합니다.

참고 글:
- https://github.com/sysnet4admin/Research/blob/main/gateway-PoC/README_ko.md

## 디렉터리 구성

```
project08/
└── terraform/
    ├── (공통) vpc.tf / eks_cluster.tf / eks_addon.tf / eks_addon_irsa.tf / outputs.tf
    ├── 1-envoy-gateway/
    ├── 2-cilium-gateway/
    └── 3-istio-gateway/
```

## 전제 조건

- AWS CLI v2, OpenTofu, kubectl 설치
- `private` AWS 프로파일 준비
- `iam_assume_role.tf`에 선언된 `terraform-assume-role`, `eks-assume-role`이 실제로 존재해야 함
- Gateway API CRD 설치(각 서브폴더 README 참고)
- Envoy/Cilium은 Helm, Istio는 istioctl 설치 권장

## 실행 순서

1) 클러스터 생성(공통)
```bash
cd /home/dongdorrong/github/private/kubernetes/project08/terraform
tofu init
tofu apply
```

2) 원하는 Gateway 모드 적용
```bash
cd /home/dongdorrong/github/private/kubernetes/project08/terraform/<mode>
```

지원 모드:
- `1-envoy-gateway`
- `2-cilium-gateway`
- `3-istio-gateway`

변수 예시:
```bash
tofu apply -var cluster_name=eksgatewaypoc -var profile=private -var region=ap-northeast-2
```
`cluster_name`은 공통 클러스터와 동일해야 하며, 기본값은 `terraform/locals.tf`의 `project_name`을 따릅니다.

## 모드별 요약

Envoy Gateway (`1-envoy-gateway`)
- Envoy 프로젝트의 Gateway API 구현체
- `GatewayClass`를 명시적으로 생성해 사용

Cilium Gateway (`2-cilium-gateway`)
- Cilium의 Gateway API 구현체(Envoy 기반)
- Cilium 설치 시 `gatewayAPI.enabled` 활성화 필요

Istio Gateway (`3-istio-gateway`)
- Istio의 Gateway API 구현체
- 기본 `GatewayClass(istio)`를 Istio가 생성

## 검증

```bash
kubectl get gatewayclass
kubectl get gateway -A
kubectl get httproute -A
```

## 정리

- 모드별 리소스는 각 폴더의 `manifests/`를 기준으로 삭제
- 클러스터 정리: 공통 폴더에서 `tofu destroy`

## 참고(GitHub)

- Envoy Gateway Quickstart: https://github.com/envoyproxy/gateway/blob/main/examples/kubernetes/quickstart.yaml
- Cilium Gateway API 예시: https://github.com/cilium/cilium/tree/main/examples/kubernetes/gateway
- Istio Gateway API 문서: https://istio.io/latest/docs/tasks/traffic-management/ingress/gateway-api/

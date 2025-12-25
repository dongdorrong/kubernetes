# 2) Cilium CNI Chaining 모드

AWS VPC CNI(`aws-node`)를 **그대로 유지**하고, Cilium을 **체이닝**으로 붙여
정책/관측 기능을 점진적으로 도입하는 방식입니다.

## 이 폴더에서 하는 일

- `vpc-cni` 애드온 + IRSA를 이 폴더에서 관리
- Cilium 설치 (CNI chaining: `aws-cni`)

> 이 폴더는 `../tfstate/terraform.tfstate`의 `oidc_provider_arn` 출력을 참조합니다.
> 따라서 공통 Terraform을 먼저 `tofu apply` 해야 합니다.

## 실행

```bash
cd /home/dongdorrong/github/private/kubernetes/project06/terraform/2-cilium-chaining
tofu init
tofu apply
```

설치가 완료되면 `kube-system` 네임스페이스의 워크로드를 자동으로 재기동합니다.
필요 시 다음 변수를 사용하세요.

```bash
# 재기동 대상 네임스페이스
tofu apply -var 'restart_namespaces=["kube-system","default"]'

# 전체 파드 삭제 방식으로 강제 재기동
tofu apply -var restart_all_pods=true
```

## 장점

- 기존 `aws-node` 유지로 전환 리스크가 낮음
- Cilium 정책/관측 기능을 빠르게 실험 가능

## 단점

- Pod IP는 계속 VPC IP를 소비 (IP 고갈 문제 해결 안 됨)
- 두 CNI가 공존해 운영 복잡도가 증가
- 설치 후 기존 Pod 재시작 필요

## 주의사항

- `aws-node`를 제거하면 안 됨
- kube-proxy는 유지 (replacement 미사용)

## 검증

```bash
kubectl -n kube-system get ds aws-node
kubectl -n kube-system get ds cilium
kubectl -n kube-system get pods -l k8s-app=cilium

POD="$(kubectl -n kube-system get pods -l k8s-app=cilium -o jsonpath='{.items[0].metadata.name}')"
kubectl -n kube-system exec -it "$POD" -c cilium-agent -- cilium status
```

로컬에 `cilium` CLI가 설치되어 있다면 추가로 아래를 실행하세요.

```bash
cilium status --wait
cilium connectivity test
```

## 테스트 스크립트

```bash
./test-cilium.sh
```

## 정리

```bash
tofu destroy
```

# 3) Cilium BYOCNI Overlay 모드

Pod IP를 **클러스터 풀 IP**에서 할당하고, **터널(vxlan)** 기반으로 전달하는 방식입니다.
VPC가 Pod IP를 직접 라우팅하지 않는 구조입니다.

## 이 폴더에서 하는 일

- `vpc-cni` 애드온과 `aws-node` DaemonSet 자동 제거
- `kube-proxy` 애드온과 `kube-proxy` DS/CM 자동 제거
- Cilium 설치 (cluster-pool IPAM + kube-proxy replacement)

## 실행

```bash
cd /home/dongdorrong/github/private/kubernetes/project06/terraform/3-cilium-overlay
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

- VPC IP 고갈에서 상대적으로 자유로움
- ENI/IP 한도에 덜 민감

## 단점

- 캡슐레이션 오버헤드 및 MTU 이슈 가능
- VPC 관측/라우팅 관점에서 문제 추적이 어려워질 수 있음

## 주의사항

- `vpc-cni`와 공존 불가 (자동 제거됨)
- `cluster_pool_ipv4_cidrs`는 VPC CIDR과 겹치지 않아야 함
- `aws`, `kubectl` CLI가 로컬에서 실행 가능해야 함

## 검증

```bash
kubectl -n kube-system get ds cilium
kubectl -n kube-system get ds kube-proxy
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

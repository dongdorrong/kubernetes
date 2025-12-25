# 1) Cilium ENI 모드

EKS에서 Cilium을 **기본 CNI**로 사용하고, **ENI 기반 IPAM**으로 Pod IP를 VPC에서 직접 할당받는 방식입니다.
Pod IP가 VPC에서 바로 라우팅되므로 오버레이 없이 동작합니다.

## 이 폴더에서 하는 일

- `vpc-cni` 애드온과 `aws-node` DaemonSet 자동 제거
- `kube-proxy` 애드온과 `kube-proxy` DS/CM 자동 제거
- Cilium 설치 (ENI IPAM + kube-proxy replacement)

## 실행

```bash
cd /home/dongdorrong/github/private/kubernetes/project06/terraform/1-cilium-eni
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

- 오버레이 없이 동작해 경로가 단순하고 성능 오버헤드가 적음
- Pod IP가 VPC에서 바로 라우팅되어 운영/관측이 직관적

## 단점

- Pod IP가 VPC 주소를 소비하므로 IP 고갈 문제가 남아 있음
- 인스턴스 타입별 ENI/IP 한도 영향을 받음
- AWS 의존도가 높음(ENI 관리 권한 필요)

## 주의사항

- `vpc-cni`와 공존 불가 (자동 제거됨)
- `kube-proxy` 제거 후 Cilium이 서비스 라우팅을 담당
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

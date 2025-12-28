# 2) Cilium Gateway

Cilium Gateway API 구현체를 사용해 Gateway API를 테스트합니다.

## 기능 요약

- Cilium CNI 위에서 Gateway API 제공
- Envoy 기반 데이터 플레인을 사용
- Cilium 설치 시 `GatewayClass(cilium)` 자동 생성 가능

## 사전 준비

- Gateway API CRD 설치
- Helm 설치
- Cilium CNI 설치 필요(EKS 기본 CNI만 사용 중이라면 chained mode 등 공식 가이드 확인)

CRD 설치 예시:

```bash
kubectl get crd gateways.gateway.networking.k8s.io >/dev/null 2>&1 || \
  kubectl kustomize "github.com/kubernetes-sigs/gateway-api/config/crd?ref=v1.4.0" | kubectl apply -f -
```

Cilium 설치(Helm):

```bash
helm repo add cilium https://helm.cilium.io
helm repo update

helm install cilium cilium/cilium \
  --version 1.16.1 \
  --namespace kube-system \
  --set gatewayAPI.enabled=true \
  --set gatewayAPI.gatewayClass.create=true
```

## 적용

```bash
kubectl apply -f /home/dongdorrong/github/private/kubernetes/project08/terraform/2-cilium-gateway/manifests
```

## 검증

```bash
kubectl get gatewayclass
kubectl -n gw-cilium get gateway
kubectl -n gw-cilium get httproute
```

게이트웨이 주소 확인:

```bash
GW_ADDR=$(kubectl -n gw-cilium get gateway cilium-gw -o jsonpath='{.status.addresses[0].value}')

curl -H "Host: cilium.example.com" "http://$GW_ADDR/"
```

## 정리

```bash
kubectl delete -f /home/dongdorrong/github/private/kubernetes/project08/terraform/2-cilium-gateway/manifests
```

## 참고(GitHub)

- https://github.com/cilium/cilium/tree/main/examples/kubernetes/gateway
- https://docs.cilium.io/en/stable/network/gateway-api/

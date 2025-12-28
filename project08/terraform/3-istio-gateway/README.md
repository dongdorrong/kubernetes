# 3) Istio Gateway

Istio의 Gateway API 구현체를 사용해 Gateway API를 테스트합니다.

## 기능 요약

- Istio 컨트롤 플레인이 Gateway API 리소스를 해석
- Envoy 기반 데이터 플레인(istio-proxy) 사용
- `GatewayClass(istio)`는 Istio 설치 시 자동 생성

## 사전 준비

- Gateway API CRD 설치
- istioctl 설치

CRD 설치 예시:

```bash
kubectl get crd gateways.gateway.networking.k8s.io >/dev/null 2>&1 || \
  kubectl kustomize "github.com/kubernetes-sigs/gateway-api/config/crd?ref=v1.4.0" | kubectl apply -f -
```

Istio 설치(예시, ingress gateway 포함):

```bash
istioctl install -y \
  --set profile=minimal \
  --set components.ingressGateways[0].enabled=true \
  --set components.ingressGateways[0].name=istio-ingressgateway \
  --set components.ingressGateways[0].k8s.service.type=LoadBalancer
```

## 적용

```bash
kubectl apply -f /home/dongdorrong/github/private/kubernetes/project08/terraform/3-istio-gateway/manifests
```

## 검증

```bash
kubectl get gatewayclass
kubectl -n istio-system get gateway
kubectl -n gw-istio get httproute
```

게이트웨이 주소 확인:

```bash
GW_ADDR=$(kubectl -n istio-system get gateway istio-gw -o jsonpath='{.status.addresses[0].value}')

curl -H "Host: istio.example.com" "http://$GW_ADDR/"
```

## 정리

```bash
kubectl delete -f /home/dongdorrong/github/private/kubernetes/project08/terraform/3-istio-gateway/manifests
```

## 참고(GitHub)

- https://istio.io/latest/docs/tasks/traffic-management/ingress/gateway-api/
- https://github.com/istio/istio/tree/master/samples/gateway-api

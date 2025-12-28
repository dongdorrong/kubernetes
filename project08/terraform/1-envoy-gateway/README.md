# 1) Envoy Gateway

Envoy Gateway를 컨트롤 플레인으로 사용해 Gateway API를 테스트합니다.

## 기능 요약

- Envoy 프로젝트의 Gateway API 구현체
- GatewayClass/HTTPRoute 중심으로 표준 API 흐름 제공
- Envoy Proxy를 데이터 플레인으로 사용

## 사전 준비

- Gateway API CRD 설치
- Helm 설치

CRD 설치 예시:

```bash
kubectl get crd gateways.gateway.networking.k8s.io >/dev/null 2>&1 || \
  kubectl kustomize "github.com/kubernetes-sigs/gateway-api/config/crd?ref=v1.4.0" | kubectl apply -f -
```

Envoy Gateway 설치(Helm):

```bash
helm install eg oci://docker.io/envoyproxy/gateway-helm \
  --version v1.6.1 \
  -n envoy-gateway-system \
  --create-namespace
```

## 적용

```bash
kubectl apply -f /home/dongdorrong/github/private/kubernetes/project08/terraform/1-envoy-gateway/manifests
```

## 검증

```bash
kubectl get gatewayclass
kubectl -n gw-envoy get gateway
kubectl -n gw-envoy get httproute
```

게이트웨이 주소 확인:

```bash
GW_ADDR=$(kubectl -n gw-envoy get gateway envoy-gw -o jsonpath='{.status.addresses[0].value}')

curl -H "Host: example.com" "http://$GW_ADDR/"
```

## 정리

```bash
kubectl delete -f /home/dongdorrong/github/private/kubernetes/project08/terraform/1-envoy-gateway/manifests
```

## 참고(GitHub)

- https://github.com/envoyproxy/gateway/blob/main/examples/kubernetes/quickstart.yaml
- https://gateway.envoyproxy.io/docs/install/install-helm/

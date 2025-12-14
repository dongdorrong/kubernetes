# istio-sidecar-with-gatewayapi 테스트 README

Istio **sidecar** 기반 워크로드에서 **Gateway API(Gateway → HTTPRoute)** 경유로 서비스까지 정상 통신되는지(end-to-end) 검증한 기록/재현 절차입니다.

## 목표(성공 조건)

- `HTTPRoute`가 `Accepted=True`, `ResolvedRefs=True`
- 외부에서 NLB(또는 Gateway 주소)로 접속 시 `server: istio-envoy`가 보이고(=Istio를 통과)
- 최종 백엔드(샘플 nginx) 응답을 수신

## 구성 개요

- Gateway: Terraform에서 `kubectl_manifest.gateway`로 생성(공유 Gateway)
- 앱: 이 차트로 배포(Deployment/Service/HTTPRoute)
- 라우팅: `Gateway(API)` → `HTTPRoute` → `Service` → `Pod`

## 파일/리소스

- 차트 경로: `/home/dongdorrong/github/private/kubernetes/project04/terraform/charts/istio-sidecar-with-gatewayapi`
- values
  - `values-shared-gateway.yaml`: 공유 Gateway( Terraform 관리 )에 attach하는 모드 (`gateway.enabled=false`)
  - `values-gatewayapi.yaml`: 차트가 자체 Gateway를 만들고 테스트하는 모드 (`gateway.enabled=true`, 보통 NLB 추가 생성 가능)
- 테스트 스크립트
  - `test-gatewayapi.sh`: 상태 점검 + NLB/Gateway 주소로 curl 수행

## 사전 조건

- Istio 설치(`istiod`) + Gateway API CRD 설치
- `istio-system`에 Gateway 존재(예: `Gateway/gateway`)
- 외부 인터넷 접속을 받을 NLB가 생성되는 구성
- (공유 Gateway를 쓸 경우) Gateway의 `allowedRoutes`가 namespace selector를 사용하면, 앱 namespace에 라벨 필요

## 배포(공유 Gateway 기준)

1) 앱 배포 (예: `demo` 네임스페이스)

```bash
helm upgrade --install demo . \
  -n demo --create-namespace \
  -f values-shared-gateway.yaml
```

2) HTTPRoute 상태 확인

```bash
kubectl -n demo get httproute
kubectl -n demo get httproute demo-istio-sidecar-with-gatewayapi -o yaml | rg -n "Accepted|ResolvedRefs|reason|message"
```

## DNS(Route53) 관련

- 테스트는 `curl -H "Host: <도메인>" http://<NLB_DNS>/` 형태로 검증합니다.
- 브라우저로도 확인하려면 Route53에 `app.dongdorrong.com -> <NLB_DNS>` CNAME(또는 ALIAS) 레코드가 필요합니다.

## 네트워크/보안그룹 주의사항(NodePort)

Istio Gateway API가 만든 `gateway-istio` Service는 보통 `type=LoadBalancer`이며, EKS에서 NLB가 **노드의 NodePort(30000-32767)** 로 트래픽을 전달하는 형태가 됩니다.

- NLB는 클라이언트 **Source IP를 보존**하는 경우가 많아서, 워커 노드 SG가 NodePort 인바운드를 막고 있으면 외부 접속이 `timeout`으로 실패합니다.
- 운영에서는 NodePort 허용 CIDR을 제한하는 게 맞고, 본 프로젝트는 Terraform에서 `local.gateway_nodeport_ingress_cidrs`로 제한하도록 구성했습니다.

## 테스트 실행

```bash
APP_HOSTNAME=app.dongdorrong.com ./test-gatewayapi.sh
```

참고: NLB가 막 생성된 직후에는 DNS 전파 지연으로 `Could not resolve host`가 잠깐 발생할 수 있으며, `test-gatewayapi.sh`는 이를 위해 DNS 대기 로직을 포함합니다.

정상 시 예시 신호:

- `HTTPRoute Accepted ResolvedRefs`가 `True True`
- `LB_DNS=...elb.amazonaws.com` 출력
- `HTTP/1.1 200 OK` + `server: istio-envoy`
- nginx welcome page 출력

## 트러블슈팅

### 1) `HTTPRoute Accepted=False`

- (공유 Gateway + namespace selector 사용 시) 네임스페이스 라벨이 없으면 attach가 거부됩니다.
  - 예: `kubectl label ns demo shared-gateway-access=true --overwrite`
- `kubectl -n demo get httproute <name> -o yaml`에서 `reason/message` 확인

### 2) curl timeout (`Failed to connect ... port 80 ... Timeout`)

대부분 “NLB → 노드(NodePort)” 경로가 막힌 케이스입니다.

- 워커 노드 SG(NodePort 30000-32767 인바운드) 확인
- NLB Target Group Health(Healthy/Unhealthy) 확인

### 3) Host 매칭 실패

- `HOSTNAME`은 쉘에서 기본으로 잡혀있는 경우가 많아 충돌할 수 있어, 스크립트는 `APP_HOSTNAME`을 사용합니다.
- `HTTPRoute.spec.hostnames`에 `APP_HOSTNAME`이 포함돼 있어야 합니다.

#!/usr/bin/env bash
set -euo pipefail

require() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "ERROR: missing command: $1" >&2
    exit 1
  }
}

require kubectl
require curl

NAMESPACE="${NAMESPACE:-demo}"
RELEASE="${RELEASE:-demo}"
# NOTE: many shells export HOSTNAME by default (node name), so don't use it for HTTP Host header.
APP_HOSTNAME="${APP_HOSTNAME:-app.dongdorrong.com}"
GATEWAY_NS="${GATEWAY_NS:-istio-system}"
GATEWAY_NAME="${GATEWAY_NAME:-gateway}"
GATEWAY_LB_SERVICE="${GATEWAY_LB_SERVICE:-}"
CURL_CONNECT_TIMEOUT="${CURL_CONNECT_TIMEOUT:-3}"
CURL_MAX_TIME="${CURL_MAX_TIME:-15}"
DNS_WAIT_SECONDS="${DNS_WAIT_SECONDS:-120}"
DNS_WAIT_INTERVAL="${DNS_WAIT_INTERVAL:-3}"

wait_for_dns() {
  local host="$1"
  if ! command -v getent >/dev/null 2>&1; then
    return 0
  fi

  local end=$((SECONDS + DNS_WAIT_SECONDS))
  while ((SECONDS < end)); do
    if getent ahosts "$host" >/dev/null 2>&1; then
      return 0
    fi
    sleep "$DNS_WAIT_INTERVAL"
  done
  return 1
}

echo "[1/6] Cluster connectivity"
kubectl version >/dev/null

echo "[2/6] Discover HTTPRoute name"
HTTPROUTE_NAME="$(
  kubectl -n "$NAMESPACE" get httproute \
    -l "app.kubernetes.io/instance=${RELEASE}" \
    -o jsonpath='{range .items[*]}{.metadata.name}{"\n"}{end}' 2>/dev/null | head -n 1 || true
)"
if [[ -z "${HTTPROUTE_NAME}" ]]; then
  echo "ERROR: HTTPRoute not found in namespace=${NAMESPACE} (label app.kubernetes.io/instance=${RELEASE})" >&2
  echo "Hint: kubectl -n ${NAMESPACE} get httproute" >&2
  exit 1
fi
echo "HTTPROUTE_NAME=${HTTPROUTE_NAME}"
echo "APP_HOSTNAME=${APP_HOSTNAME}"
if [[ "${APP_HOSTNAME}" != *.* ]]; then
  echo "WARN: APP_HOSTNAME does not look like a FQDN (expected something like app.dongdorrong.com): '${APP_HOSTNAME}'" >&2
fi

ROUTE_HOSTNAMES="$(
  kubectl -n "$NAMESPACE" get httproute "$HTTPROUTE_NAME" -o jsonpath='{.spec.hostnames[*]}' 2>/dev/null || true
)"
if [[ -n "${ROUTE_HOSTNAMES}" ]]; then
  echo "HTTPROUTE hostnames: ${ROUTE_HOSTNAMES}"
  if ! echo " ${ROUTE_HOSTNAMES} " | grep -q " ${APP_HOSTNAME} "; then
    echo "WARN: APP_HOSTNAME is not included in HTTPRoute.spec.hostnames (Host match will fail)" >&2
  fi
fi

echo "[3/6] Check HTTPRoute status (Accepted/ResolvedRefs)"
kubectl -n "$NAMESPACE" get httproute "$HTTPROUTE_NAME" -o jsonpath='{.status.parents[*].parentRef.name}{"\n"}{.status.parents[*].conditions[*].type}{"\n"}{.status.parents[*].conditions[*].status}{"\n"}' || true
echo

ACCEPTED_STATUS="$(
  kubectl -n "$NAMESPACE" get httproute "$HTTPROUTE_NAME" \
    -o jsonpath='{range .status.parents[*].conditions[*]}{.type}={.status}{"\n"}{end}' 2>/dev/null \
    | grep -E '^Accepted=' | head -n 1 | cut -d= -f2 || true
)"
if [[ "${ACCEPTED_STATUS}" == "False" ]]; then
  echo "ERROR: HTTPRoute Accepted=False (most commonly: namespace label missing for shared gateway)." >&2
  kubectl -n "$NAMESPACE" get httproute "$HTTPROUTE_NAME" -o jsonpath='{range .status.parents[*].conditions[*]}- {.type}={.status} ({.reason}) {.message}{"\n"}{end}' 2>/dev/null || true
  echo "Hint: kubectl label ns ${NAMESPACE} shared-gateway-access=true --overwrite" >&2
  exit 1
fi

echo "[4/6] Discover Gateway address (preferred) or LB Service DNS"

# Preferred: Gateway.status.addresses[0].value (Istio Gateway API reports this reliably)
LB_DNS="$(
  kubectl -n "$GATEWAY_NS" get gateway "$GATEWAY_NAME" -o jsonpath='{.status.addresses[0].value}' 2>/dev/null || true
)"

if [[ -n "${LB_DNS}" ]]; then
  echo "LB_DNS=${LB_DNS}"
else
  echo "INFO: Gateway/${GATEWAY_NAME} has no status.addresses yet; falling back to Service(Type=LoadBalancer)."

if [[ -n "${GATEWAY_LB_SERVICE}" ]]; then
  SVC_NAME="${GATEWAY_LB_SERVICE}"
else
  if kubectl -n "$GATEWAY_NS" get svc gateway >/dev/null 2>&1; then
    SVC_NAME="gateway"
  else
    SVC_NAME="$(
      kubectl -n "$GATEWAY_NS" get svc \
        -o jsonpath='{range .items[?(@.spec.type=="LoadBalancer")]}{.metadata.name}{"\n"}{end}' 2>/dev/null \
        | grep -E "^${GATEWAY_NAME}(-|$)" \
        | head -n 1 || true
    )"
  fi
fi

if [[ -z "${SVC_NAME}" ]]; then
  echo "ERROR: could not find a LoadBalancer Service in namespace=${GATEWAY_NS} (set GATEWAY_LB_SERVICE to override)" >&2
  echo "Hint: kubectl -n ${GATEWAY_NS} get svc" >&2
  exit 1
fi

LB_DNS="$(
  kubectl -n "$GATEWAY_NS" get svc "$SVC_NAME" -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null || true
)"
if [[ -z "${LB_DNS}" ]]; then
  echo "ERROR: Service/${SVC_NAME} has no loadBalancer hostname yet (still provisioning?)" >&2
  echo "Hint: kubectl -n ${GATEWAY_NS} get svc ${SVC_NAME} -o yaml | sed -n '1,200p'" >&2
  exit 1
fi
echo "GATEWAY_LB_SERVICE=${SVC_NAME}"
echo "LB_DNS=${LB_DNS}"
fi

echo "[5/6] Verify Service endpoints"
SVC_NAME_APP="$(kubectl -n "$NAMESPACE" get svc -l "app.kubernetes.io/instance=${RELEASE}" -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || true)"
if [[ -n "${SVC_NAME_APP}" ]]; then
  kubectl -n "$NAMESPACE" get endpoints "$SVC_NAME_APP" -o wide || true
fi

echo "[5.5/6] Verify Gateway service(s) (optional debug)"
if kubectl -n "$GATEWAY_NS" get svc gateway-istio >/dev/null 2>&1; then
  kubectl -n "$GATEWAY_NS" get svc gateway-istio -o wide || true
  kubectl -n "$GATEWAY_NS" get svc gateway-istio -o jsonpath='{range .spec.ports[*]}{.name}={.port}->{.targetPort}{" nodePort="}{.nodePort}{"\n"}{end}' || true
else
  kubectl -n "$GATEWAY_NS" get svc --field-selector spec.type=LoadBalancer -o wide || true
fi

echo "[6/6] E2E request (Gateway -> HTTPRoute -> Service)"
# Shared Gateway 설정(allowedRoutes: selector)을 쓰는 경우, namespace 라벨이 없으면 HTTPRoute Accepted=false가 됩니다.
NS_LABEL="$(
  kubectl get ns "$NAMESPACE" -o jsonpath='{.metadata.labels.shared-gateway-access}' 2>/dev/null || true
)"
if [[ "${NS_LABEL}" != "true" ]]; then
  echo "WARN: namespace/${NAMESPACE} label shared-gateway-access!=true (current: '${NS_LABEL}')" >&2
  echo "      kubectl label ns ${NAMESPACE} shared-gateway-access=true --overwrite" >&2
fi
URL="http://${LB_DNS}/"
echo "curl -H \"Host: ${APP_HOSTNAME}\" ${URL}"

if ! wait_for_dns "$LB_DNS"; then
  echo "ERROR: DNS could not resolve within ${DNS_WAIT_SECONDS}s: ${LB_DNS}" >&2
  echo "Hint: AWS NLB DNS 레코드 전파 지연일 수 있어 잠시 후 재시도하거나, 로컬 DNS 설정을 확인하세요." >&2
  exit 6
fi

set +e
TMP_HEADERS="$(mktemp)"
TMP_BODY="$(mktemp)"
curl -sS -D "$TMP_HEADERS" -o "$TMP_BODY" \
  --connect-timeout "$CURL_CONNECT_TIMEOUT" --max-time "$CURL_MAX_TIME" \
  -H "Host: ${APP_HOSTNAME}" "${URL}"
RC=$?
set -e

if [[ $RC -ne 0 ]]; then
  echo "ERROR: curl failed (exit=${RC})." >&2
  if [[ $RC -eq 6 ]]; then
    echo "Hint: DNS resolution failed for ${LB_DNS}. Wait a bit (NLB DNS propagation) or check local DNS." >&2
  elif [[ $RC -eq 28 ]]; then
    echo "Hint: timeout이면 AWS NLB Target Group health / 노드 SG(NodePort) 인바운드 / 라우팅 경로를 확인하세요." >&2
  fi
  exit $RC
fi

echo "--- response headers (first 20 lines) ---"
sed -n '1,20p' "$TMP_HEADERS"
echo "--- response body (first 30 lines) ---"
sed -n '1,30p' "$TMP_BODY"
rm -f "$TMP_HEADERS" "$TMP_BODY"

echo
echo "OK"

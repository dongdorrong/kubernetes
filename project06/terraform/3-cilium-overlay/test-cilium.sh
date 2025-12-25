#!/usr/bin/env bash
set -euo pipefail

namespace="${NAMESPACE:-kube-system}"

fail() {
  echo "ERROR: $*" >&2
  exit 1
}

info() {
  echo "INFO: $*"
}

require() {
  command -v "$1" >/dev/null 2>&1 || fail "$1 not found"
}

get_cm_value() {
  local key="$1"
  kubectl -n "$namespace" get configmap cilium-config -o yaml \
    | awk -v k="$key" -F': ' '$1 == "  "k {print $2; exit}' \
    | tr -d '"'
}

require kubectl

info "Checking cilium daemonset readiness..."
kubectl -n "$namespace" get ds cilium >/dev/null
ready="$(kubectl -n "$namespace" get ds cilium -o jsonpath='{.status.numberReady}')"
desired="$(kubectl -n "$namespace" get ds cilium -o jsonpath='{.status.desiredNumberScheduled}')"
[[ "$ready" == "$desired" ]] || fail "cilium ds not ready ($ready/$desired)"

if kubectl -n "$namespace" get ds kube-proxy >/dev/null 2>&1; then
  fail "kube-proxy daemonset should be absent for overlay mode"
fi

if kubectl -n "$namespace" get ds aws-node >/dev/null 2>&1; then
  fail "aws-node daemonset should be absent for overlay mode"
fi

pod="$(kubectl -n "$namespace" get pods -l k8s-app=cilium -o jsonpath='{.items[0].metadata.name}')"
[[ -n "$pod" ]] || fail "no cilium pod found"
kubectl -n "$namespace" exec -i "$pod" -c cilium-agent -- cilium status >/dev/null

ipam="$(get_cm_value ipam)"
routing_mode="$(get_cm_value routing-mode)"
tunnel_protocol="$(get_cm_value tunnel-protocol)"
kpr="$(get_cm_value kube-proxy-replacement | tr '[:upper:]' '[:lower:]')"

[[ "$ipam" == "cluster-pool" ]] || fail "ipam expected 'cluster-pool' but got '$ipam'"
[[ "$routing_mode" == "tunnel" ]] || fail "routing-mode expected 'tunnel' but got '$routing_mode'"
[[ "$tunnel_protocol" == "vxlan" ]] || fail "tunnel-protocol expected 'vxlan' but got '$tunnel_protocol'"
[[ "$kpr" == "true" ]] || fail "kube-proxy-replacement expected 'true' but got '$kpr'"

info "Overlay mode checks passed."

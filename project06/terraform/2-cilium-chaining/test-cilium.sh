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

kubectl -n "$namespace" get ds aws-node >/dev/null \
  || fail "aws-node daemonset should exist for chaining mode"
kubectl -n "$namespace" get ds kube-proxy >/dev/null \
  || fail "kube-proxy daemonset should exist for chaining mode"

pod="$(kubectl -n "$namespace" get pods -l k8s-app=cilium -o jsonpath='{.items[0].metadata.name}')"
[[ -n "$pod" ]] || fail "no cilium pod found"
kubectl -n "$namespace" exec -i "$pod" -c cilium-agent -- cilium status >/dev/null

kpr="$(get_cm_value kube-proxy-replacement | tr '[:upper:]' '[:lower:]')"
chaining_mode="$(get_cm_value cni-chaining-mode)"

[[ "$kpr" == "false" ]] || fail "kube-proxy-replacement expected 'false' but got '$kpr'"
[[ "$chaining_mode" == "aws-cni" ]] || fail "cni-chaining-mode expected 'aws-cni' but got '$chaining_mode'"

info "Chaining mode checks passed."

#!/usr/bin/env bash
set -euo pipefail

# Usage: ./install-samples.sh [namespace] [additional helm args...]
# Default namespace is "gateway-samples".

NAMESPACE="${1:-gateway-samples}"
if [[ $# -gt 0 ]]; then
  shift
fi
EXTRA_ARGS=("$@")

CHART_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"

RELEASES=(
  "sample-app:values-sample-app.yaml"
  "sample-was:values-sample-was.yaml"
  "sample-web:values-sample-web.yaml"
)

for entry in "${RELEASES[@]}"; do
  release="${entry%%:*}"
  values_file="${entry#*:}"
  if [[ ! -f "${CHART_DIR}/${values_file}" ]]; then
    echo "Values file not found: ${CHART_DIR}/${values_file}" >&2
    exit 1
  fi

  echo ">>> Deploying ${release} to namespace ${NAMESPACE} using ${values_file}"
  helm upgrade --install "${release}" "${CHART_DIR}" \
    -n "${NAMESPACE}" --create-namespace \
    -f "${CHART_DIR}/${values_file}" \
    "${EXTRA_ARGS[@]}"
done

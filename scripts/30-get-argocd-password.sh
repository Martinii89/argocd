#!/usr/bin/env bash
set -euo pipefail

NAMESPACE="${ARGO_NAMESPACE:-argocd}"

if ! command -v kubectl >/dev/null 2>&1; then
  echo "[ERROR] kubectl not found in PATH." >&2
  exit 1
fi

export KUBECONFIG="${KUBECONFIG:-$HOME/.kube/config}"
if [[ ! -f "${KUBECONFIG}" ]]; then
  echo "[ERROR] kubeconfig not found at ${KUBECONFIG}. Export KUBECONFIG or place it in ~/.kube/config." >&2
  exit 1
fi

kubectl -n "$NAMESPACE" get secret argocd-initial-admin-secret \
  -o jsonpath='{.data.password}' | base64 --decode

printf '\n'

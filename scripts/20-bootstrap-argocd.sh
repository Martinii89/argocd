#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(realpath "${SCRIPT_DIR}/..")"

log() {
  echo -e "[ARGOCD] $1"
}

if ! command -v kubectl >/dev/null 2>&1; then
  echo "[ERROR] kubectl not found in PATH." >&2
  exit 1
fi

if ! command -v helm >/dev/null 2>&1; then
  echo "[ERROR] helm not found in PATH." >&2
  exit 1
fi

export KUBECONFIG="${KUBECONFIG:-$HOME/.kube/config}"
if [[ ! -f "${KUBECONFIG}" ]]; then
  echo "[ERROR] kubeconfig not found at ${KUBECONFIG}. Export KUBECONFIG or place it in ~/.kube/config." >&2
  exit 1
fi



log "Adding Argo Helm repo"
helm repo add argo-cd https://argoproj.github.io/argo-helm >/dev/null
helm repo update >/dev/null

log "Ensuring chart dependencies are present"
helm dependency update "infra/apps/argo" >/dev/null

log "Installing/Upgrading Argo CD Helm release"
helm upgrade --install argocd "infra/apps/argo" `
  --namespace argocd `
  --create-namespace

log "Waiting for Argo CD server deployment"
kubectl rollout status deployment/argo-cd-argocd-server \
  --namespace argocd \
  --timeout=5m

log "Applying GitOps root application"
helm template "${REPO_ROOT}/charts/${ROOT_APP_NAME}" | kubectl apply -f -

log "Bootstrapping complete"

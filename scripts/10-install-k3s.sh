#!/usr/bin/env bash
set -euo pipefail

if [[ $(id -u) -ne 0 ]]; then
  echo "[ERROR] This script must be run as root." >&2
  exit 1
fi

log() {
  echo -e "[K3S] $1"
}

if systemctl is-enabled k3s >/dev/null 2>&1; then
  log "k3s service already enabled; skipping installation"
  exit 0
fi

INSTALL_K3S_CHANNEL="${INSTALL_K3S_CHANNEL:-stable}"
INSTALL_K3S_EXEC="${INSTALL_K3S_EXEC:-server --disable traefik}"

log "Downloading k3s installer (${INSTALL_K3S_CHANNEL} channel)"
export INSTALL_K3S_CHANNEL
export INSTALL_K3S_EXEC
curl -sfL https://get.k3s.io | sh -

log "Waiting for k3s service to report healthy"
systemctl enable k3s >/dev/null
systemctl restart k3s
systemctl is-active --quiet k3s || systemctl status k3s --no-pager

KUBECONFIG_SOURCE="/etc/rancher/k3s/k3s.yaml"
KUBECONFIG_DEST="${SUDO_USER:-root}"
if [[ "${KUBECONFIG_DEST}" != "root" ]]; then
  KUBECONFIG_DEST="/home/${KUBECONFIG_DEST}/.kube"
else
  KUBECONFIG_DEST="/root/.kube"
fi

mkdir -p "${KUBECONFIG_DEST}"
cp "${KUBECONFIG_SOURCE}" "${KUBECONFIG_DEST}/config"
chown "${SUDO_USER:-root}:${SUDO_USER:-root}" "${KUBECONFIG_DEST}/config"
chmod 600 "${KUBECONFIG_DEST}/config"

log "k3s installation complete. Remember to copy the kubeconfig securely to your workstation if needed."

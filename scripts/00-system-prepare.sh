#!/usr/bin/env bash
set -euo pipefail

if [[ $(id -u) -ne 0 ]]; then
  echo "[ERROR] This script must be run as root." >&2
  exit 1
fi

log() {
  echo -e "[SYSTEM] $1"
}

if ! command -v apt-get >/dev/null 2>&1; then
  echo "[ERROR] This helper currently targets Debian/Ubuntu systems. Adjust it for your distribution." >&2
  exit 1
fi

log "Updating package index"
apt-get update -y

log "Upgrading base packages"
DEBIAN_FRONTEND=noninteractive apt-get upgrade -y

log "Installing baseline tooling"
DEBIAN_FRONTEND=noninteractive apt-get install -y \
  curl \
  jq \
  git \
  ufw \
  ca-certificates

if swapoff -a 2>/dev/null; then
  log "Swap disabled"
else
  log "Swap already disabled"
fi

if grep -q "\sswap\s" /etc/fstab; then
  log "Commenting out swap entries in /etc/fstab"
  sed -i.bak '/\sswap\s/s/^/#/' /etc/fstab
fi

touch /etc/modules-load.d/k8s.conf
cat <<'EOF' >/etc/sysctl.d/99-kubernetes-cri.conf
net.bridge.bridge-nf-call-iptables = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward = 1
EOF
sysctl --system >/dev/null

if command -v modprobe >/dev/null 2>&1; then
  modprobe br_netfilter || true
fi

if command -v ufw >/dev/null 2>&1; then
  log "Configuring uncomplicated firewall"
  ufw allow OpenSSH >/dev/null 2>&1 || true
  ufw allow 6443/tcp >/dev/null 2>&1 || true
  ufw allow 10250/tcp >/dev/null 2>&1 || true
  ufw allow 80/tcp >/dev/null 2>&1 || true
  ufw allow 443/tcp >/dev/null 2>&1 || true
  if ufw status | grep -q "Status: inactive"; then
    yes | ufw enable >/dev/null 2>&1 || true
  fi
fi

log "System preparation complete"

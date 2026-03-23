#!/usr/bin/env bash
set -euo pipefail

# ==========================================
# DOCKER INSTALL (OFFICIAL REPO)
# ==========================================

echo "[INFO] Installing Docker..."

apt-get update -qq
apt-get install -y ca-certificates curl gnupg

install -m 0755 -d /etc/apt/keyrings

if [ ! -f /etc/apt/keyrings/docker.gpg ]; then
  curl -fsSL https://download.docker.com/linux/debian/gpg \
    | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
fi

chmod a+r /etc/apt/keyrings/docker.gpg

ARCH="$(dpkg --print-architecture)"
CODENAME="$(. /etc/os-release && echo "$VERSION_CODENAME")"

echo \
  "deb [arch=${ARCH} signed-by=/etc/apt/keyrings/docker.gpg] \
  https://download.docker.com/linux/debian ${CODENAME} stable" \
  > /etc/apt/sources.list.d/docker.list

apt-get update -qq

apt-get install -y \
  docker-ce \
  docker-ce-cli \
  containerd.io \
  docker-buildx-plugin \
  docker-compose-plugin

echo "[INFO] Enabling Docker..."
systemctl enable --now docker

# ==========================================
# USER PERMISSIONS
# ==========================================

CURRENT_USER=$(logname 2>/dev/null || echo "${SUDO_USER:-$USER}")

echo "[INFO] Adding $CURRENT_USER to docker group..."
usermod -aG docker "$CURRENT_USER"

echo "[WARN] You must log out and back in (or run: newgrp docker)"

echo "[INFO] Docker installation complete."
docker --version
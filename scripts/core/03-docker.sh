#!/bin/bash
set -e

CURRENT_USER=$(logname)

echo "[INFO] Installing Docker..."

apt-get update
apt-get install -y ca-certificates curl gnupg lsb-release

install -m 0755 -d /etc/apt/keyrings

curl -fsSL https://download.docker.com/linux/debian/gpg \
  | gpg --dearmor -o /etc/apt/keyrings/docker.gpg

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
  https://download.docker.com/linux/debian \
  $(lsb_release -cs) stable" \
  > /etc/apt/sources.list.d/docker.list

apt-get update

apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

systemctl enable docker
systemctl start docker

echo "[INFO] Adding user to docker group..."

usermod -aG docker "$CURRENT_USER"

# Apply immediately (critical fix)
if ! groups "$CURRENT_USER" | grep -q docker; then
    echo "[INFO] Applying docker group without logout"
    newgrp docker <<EOF
echo "docker group applied"
EOF
fi

echo "[INFO] Docker installed successfully"
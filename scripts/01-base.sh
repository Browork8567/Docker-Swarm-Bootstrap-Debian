#!/usr/bin/env bash
set -euo pipefail

# ==========================================
# BASE SYSTEM SETUP (MINIMAL + SAFE)
# ==========================================

echo "[INFO] Updating system packages..."
apt-get update -qq
apt-get upgrade -y

echo "[INFO] Installing required base packages..."

apt-get install -y \
  ca-certificates \
  curl \
  gnupg \
  lsb-release \
  openssh-server \
  ufw \
  sudo \
  bash-completion

echo "[INFO] Enabling SSH service..."
systemctl enable --now ssh

echo "[INFO] Setting correct permissions on SSH directory..."

CURRENT_USER=$(logname 2>/dev/null || echo "${SUDO_USER:-$USER}")
HOME_DIR=$(eval echo "~$CURRENT_USER")
SSH_DIR="$HOME_DIR/.ssh"

mkdir -p "$SSH_DIR"
chmod 700 "$SSH_DIR"
chown -R "$CURRENT_USER:$CURRENT_USER" "$SSH_DIR"

echo "[INFO] Base system setup complete."
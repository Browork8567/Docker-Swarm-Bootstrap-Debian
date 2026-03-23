#!/usr/bin/env bash
set -euo pipefail

echo "[03] SSH hardening + key setup..."

CURRENT_USER=$(logname 2>/dev/null || echo "${SUDO_USER:-$USER}")
HOME_DIR=$(eval echo "~$CURRENT_USER")
SSH_DIR="$HOME_DIR/.ssh"

mkdir -p "$SSH_DIR"
chmod 700 "$SSH_DIR"
chown -R "$CURRENT_USER:$CURRENT_USER" "$SSH_DIR"

if [ ! -f "$SSH_DIR/id_ed25519" ]; then
  sudo -u "$CURRENT_USER" ssh-keygen -t ed25519 -N "" -f "$SSH_DIR/id_ed25519"
fi

touch "$SSH_DIR/authorized_keys"
chmod 600 "$SSH_DIR/authorized_keys"
chown "$CURRENT_USER:$CURRENT_USER" "$SSH_DIR/authorized_keys"

echo "[03] SSH ready."
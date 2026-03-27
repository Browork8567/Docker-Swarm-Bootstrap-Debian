#!/bin/bash
set -euo pipefail

CONFIG_DIR="/etc/swarm-bootstrap"
CONFIG_FILE="$CONFIG_DIR/config.json"

mkdir -p "$CONFIG_DIR"

echo "[INFO] Starting interactive configuration..."

NODE_IP=$(hostname -I | awk '{print $1}')
echo "[INFO] Detected node IP: $NODE_IP"

read -rp "Enter PRIMARY manager IP: " PRIMARY_MANAGER_IP
read -rp "Enter manager IP range (e.g. 192.168.69.10-192.168.69.20): " MANAGER_RANGE
read -rp "Enter worker IP range (e.g. 192.168.69.30-192.168.69.60): " WORKER_RANGE

read -rp "Enter bootstrap username [default: swarm-bootstrap]: " BOOTSTRAP_USER
BOOTSTRAP_USER=${BOOTSTRAP_USER:-swarm-bootstrap}

read -rsp "Enter bootstrap password: " BOOTSTRAP_PASS
echo

IS_PRIMARY=false
if [[ "$NODE_IP" == "$PRIMARY_MANAGER_IP" ]]; then
    IS_PRIMARY=true
fi

cat > "$CONFIG_FILE" <<EOF
{
  "node_ip": "$NODE_IP",
  "primary_manager_ip": "$PRIMARY_MANAGER_IP",
  "manager_range": "$MANAGER_RANGE",
  "worker_range": "$WORKER_RANGE",
  "bootstrap_user": "$BOOTSTRAP_USER",
  "bootstrap_password": "$BOOTSTRAP_PASS",
  "is_primary_manager": $IS_PRIMARY
}
EOF

jq empty "$CONFIG_FILE"

echo "[INFO] Configuration saved to $CONFIG_FILE"
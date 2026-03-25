#!/bin/bash
set -e

CONFIG_DIR="/etc/swarm-bootstrap"
CONFIG_FILE="$CONFIG_DIR/config.json"

mkdir -p "$CONFIG_DIR"

echo "[INFO] Starting interactive configuration..."

read -rp "Enter node role (manager/worker): " ROLE
read -rp "Enter node IP address: " NODE_IP
read -rp "Enter admin username: " ADMIN_USER
read -rp "Enter admin IP address: " ADMIN_IP

IS_PRIMARY_MANAGER=false

if [[ "$ROLE" == "manager" ]]; then
    read -rp "Is this the PRIMARY manager node? (y/n): " PRIMARY_INPUT
    if [[ "$PRIMARY_INPUT" =~ ^[Yy]$ ]]; then
        IS_PRIMARY_MANAGER=true
    fi
fi

cat > "$CONFIG_FILE" <<EOF
{
  "role": "$ROLE",
  "node_ip": "$NODE_IP",
  "admin_user": "$ADMIN_USER",
  "admin_ip": "$ADMIN_IP",
  "is_primary_manager": $IS_PRIMARY_MANAGER
}
EOF

echo "[INFO] Configuration saved to $CONFIG_FILE"
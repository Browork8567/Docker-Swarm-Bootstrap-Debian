#!/bin/bash
set -e

CONFIG_DIR="/etc/swarm-bootstrap"
CONFIG_FILE="$CONFIG_DIR/config.json"

mkdir -p "$CONFIG_DIR"

echo "==== Swarm Bootstrap Configuration ===="

CURRENT_USER=$(logname)

read -p "Node role (manager/worker): " NODE_ROLE
read -p "Hostname: " HOSTNAME
read -p "Node IP: " NODE_IP

read -p "Manager IPs (comma-separated): " MANAGERS

# Admin user
read -p "Is admin user '$CURRENT_USER'? (y/n): " USE_CURRENT
if [[ "$USE_CURRENT" == "y" ]]; then
    ADMIN_USER="$CURRENT_USER"
else
    read -p "Enter admin username: " ADMIN_USER
fi

# Admin IP (auto-detect)
AUTO_IP=$(who am i | awk '{print $5}' | tr -d '()')
echo "[INFO] Detected admin IP: $AUTO_IP"

read -p "Use detected IP? (y/n): " USE_AUTO
if [[ "$USE_AUTO" == "y" ]]; then
    ADMIN_IP="$AUTO_IP"
else
    read -p "Enter admin IP: " ADMIN_IP
fi

# Manager mode
if [[ "$NODE_ROLE" == "manager" ]]; then
    read -p "Manager availability (active/drain): " MANAGER_MODE
else
    MANAGER_MODE="n/a"
fi

# Worker promotion
if [[ "$NODE_ROLE" == "worker" ]]; then
    read -p "Enable manager promotion candidate? (y/n): " CANDIDATE
    if [[ "$CANDIDATE" == "y" ]]; then
        echo "[INFO] Lower number = higher priority"
        read -p "Enter candidate priority (1,2,3...): " PRIORITY
    else
        PRIORITY=""
    fi
else
    PRIORITY=""
fi

cat > "$CONFIG_FILE" <<EOF
{
  "role": "$NODE_ROLE",
  "hostname": "$HOSTNAME",
  "node_ip": "$NODE_IP",
  "managers": [$(echo $MANAGERS | sed 's/,/","/g' | sed 's/^/"/;s/$/"/')],
  "admin_user": "$ADMIN_USER",
  "admin_ip": "$ADMIN_IP",
  "manager_mode": "$MANAGER_MODE",
  "candidate_priority": "$PRIORITY"
}
EOF

echo "[INFO] Config written to $CONFIG_FILE"
#!/usr/bin/env bash
set -euo pipefail

CONFIG="/etc/swarm-bootstrap/config.json"
NODES_JSON="/etc/swarm-bootstrap/nodes.json"
INIT_FLAG="/etc/swarm-bootstrap/.initialized"

echo "[07] Configuring Docker Swarm..."

# Validate config exists
if [[ ! -f "$CONFIG" ]]; then
    echo "[ERROR] Missing config.json"
    exit 1
fi

ROLE=$(jq -r .role "$CONFIG")
NODE_IP=$(jq -r .node_ip "$CONFIG")
IS_PRIMARY=$(jq -r .is_primary_manager "$CONFIG")
PRIMARY_MANAGER=$(jq -r .primary_manager_ip "$CONFIG")

# -------------------------------
# PRIMARY MANAGER INIT
# -------------------------------
if [[ "$ROLE" == "manager" && "$IS_PRIMARY" == "true" ]]; then
    if docker info 2>/dev/null | grep -q "Swarm: active"; then
        echo "[INFO] Swarm already initialized"
    else
        echo "[INFO] Initializing swarm on PRIMARY manager..."
        docker swarm init --advertise-addr "$NODE_IP"
    fi

    # Initialize nodes.json if not present
    if [[ ! -f "$NODES_JSON" ]]; then
        echo "[INFO] Creating initial nodes.json"
        mkdir -p /etc/swarm-bootstrap

        cat > "$NODES_JSON" <<EOF
{
  "managers": ["$NODE_IP"],
  "workers": []
}
EOF
    fi

    touch "$INIT_FLAG"
    echo "[INFO] Primary manager setup complete"
    exit 0
fi

# -------------------------------
# JOIN EXISTING SWARM (FIXED)
# -------------------------------
if [[ -z "$PRIMARY_MANAGER" || "$PRIMARY_MANAGER" == "null" ]]; then
    echo "[ERROR] No primary manager defined in config"
    exit 1
fi

echo "[INFO] Joining swarm via primary manager: $PRIMARY_MANAGER"

# Verify manager is reachable
SSH_USER="swarmd"
SSH_KEY="/home/swarmd/.ssh/id_rsa"

SSH_OPTS="-i $SSH_KEY -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o ConnectTimeout=5"

if ! ssh $SSH_OPTS "${SSH_USER}@${PRIMARY_MANAGER}" "docker info" >/dev/null 2>&1; then
    echo "[ERROR] Cannot reach primary manager via swarmd SSH"
    exit 1
fi

TOKEN=$(ssh $SSH_OPTS "${SSH_USER}@${PRIMARY_MANAGER}" "docker swarm join-token -q $ROLE")

TOKEN=$(ssh "$PRIMARY_MANAGER" "docker swarm join-token -q $ROLE")

if docker swarm join --token "$TOKEN" "$PRIMARY_MANAGER:2377"; then
    echo "[INFO] Successfully joined swarm"
else
    echo "[ERROR] Failed to join swarm"
    exit 1
fi

# -------------------------------
# POST-JOIN VALIDATION
# -------------------------------
sleep 2

if ! docker info 2>/dev/null | grep -q "Swarm: active"; then
    echo "[ERROR] Node failed to properly join swarm"
    exit 1
fi

echo "[INFO] Swarm join validated"

echo "[07] Swarm configuration complete."
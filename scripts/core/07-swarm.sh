#!/usr/bin/env bash
set -euo pipefail

CONFIG="/etc/swarm-bootstrap/config.json"
NODES_JSON="/etc/swarm-bootstrap/nodes.json"
INIT_FLAG="/etc/swarm-bootstrap/.initialized"

echo "[08] Configuring Docker Swarm..."

# Validate config exists
if [[ ! -f "$CONFIG" ]]; then
    echo "[ERROR] Missing config.json"
    exit 1
fi

ROLE=$(jq -r .role "$CONFIG")
NODE_IP=$(jq -r .node_ip "$CONFIG")
IS_PRIMARY=$(jq -r .is_primary_manager "$CONFIG")

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
# JOIN EXISTING SWARM
# -------------------------------
echo "[INFO] Attempting to join existing swarm..."

# Wait for nodes.json to exist
for i in {1..30}; do
    if [[ -f "$NODES_JSON" ]]; then
        break
    fi
    echo "[INFO] Waiting for nodes.json..."
    sleep 2
done

if [[ ! -f "$NODES_JSON" ]]; then
    echo "[ERROR] nodes.json not found after waiting"
    exit 1
fi

MANAGERS=$(jq -r '.managers[]' "$NODES_JSON")

JOINED=false

for MANAGER in $MANAGERS; do
    echo "[INFO] Trying manager $MANAGER..."

    if ssh -o ConnectTimeout=3 "$MANAGER" "docker info" >/dev/null 2>&1; then
        TOKEN=$(ssh "$MANAGER" "docker swarm join-token -q $ROLE")

        if docker swarm join --token "$TOKEN" "$MANAGER:2377"; then
            echo "[INFO] Successfully joined swarm via $MANAGER"
            JOINED=true
            break
        fi
    fi
done

if [[ "$JOINED" != "true" ]]; then
    echo "[ERROR] Failed to join swarm"
    exit 1
fi

# -------------------------------
# POST-JOIN VALIDATION (MEDIUM FIX 5)
# -------------------------------
sleep 2

if ! docker info 2>/dev/null | grep -q "Swarm: active"; then
    echo "[ERROR] Node failed to properly join swarm"
    exit 1
fi

echo "[INFO] Swarm join validated"

echo "[08] Swarm configuration complete."
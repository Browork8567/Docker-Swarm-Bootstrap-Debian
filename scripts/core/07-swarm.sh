#!/usr/bin/env bash
set -euo pipefail

CONFIG="/etc/swarm-bootstrap/config.json"
NODES_JSON="/etc/swarm-bootstrap/nodes.json"

echo "[07] Configuring Docker Swarm..."

ROLE_IP=$(jq -r .node_ip "$CONFIG")
PRIMARY=$(jq -r .primary_manager_ip "$CONFIG")
IS_PRIMARY=$(jq -r .is_primary_manager "$CONFIG")

if [[ "$IS_PRIMARY" == "true" ]]; then
    if ! docker info 2>/dev/null | grep -q "Swarm: active"; then
        echo "[INFO] Initializing swarm..."
        docker swarm init --advertise-addr "$ROLE_IP"
    fi

    mkdir -p /etc/swarm-bootstrap

    cat > "$NODES_JSON" <<EOF
{
  "managers": ["$ROLE_IP"],
  "workers": []
}
EOF

    echo "[INFO] Leader initialized"
else
    echo "[INFO] Waiting for leader discovery..."
fi
#!/bin/bash
set -e

NODE_ROLE="$1"
MANAGERS_CSV="$2"

IFS=',' read -ra MANAGERS <<< "$MANAGERS_CSV"

get_join_token() {
    ROLE="$1"

    for MANAGER in "${MANAGERS[@]}"; do
        if ssh -o ConnectTimeout=3 "$MANAGER" "docker info" >/dev/null 2>&1; then
            echo "[INFO] Using manager $MANAGER for token"
            ssh "$MANAGER" "docker swarm join-token -q $ROLE"
            return 0
        fi
    done

    echo "[ERROR] No reachable managers"
    exit 1
}

if [[ "$NODE_ROLE" == "manager" ]]; then

    if docker info 2>/dev/null | grep -q "Swarm: active"; then
        echo "[INFO] Already part of a swarm"
    else
        echo "[INFO] Attempting to join existing swarm..."

        TOKEN=$(get_join_token manager)

        for MANAGER in "${MANAGERS[@]}"; do
            docker swarm join --token "$TOKEN" "$MANAGER:2377" && break || true
        done || docker swarm init
    fi

else
    echo "[INFO] Joining as worker..."

    TOKEN=$(get_join_token worker)

    for MANAGER in "${MANAGERS[@]}"; do
        docker swarm join --token "$TOKEN" "$MANAGER:2377" && break || true
    done
fi

echo "[INFO] Swarm setup complete"
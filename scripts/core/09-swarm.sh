#!/bin/bash
set -e

CONFIG="/etc/swarm-bootstrap/config.json"

ROLE=$(jq -r .role "$CONFIG")
MANAGERS=$(jq -r '.managers[]' "$CONFIG")
MODE=$(jq -r .manager_mode "$CONFIG")
PRIORITY=$(jq -r .candidate_priority "$CONFIG")

get_token() {
    TYPE=$1
    for M in $MANAGERS; do
        if sudo -u swarmd ssh -i /home/swarmd/.ssh/id_rsa swarmd@"$M" "docker info" >/dev/null 2>&1; then
            sudo -u swarmd ssh -i /home/swarmd/.ssh/id_rsa swarmd@"$M" "docker swarm join-token -q $TYPE"
            return
        fi
    done
    exit 1
}

if [[ "$ROLE" == "manager" ]]; then
    docker info | grep -q "Swarm: active" || docker swarm init
else
    TOKEN=$(get_token worker)
    for M in $MANAGERS; do
        docker swarm join --token "$TOKEN" "$M:2377" && break || true
    done
fi

NODE_ID=$(docker info -f '{{.Swarm.NodeID}}')

if [[ "$ROLE" == "manager" && "$MODE" != "n/a" ]]; then
    docker node update --availability "$MODE" "$NODE_ID"
fi

if [[ "$ROLE" == "worker" && -n "$PRIORITY" ]]; then
    docker node update --label-add manager_candidate_priority="$PRIORITY" "$NODE_ID"
fi

echo "[INFO] Swarm configured"
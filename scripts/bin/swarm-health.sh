#!/bin/bash

CONFIG="/etc/swarm-bootstrap/config.json"
LOCK_FILE="/var/run/swarm-recovery.lock"

exec 200>$LOCK_FILE
flock -n 200 || exit 0

[[ ! -f "$CONFIG" ]] && exit 0

ROLE=$(jq -r .role "$CONFIG")
MANAGERS=$(jq -r '.managers[]' "$CONFIG")

# Rejoin if dropped
if ! docker info 2>/dev/null | grep -q "Swarm: active"; then
    echo "[WARN] Node not in swarm, attempting rejoin..."

    for MANAGER in $MANAGERS; do
        if ssh -o ConnectTimeout=3 "$MANAGER" "docker info" >/dev/null 2>&1; then
            TOKEN=$(ssh "$MANAGER" "docker swarm join-token -q $ROLE")
            docker swarm join --token "$TOKEN" "$MANAGER:2377" && break
        fi
    done
fi

# Only managers handle quorum
if [[ "$ROLE" != "manager" ]]; then
    exit 0
fi

[[ ! -f /etc/swarm-bootstrap/.initialized ]] && exit 0

TOTAL=$(docker node ls --filter role=manager -q | wc -l)
REACHABLE=$(docker node ls --format '{{.ManagerStatus}}' | grep -c Reachable || true)
QUORUM=$((TOTAL / 2 + 1))

if [[ "$REACHABLE" -lt "$QUORUM" ]]; then
    echo "[CRITICAL] Quorum at risk, promoting candidate..."

    docker node ls --filter role=worker --format '{{.ID}}' | while read ID; do
        PRIORITY=$(docker node inspect "$ID" \
            --format '{{ index .Spec.Labels "manager_candidate_priority" }}')

        if [[ -n "$PRIORITY" ]]; then
            echo "$PRIORITY $ID"
        fi
    done | sort -n | head -1 | while read PRIORITY NODE_ID; do
        STATE=$(docker node inspect "$NODE_ID" --format '{{.Status.State}}')

        if [[ "$STATE" == "ready" ]]; then
            docker node promote "$NODE_ID"
            echo "[INFO] Promoted node $NODE_ID"
        fi
    done
fi
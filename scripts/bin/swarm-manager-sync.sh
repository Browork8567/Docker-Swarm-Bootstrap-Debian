#!/bin/bash
set -e

echo "[INFO] Running manager sync..."

# Only run on leader
IS_LEADER=$(docker node ls 2>/dev/null | grep Leader || true)

if [[ -z "$IS_LEADER" ]]; then
    echo "[INFO] Not leader, skipping..."
    exit 0
fi

MANAGERS=$(docker node ls --format '{{.Hostname}} {{.Status}} {{.ManagerStatus}}' | \
    awk '$3 ~ /Leader|Reachable/ {print $1}')

WORKERS=$(docker node ls --format '{{.Hostname}} {{.Status}} {{.ManagerStatus}}' | \
    awk '$3 == "" {print $1}')

MANAGER_COUNT=$(echo "$MANAGERS" | wc -l)

# ✅ MEDIUM FIX 6 — CORRECT PLACEMENT
if [[ "$MANAGER_COUNT" -lt 1 ]]; then
    echo "[WARN] No managers detected, skipping sync"
    exit 0
fi

mkdir -p /etc/swarm-bootstrap

# Build JSON arrays
MANAGER_JSON=$(printf '%s\n' $MANAGERS | jq -R . | jq -s .)
WORKER_JSON=$(printf '%s\n' $WORKERS | jq -R . | jq -s .)

cat > /etc/swarm-bootstrap/nodes.json <<EOF
{
  "managers": $MANAGER_JSON,
  "workers": $WORKER_JSON
}
EOF

echo "[INFO] nodes.json updated"
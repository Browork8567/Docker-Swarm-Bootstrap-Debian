#!/usr/bin/env bash
set -euo pipefail

echo "[INFO] Installing swarm-node-init.sh..."

SRC="scripts/bin/swarm-node-init.sh"
DEST="/usr/local/bin/swarm-node-init.sh"

if [[ ! -f "$SRC" ]]; then
    echo "[ERROR] Missing $SRC"
    exit 1
fi

# Copy script
cp "$SRC" "$DEST"

# Set permissions
chmod 700 "$DEST"
chown root:root "$DEST"

echo "[INFO] Installed swarm-node-init.sh to $DEST"
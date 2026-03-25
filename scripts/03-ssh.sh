#!/bin/bash
set -e

MANAGERS_CSV="$1"
IFS=',' read -ra MANAGERS <<< "$MANAGERS_CSV"

echo "[INFO] Setting up SSH trust..."

if [[ ! -f "$HOME/.ssh/id_rsa" ]]; then
    ssh-keygen -t rsa -N "" -f "$HOME/.ssh/id_rsa"
fi

for MANAGER in "${MANAGERS[@]}"; do
    echo "[INFO] Copying SSH key to $MANAGER"
    ssh-copy-id -o StrictHostKeyChecking=no "$MANAGER" || true
done

echo "[INFO] SSH trust setup complete"
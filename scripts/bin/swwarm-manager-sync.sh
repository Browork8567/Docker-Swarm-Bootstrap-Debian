#!/bin/bash

CONFIG="/etc/swarm-bootstrap/config.json"

ROLE=$(jq -r .role "$CONFIG")

[[ "$ROLE" != "manager" ]] && exit 0

MANAGERS=$(jq -r '.managers[]' "$CONFIG")

for TARGET in $MANAGERS; do
    scp -o ConnectTimeout=3 "$CONFIG" "$TARGET:$CONFIG" >/dev/null 2>&1 || true
done
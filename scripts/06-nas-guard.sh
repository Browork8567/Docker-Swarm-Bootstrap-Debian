#!/usr/bin/env bash
set -euo pipefail

source /opt/swarm-secure/config.env

LOG="/var/log/nas-guard.log"

log(){ echo "$(date) $1" >> "$LOG"; }

if ! mountpoint -q /data; then
  log "Mount missing, attempting remount"
  mount -a || log "Remount failed"
fi

touch /data/.healthcheck 2>/dev/null || log "Write failed"

exit 0
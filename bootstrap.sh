#!/usr/bin/env bash
set -euo pipefail

echo "[INFO] Secure Swarm Bootstrap Starting..."

if [ "$EUID" -ne 0 ]; then
  echo "Run as root (sudo)"
  exit 1
fi

CONFIG_FILE="./config/config.env"

if [ ! -f "$CONFIG_FILE" ]; then
  echo "[ERROR] Missing config.env (copy from example)"
  exit 1
fi

source "$CONFIG_FILE"

chmod +x scripts/*.sh

run_step() {
  echo ""
  echo "========== $1 =========="
  sleep 2
  bash "$2"
}

run_step "Base System" scripts/01-base.sh
run_step "Docker" scripts/02-docker.sh
run_step "SSH" scripts/03-ssh.sh
run_step "Firewall" scripts/04-ufw.sh
run_step "NAS" scripts/05-nas.sh
run_step "NAS Guard" scripts/06-nas-guard.sh
run_step "Swarm" scripts/07-swarm.sh
run_step "Hardening" scripts/08-hardening.sh

echo ""
echo "======================================="
echo "[OK] SYSTEM FULLY BOOTSTRAPPED (SECURE)"
echo "======================================="
echo ""
echo "NEXT:"
echo "1. logout/login OR run: newgrp docker"
echo "2. ssh-copy-id $CURRENT_USER@$MGR1_HOST"
echo "3. sudo systemctl start swarm-auto.service"
echo "4. docker node ls"

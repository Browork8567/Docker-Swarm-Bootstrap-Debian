#!/usr/bin/env bash
set -euo pipefail

CURRENT_USER=$(logname 2>/dev/null || echo "${SUDO_USER:-$USER}")

#######################################
# INIT
#######################################

cat << 'EOF' > /usr/local/bin/swarm-init.sh
#!/usr/bin/env bash
set -euo pipefail

if docker info | grep -q "Swarm: active"; then exit 0; fi

IP=$(hostname -I | awk '{print $1}')

docker swarm init --advertise-addr "$IP"

echo "[INFO] Creating Docker secrets store..."

docker secret create example_secret - <<EOF2
supersecretvalue
EOF2
EOF

#######################################
# JOIN
#######################################

cat << EOF > /usr/local/bin/swarm-join.sh
#!/usr/bin/env bash
set -euo pipefail

ROLE="\${1:-worker}"

while true; do
  if ssh -o BatchMode=yes $CURRENT_USER@$MGR1_HOST docker info >/dev/null 2>&1; then

    TOKEN=\$(ssh $CURRENT_USER@$MGR1_HOST docker swarm join-token -q \$ROLE)

    docker swarm join --token "\$TOKEN" "$MGR1_IP:2377"
    break
  fi

  sleep 3
done
EOF

#######################################
# SERVICE
#######################################

cat << 'EOF' > /etc/systemd/system/swarm-auto.service
[Unit]
Description=Swarm Auto Join
After=docker.service network-online.target

[Service]
Type=oneshot
ExecStart=/usr/local/bin/swarm-role.sh
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF

chmod +x /usr/local/bin/swarm-*.sh
systemctl daemon-reload
systemctl enable swarm-auto.service
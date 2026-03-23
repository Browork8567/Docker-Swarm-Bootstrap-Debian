# Debian-13-Docker-Swarm-Secure-Deployment-

#Description

Hi! I have been working in my homelab to migrate to docker swarm. As I moved through the process i had multiple scripts written and kept a security first posture in mind. Ai was used to write the scripts, as it is much faster than i ever will be at writing them, but I directed the architecture and kept it limited in scope. I double checked function and debugged each step along the way. I thought this was really cool and wanted to share. 

This is my first time publishing to github so if the repo is a little weird, I appologize and I am eternally greatful for any help. :) 



# Secure Docker Swarm Bootstrap

## Features
- Hardened Debian baseline
- Docker Swarm auto-cluster
- SSH key-based auth only
- UFW locked down
- Docker secrets enabled
- NAS optional (secure input)
- Fail2ban protection

## Setup

1. Clone repo
2. Copy config:
   cp config/config.env.example config/config.env
3. Edit values
4. Run:
   sudo bash bootstrap.sh

## Post Install

ssh-copy-id user@mgr-01

sudo systemctl start swarm-auto.service

docker node ls

## Security Model

- No plaintext credentials
- No open LAN firewall
- SSH locked down
- Secrets stored in Docker
- Swarm ports internal only

## WARNING

Docker group = root access.
Treat nodes as trusted.

#!/bin/sh
echo "Initializing Alpine..."

# --- System & Repos ---
VERSION=$(cut -d'.' -f1,2 /etc/alpine-release)
cat > /etc/apk/repositories << EOF
https://dl-cdn.alpinelinux.org/alpine/v${VERSION}/main
https://dl-cdn.alpinelinux.org/alpine/v${VERSION}/community
EOF
apk update && apk add nano curl net-tools iptables dnsmasq docker docker-compose git

# --- Docker Log Limits ---
mkdir -p /etc/docker
cat > /etc/docker/daemon.json << EOF
{
  "log-driver": "json-file",
  "log-opts": { "max-size": "10m", "max-file": "3" }
}
EOF

# --- Services & Persistence ---
rc-update add docker boot
service docker restart
lbu commit -d

echo "Alpine init complete"

#!/bin/sh

set -e

echo "Loading tun module..."
modprobe tun

if [ ! -e /dev/net/tun ]; then
  echo "Creating /dev/net/tun device node..."
  mkdir -p /dev/net
  mknod /dev/net/tun c 10 200
  chmod 600 /dev/net/tun
fi

echo "/dev/net/tun is ready."

if ! grep -qx "tun" /etc/modules 2>/dev/null; then
  echo "Adding tun to /etc/modules for persistence..."
  echo "tun" >> /etc/modules
fi

echo "Host is ready. You can now run: docker-compose up -d"

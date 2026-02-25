#!/bin/sh
# host-init/common/wg_utils.sh
# Reusable WireGuard gateway utilities

set -e

# ----------------------------------------------------
# Helper: Get the default gateway IP
# ----------------------------------------------------
wg_get_host_ip() {
  ip route show | grep default | awk '{print $3}'
}

# ----------------------------------------------------
# Configure the wg0 interface from a config file.
#   $1 - path to wg0.conf
#   $2 - local IP address to assign to wg0 (e.g. 10.8.0.12/24)
# ----------------------------------------------------
wg_setup_interface() {
  local config="$1"
  local local_ip="$2"
  local wg_if="wg0"

  ip link delete dev "$wg_if" 2>/dev/null || true
  ip link add dev "$wg_if" type wireguard
  wg setconf "$wg_if" "$config"
  ip address add "$local_ip" dev "$wg_if"
  ip link set mtu 1420 up dev "$wg_if"
}

# ----------------------------------------------------
# Set up NAT/forwarding rules for a WG gateway.
#   $1 - outbound interface (e.g. eth0)
#   $2 - optional WG interface name (default wg0)
# ----------------------------------------------------
wg_setup_nat() {
  local eth_out="$1"
  local wg_if="${2:-wg0}"

  iptables -F
  iptables -t nat -F
  iptables -t nat -A PREROUTING -i "$wg_if" -p tcp --dport 22 -j DNAT \
    --to-destination "$(wg_get_host_ip):22"
  iptables -t nat -A POSTROUTING -o "$eth_out" -j MASQUERADE
  iptables -A FORWARD -i "$wg_if" -o "$eth_out" -j ACCEPT
  iptables -A FORWARD -i "$eth_out" -o "$wg_if" -m state --state RELATED,ESTABLISHED -j ACCEPT
}

# ----------------------------------------------------
# Start a background loop that always re‑resolves DNS and
# forces a WireGuard endpoint update every 120 seconds.
#   $1 - path to wg0.conf
# ----------------------------------------------------
wg_dns_resolver_loop() {
  local config="$1"
  local wg_if="wg0"

  (
    while true; do
      sleep 120

      # Re‑extract the peer key and endpoint from the config on each iteration.
      local peer_key
      local endpoint

      peer_key=$(grep -i "^PublicKey" "$config" | cut -d '=' -f 2- | tr -d ' ' | tr -d '\r')
      endpoint=$(grep -i "^Endpoint" "$config" | cut -d '=' -f 2- | tr -d ' ' | tr -d '\r')

      echo "$(date): Re‑resolving endpoint $endpoint..."

      local backoff=1
      local max_backoff=60
      local attempts=0
      local max_attempts=10

      while [ $attempts -lt $max_attempts ]; do
        if wg set "$wg_if" peer "$peer_key" endpoint "$endpoint"; then
          break
        else
          jitter=$((RANDOM % 2))
          sleep_time=$((backoff + jitter))
          echo "$(date): reconnect attempt $((attempts+1)) failed. Backing off ${sleep_time}s…"
          sleep "$sleep_time"
          attempts=$((attempts + 1))
          backoff=$((backoff * 2))
          [ "$backoff" -gt "$max_backoff" ] && backoff=$max_backoff
        fi
      done

      if [ $attempts -eq $max_attempts ]; then
        echo "$(date): All ${max_attempts} reconnect attempts failed. Exiting."
        exit 1
      fi
    done
  ) &
}

# ----------------------------------------------------
# End of common WireGuard gateway utilities
# ----------------------------------------------------

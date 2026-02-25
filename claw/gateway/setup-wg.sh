#!/bin/sh
set -e

source "/app/common/wg_utils.sh"

# --------------------------------------------------------------------
# Configuration
# --------------------------------------------------------------------
WG_CONF="/etc/wireguard/wg0.conf"
LOCAL_IP="10.10.0.3/24"

# --------------------------------------------------------------------
# Setup the WireGuard interface
# --------------------------------------------------------------------
wg_setup_interface "$WG_CONF" "$LOCAL_IP"

# --------------------------------------------------------------------
# Configure NAT, forwarding, and basic DNAT rules
# --------------------------------------------------------------------
wg_setup_nat eth0
iptables -t nat -A PREROUTING -i wg0 -p tcp --dport 22 -j DNAT --to-destination "$(wg_get_host_ip):22"

echo "Gateway operational. Host: $(wg_get_host_ip)"

# --------------------------------------------------------------------
# Start the DNS re‑resolution loop
# --------------------------------------------------------------------
wg_dns_resolver_loop "$WG_CONF"

# --------------------------------------------------------------------
# Keep the container alive
# --------------------------------------------------------------------
tail -f /dev/null

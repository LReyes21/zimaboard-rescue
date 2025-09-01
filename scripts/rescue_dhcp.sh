#!/usr/bin/env bash
# Start a temporary DHCP server on a given interface to rescue a directly-connected device.
# Usage: sudo ./rescue_dhcp.sh enx9cebe869e600 192.168.100.1
set -euo pipefail
IFACE=${1:-enx9cebe869e600}
SERVER_IP=${2:-192.168.100.1}
RANGE_START=${3:-192.168.100.10}
RANGE_END=${4:-192.168.100.50}
CONF=/tmp/dnsmasq-rescue.conf

if [ "$EUID" -ne 0 ]; then
  echo "Run as root: sudo $0"; exit 1
fi

ip addr flush dev "$IFACE"
ip addr add "$SERVER_IP/24" dev "$IFACE"
ip link set "$IFACE" up

cat > "$CONF" <<EOF
interface=$IFACE
bind-interfaces
log-dhcp
dhcp-range=$RANGE_START,$RANGE_END,255.255.255.0,12h
dhcp-option=3,$SERVER_IP
dhcp-option=6,8.8.8.8
EOF

echo "Starting dnsmasq with $CONF"
dnsmasq --conf-file="$CONF" --no-daemon --log-dhcp &
DNSMASQ_PID=$!

echo "dnsmasq started (pid=$DNSMASQ_PID). Press Ctrl-C to stop and clean up."

trap 'echo "Stopping dnsmasq..."; kill $DNSMASQ_PID; ip addr flush dev "$IFACE"; exit 0' SIGINT SIGTERM

while true; do sleep 1; done

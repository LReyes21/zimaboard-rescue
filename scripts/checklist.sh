#!/usr/bin/env bash
# Interactive checklist to run common rescue steps and optionally record them in the DB.
set -euo pipefail
REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SCRIPTS="$REPO_ROOT/scripts"

echo "Rescue checklist — run steps as needed. Press ENTER to continue or Ctrl+C to cancel."

read -p "1) Ensure USB-C ethernet is connected and interface is up. Press ENTER when ready..." || true
ip -brief link | grep -E 'enx|eth' || true

read -p "2) (Optional) Start DHCP rescue on interface (runs dnsmasq). Enter interface name or leave blank to skip: " IFACE
if [[ -n "$IFACE" ]]; then
  sudo bash -c "$SCRIPTS/rescue_dhcp.sh $IFACE"
  echo "Started rescue DHCP (foreground). Ctrl+C to stop and continue checklist."
  read -p "Press ENTER after you stopped dnsmasq to continue..." || true
fi

read -p "3) Try SSH to last-known host (userver.local / 192.168.0.147). Press ENTER to run ping..." || true
ping -c 3 userver.local || ping -c 3 192.168.0.147 || true

read -p "4) Collect non-privileged diagnostics? [y/N] " yn
if [[ "$yn" =~ ^[Yy] ]]; then
  bash -c "$SCRIPTS/collect_diagnostics.sh userver.local > $REPO_ROOT/diagnostics/checklist_nonpriv.txt"
  echo "Saved: diagnostics/checklist_nonpriv.txt"
fi

read -p "5) Record this checklist run to DB? [y/N] " yn2
if [[ "$yn2" =~ ^[Yy] ]]; then
  read -p "Summary for record: " summary
  python3 "$SCRIPTS/add_record.py" --summary "$summary" --type checklist --details "Checklist run saved to diagnostics/checklist_nonpriv.txt" || true
fi

echo "Checklist complete."

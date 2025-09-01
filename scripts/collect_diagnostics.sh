#!/usr/bin/env bash
# Collect important diagnostics from a running Zimaboard (or similar) over SSH
# Usage: ./collect_diagnostics.sh luis@userver.local /path/to/output_dir
set -euo pipefail
TARGET=${1:-luis@userver.local}
OUTDIR=${2:-./diagnostics}
mkdir -p "$OUTDIR"

ssh -T "$TARGET" <<'EOF' > "$OUTDIR/remote_diagnostics.txt"
set -x
sudo efibootmgr -v || true
ls -la /boot/efi/EFI || true
cat /etc/default/grub || true
sudo grub-editenv list 2>/dev/null || true
sudo journalctl -b -1 --no-pager | sed -n '1,200p' || true
sudo dmidecode -t bios | sed -n '1,120p' || true
sudo parted -l || true
ip addr show || true
ip neigh show || true
lsusb || true
sudo ethtool $(ip -o link show | awk -F': ' '{print $2}' | head -n1) || true
EOF

echo "Diagnostics saved to $OUTDIR/remote_diagnostics.txt"

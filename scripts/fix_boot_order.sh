#!/usr/bin/env bash
# Fix UEFI BootOrder to prefer Ubuntu and make GRUB visible.
# Usage: sudo ./fix_boot_order.sh
set -euo pipefail

if [ "$EUID" -ne 0 ]; then
  echo "Run as root: sudo $0"; exit 1
fi

echo "Current efibootmgr entries:"
efibootmgr -v || true

# Find Ubuntu entry
UBUNTU_BOOT=$(efibootmgr -v | grep -i "ubuntu" | head -n1 | awk '{print $1}' | sed 's/Boot//' | sed 's/*//')
if [ -z "$UBUNTU_BOOT" ]; then
  echo "No Ubuntu EFI entry found. Abort."; exit 2
fi

echo "Ubuntu entry = $UBUNTU_BOOT"
# Construct new order: ubuntu, then others
OTHERS=$(efibootmgr | grep BootOrder | sed 's/BootOrder: //' | tr -d '\n' | sed 's/,$//' )
NEWORDER="$UBUNTU_BOOT,$(echo $OTHERS | sed "s/$UBUNTU_BOOT,//g")"

echo "Setting BootOrder to $NEWORDER"
efibootmgr -o $NEWORDER || true

echo "Making GRUB menu visible (timeout=5)"
sed -i 's/GRUB_TIMEOUT_STYLE=hidden/GRUB_TIMEOUT_STYLE=menu/' /etc/default/grub || true
sed -i 's/GRUB_TIMEOUT=0/GRUB_TIMEOUT=5/' /etc/default/grub || true
update-grub || true

echo "Reinstalling grub EFI as safety"
grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=ubuntu --recheck || true

echo "Done. Current boot entries:"
efibootmgr -v || true

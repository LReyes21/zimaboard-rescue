Zimaboard Rescue Playbook

This repository contains notes, scripts, and diagnostics collected during a live rescue session for a ZimaBoard 832 where the device dropped from WiFi and required recovery via USB-C Ethernet.

Structure:
- README.md - this file
- REPORT.md - timeline, root cause analysis, and recommended fixes
- scripts/
  - rescue_dhcp.sh - start a temporary DHCP server on a laptop to give the board an IP
  - collect_diagnostics.sh - collect UEFI/boot/firmware and network diagnostics from a running board
  - fix_boot_order.sh - set UEFI BootOrder to prefer Ubuntu, make GRUB visible, reinstall EFI bootloader

Usage notes:
- Run scripts as root or using sudo.
- Use `collect_diagnostics.sh` to gather logs before and after any changes.
- `rescue_dhcp.sh` binds a DHCP server to the USB-C Ethernet adapter and should be stopped when finished.

License: MIT

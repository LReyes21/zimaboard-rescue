Zimaboard Rescue Playbook

Goal: A concise decision tree for reconnecting a Zimaboard that drops from WiFi.

1) Initial checks (laptop connected via USB-C Ethernet adapter)
- Confirm laptop interface: `ip addr show` (look for `enx*`)
- Check physical link: `ethtool <iface>` -> expect `Link detected: yes` and `Speed: 1000Mb/s`

2) If link up but no IP / no DHCP
- Assume no DHCP server on that link.
- Option A: Set laptop static IP on the same subnet as expected board (e.g., 192.168.100.1) and run `rescue_dhcp.sh` to offer leases.
- Option B: Scan common private ranges for static IPs (192.168.0.x, 192.168.1.x, 192.168.10.x, 192.168.88.x)

3) If link up and board not responding to ARP/DHCP
- Power cycle the board for 30s.
- Re-check DHCP logs and tcpdump on laptop.

4) If board returns to WiFi
- Ping `userver.local` and SSH in.
- Run `collect_diagnostics.sh` to gather state.
- Check `efibootmgr -v` and `/etc/default/grub`.

5) If BootOrder changed or Ubuntu not first
- Run `fix_boot_order.sh` which sets BootOrder to Ubuntu, makes GRUB visible, reinstalls EFI.

6) If board will not boot
- Connect monitor+keyboard and check boot messages.
- Reinstall system from autoinstall if disk corruption suspected.

7) Post-rescue
- Save diagnostics to repo and document MACs and last-known IPs in `metadata.yml`.
- Store `rescue_dhcp.sh` on a USB stick for future rescues.

Notes:
- Use caution with `grub-install` and `efibootmgr` on multi-OS systems.
- Prefer interactive sudo (TTY) for privileged commands to avoid `sudo: a terminal is required` failures.

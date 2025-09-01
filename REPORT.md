Zimaboard Rescue Report

Date: 2025-08-31
Summary:
- Incident: Zimaboard (hostname userver.local) dropped from WiFi and became unreachable.
- Rescue steps: connected laptop via USB-C to Ethernet adapter (Realtek RTL8153), configured laptop as DHCP server, attempted to obtain lease, attempted network scans and ARP broadcasts, power-cycled Zimaboard, regained WiFi connectivity.

Root cause analysis:
- Observable symptoms: ethernet link detected (1Gbps), no DHCP requests from Zimaboard, no ARP responses, no network traffic.
- After power-cycling, the device reconnected to WiFi (192.168.0.147).
- Later, boot order was checked with `efibootmgr` and Ubuntu was present as Boot0000; GRUB was configured to hide the menu (GRUB_TIMEOUT=0), which could make initial boot appear immediate and mask transient boot-source changes.

Actions taken:
- Verified USB-C Ethernet adapter: `lsusb` and `ethtool` (link 1000Mb/s)
- Configured laptop static IP and ran `dnsmasq` as temporary DHCP server on `enx*` interface (192.168.100.1)
- Monitored logs (`/var/log/syslog`, `tcpdump`) for DHCP/ARP activity
- Performed power cycle of Zimaboard
- Confirmed WiFi: `ping userver.local` -> 192.168.0.147
- SSH into Zimaboard and ran diagnostics: `efibootmgr -v`, `ls /boot/efi/EFI`, `cat /etc/default/grub`, `journalctl -b -1`, `dmidecode`, `parted -l`
- Applied fixes: forced BootOrder to prefer Ubuntu (`efibootmgr -o 0000,0004,0003`), made GRUB visible (GRUB_TIMEOUT=5), reinstalled EFI bootloader with `grub-install`, rebooted, verified.

Recommendations:
- Keep GRUB menu visible (short timeout) for systems where boot source may change.
- Investigate firmware updates or power events that can reorder BootOrder.
- Document device MAC addresses and usual IPs.
- Keep a small USB-C to Ethernet adapter and rescue script on rescue laptop.

Files created during rescue:
- Temporary dhcp config: /tmp/dnsmasq-rescue.conf

Relevant commands (copyable):
# Basic diagnostics
sudo ethtool <iface>
lsusb
ip addr show
ip neigh show

# Start rescue DHCP server (example)
sudo ip addr add 192.168.100.1/24 dev <iface>
cat > /tmp/dnsmasq-rescue.conf <<'EOF'
interface=<iface>
bind-interfaces
dhcp-range=192.168.100.10,192.168.100.50,255.255.255.0,12h
log-dhcp
EOF
sudo dnsmasq --conf-file=/tmp/dnsmasq-rescue.conf --no-daemon --log-dhcp

# Collect diagnostics on board
ssh user@host "sudo efibootmgr -v; ls -la /boot/efi/EFI; cat /etc/default/grub; sudo journalctl -b -1 | sed -n '1,120p'"

# Fix boot order and GRUB
sudo efibootmgr -o 0000,0004,0003
sudo sed -i 's/GRUB_TIMEOUT_STYLE=hidden/GRUB_TIMEOUT_STYLE=menu/' /etc/default/grub
sudo sed -i 's/GRUB_TIMEOUT=0/GRUB_TIMEOUT=5/' /etc/default/grub
sudo update-grub
sudo grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=ubuntu --recheck


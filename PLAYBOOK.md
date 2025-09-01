# ZimaBoard Rescue Playbook

A systematic decision tree for recovering ZimaBoard devices that have lost network connectivity.

## 🎯 Objective

Restore network access to an unresponsive ZimaBoard device using USB-C Ethernet recovery and systematic troubleshooting procedures.

## ⚡ Quick Reference

**Emergency Commands:**
```bash
sudo scripts/rescue_dhcp.sh          # Start rescue DHCP server
scripts/collect_diagnostics.sh       # Gather system diagnostics  
sudo scripts/fix_boot_order.sh       # Repair boot configuration
```

## 📋 Step-by-Step Procedure

### 1. Initial Assessment

**Physical Connection:**
- Connect laptop to ZimaBoard via USB-C Ethernet adapter
- Verify physical link establishment

**Diagnostic Commands:**
```bash
ip addr show                         # Confirm laptop interface (look for enx*)
sudo ethtool <interface>             # Check physical link status
# Expected: "Link detected: yes" and "Speed: 1000Mb/s"
```

### 2. Network Recovery

#### Option A: DHCP Server Method (Recommended)
```bash
sudo scripts/rescue_dhcp.sh         # Provides DHCP on 192.168.100.0/24
sudo tcpdump -i <interface> port 67  # Monitor DHCP requests
```

#### Option B: Static IP Scanning
If DHCP fails, scan common private ranges:
```bash
# Set static IP and scan
sudo ip addr add 192.168.100.1/24 dev <interface>
nmap -sn 192.168.0.0/24             # Scan for devices
nmap -sn 192.168.1.0/24
nmap -sn 192.168.10.0/24
```

### 3. Device Recovery

#### If No Response to Network Attempts:
1. **Power cycle** the ZimaBoard (30-second power-off)
2. Re-monitor DHCP logs and network traffic
3. Check for WiFi reconnection: `ping userver.local`

#### If WiFi Connectivity Restored:
```bash
ssh user@userver.local              # Establish SSH connection
scripts/collect_diagnostics.sh      # Gather diagnostic information
```

### 4. Boot Configuration Analysis

**Check Boot Status:**
```bash
sudo efibootmgr -v                  # Verify boot order
cat /etc/default/grub               # Check GRUB configuration
sudo journalctl -b -1               # Review previous boot logs
```

**Common Issues to Look For:**
- Ubuntu not first in boot order
- GRUB timeout set to 0 (hidden menu)
- Missing or corrupted EFI entries

### 5. Apply Fixes

**If Boot Order Issues Detected:**
```bash
sudo scripts/fix_boot_order.sh      # Comprehensive boot repair
# This script will:
# - Set Ubuntu as primary boot option
# - Make GRUB menu visible (5-second timeout)
# - Reinstall EFI bootloader
# - Verify configuration
```

### 6. Persistent Boot Issues

**If Device Won't Boot Properly:**
- Connect monitor and keyboard for direct console access
- Check boot messages for hardware errors
- Consider system reinstall if disk corruption suspected

### 7. Post-Recovery Documentation

**Update Records:**
```bash
python3 scripts/add_record.py \
  --source "ZimaBoard-832" \
  --type "network-recovery" \
  --summary "WiFi connectivity restored" \
  --details "USB-C Ethernet recovery successful, boot order repaired"
```

**Update Device Inventory:**
- Document new IP addresses in `docs/device-inventory.md`
- Save diagnostic outputs to `diagnostics/` directory
- Update `metadata.yml` with current device status

## ⚠️ Safety Considerations

- **Boot Commands**: Use caution with `grub-install` and `efibootmgr` on multi-OS systems
- **Privilege Escalation**: Prefer interactive sudo (TTY) for privileged commands
- **Network Isolation**: Ensure rescue network doesn't conflict with existing infrastructure
- **Power Cycling**: Allow adequate time for complete power-off (30+ seconds)

## 🔧 Troubleshooting Common Issues

### DHCP Server Won't Start
```bash
sudo systemctl stop systemd-networkd  # Stop conflicting services
sudo killall dnsmasq                  # Kill existing instances
sudo scripts/rescue_dhcp.sh           # Retry
```

### USB-C Adapter Not Recognized
```bash
lsusb                                 # Verify adapter detection
dmesg | tail                          # Check kernel messages
sudo modprobe cdc_ether               # Load Ethernet CDC driver
```

### SSH Connection Refused
```bash
nmap -p 22 <target_ip>               # Check SSH service
telnet <target_ip> 22                # Test connectivity
ssh -v user@<target_ip>              # Verbose connection attempt
```

## 📚 Related Documentation

- [Device Inventory](docs/device-inventory.md) - MAC addresses and network references
- [Incident Analysis](docs/incident-analysis.md) - Detailed analysis of previous rescue
- [Scripts README](scripts/README.md) - Individual script documentation

---

*Keep this playbook accessible during emergency situations. Consider printing a copy or storing on a rescue USB drive.*

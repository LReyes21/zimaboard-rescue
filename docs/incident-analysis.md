# ZimaBoard Rescue - Incident Analysis

**Date**: 2025-08-31  
**Device**: ZimaBoard 832 (hostname: `userver.local`)  
**Issue**: Device dropped from WiFi and became unreachable  
**Resolution**: USB-C Ethernet recovery and boot order repair  

## Executive Summary

The ZimaBoard experienced a WiFi connectivity loss, requiring emergency recovery via USB-C Ethernet adapter. The rescue involved network troubleshooting, temporary DHCP server setup, and subsequent boot order configuration to prevent future issues.

## Incident Timeline

### Initial Problem
- **Symptom**: Device `userver.local` became unreachable via WiFi
- **Connectivity**: No response to ping, SSH timeouts
- **Physical Access**: Not available (headless device)

### Recovery Steps

1. **Physical Connection Established**
   - Connected laptop to ZimaBoard via USB-C Ethernet adapter (Realtek RTL8153)
   - Verified adapter: `lsusb` and `ethtool` confirmed 1Gbps link

2. **Network Recovery Setup**
   - Configured laptop static IP: `192.168.100.1/24`
   - Started temporary DHCP server using `dnsmasq`
   - Monitored for DHCP requests and ARP activity

3. **Device Recovery**
   - Initial network attempts: No DHCP requests detected
   - **Power cycle performed**: Device rebooted successfully
   - WiFi connectivity restored: Device reappeared at `192.168.0.147`

4. **Preventive Maintenance**
   - SSH access established for diagnostics
   - Boot order analysis using `efibootmgr -v`
   - GRUB configuration review

## Root Cause Analysis

### Observable Symptoms
- Ethernet link established (1Gbps) but no network communication
- No DHCP requests from ZimaBoard on USB-C Ethernet
- No ARP responses to broadcast attempts
- Power cycle resolved WiFi connectivity immediately

### Contributing Factors
1. **Boot Configuration Issues**:
   - GRUB timeout set to 0 (hidden menu)
   - Potential boot order instability
   - Could mask transient boot failures

2. **Network State Issues**:
   - Possible WiFi driver/firmware hang
   - Network stack may have required reset

## Resolution Actions

### Immediate Fixes Applied
1. **Boot Order Stabilization**:
   ```bash
   sudo efibootmgr -o 0000,0004,0003  # Force Ubuntu as primary
   ```

2. **GRUB Visibility**:
   ```bash
   sudo sed -i 's/GRUB_TIMEOUT=0/GRUB_TIMEOUT=5/' /etc/default/grub
   sudo update-grub
   ```

3. **EFI Bootloader Reinstall**:
   ```bash
   sudo grub-install --target=x86_64-efi --efi-directory=/boot/efi
   ```

4. **Verification Reboot**:
   - Confirmed GRUB menu appears
   - Verified Ubuntu boots correctly

## Prevention Recommendations

### Configuration Changes
- ✅ Keep GRUB menu visible (5-second timeout)
- ✅ Ensure stable boot order preference
- 🔄 Monitor firmware updates that may affect boot configuration

### Emergency Preparedness
- ✅ Keep USB-C Ethernet adapter readily available
- ✅ Document MAC addresses for device identification
- ✅ Maintain rescue scripts and procedures
- 🔄 Test rescue procedures periodically

### Monitoring
- 🔄 Implement uptime monitoring for early detection
- 🔄 Log boot events for pattern analysis
- 🔄 Document power events and correlate with connectivity issues

## Technical References

### Diagnostic Commands Used
```bash
# Network adapter verification
sudo ethtool <interface>
lsusb
ip addr show
ip neigh show

# Boot diagnostics
sudo efibootmgr -v
ls -la /boot/efi/EFI
cat /etc/default/grub
sudo journalctl -b -1

# System information
sudo dmidecode
sudo parted -l
```

### Rescue Network Configuration
```bash
# Temporary DHCP server setup
sudo ip addr add 192.168.100.1/24 dev <interface>
cat > /tmp/dnsmasq-rescue.conf <<'EOF'
interface=<interface>
bind-interfaces
dhcp-range=192.168.100.10,192.168.100.50,255.255.255.0,12h
log-dhcp
EOF
sudo dnsmasq --conf-file=/tmp/dnsmasq-rescue.conf --no-daemon
```

## Lessons Learned

1. **Power cycling can resolve network stack issues** that don't respond to software intervention
2. **Boot configuration stability is critical** for headless devices
3. **USB-C Ethernet adapters provide reliable emergency access** when WiFi fails
4. **Comprehensive logging and documentation** enable faster future recoveries
5. **Preventive maintenance** (visible boot menu, stable boot order) reduces incident probability

## Files Generated During Rescue

- `/tmp/dnsmasq-rescue.conf` - Temporary DHCP configuration
- System diagnostics captured via SSH
- Network monitoring logs (`tcpdump`, `syslog`)

---

*This analysis serves as both incident documentation and template for future rescue operations.*

# Fix boot order and GRUB
sudo efibootmgr -o 0000,0004,0003
sudo sed -i 's/GRUB_TIMEOUT_STYLE=hidden/GRUB_TIMEOUT_STYLE=menu/' /etc/default/grub
sudo sed -i 's/GRUB_TIMEOUT=0/GRUB_TIMEOUT=5/' /etc/default/grub
sudo update-grub
sudo grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=ubuntu --recheck


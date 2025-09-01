# Device Inventory & Network Reference

This document tracks device identifiers, MAC addresses, and network information for rescue operations.

## Target Device: ZimaBoard 832

### Network Interfaces
- **WiFi Interface**: `wlp1s0`
  - MAC Address: `dc:97:ba:3c:31:c9`
  - Last Known IP: `192.168.0.147`
  - SSID: [Network Name]

- **Ethernet Interface**: `enp2s0` (built-in)
  - MAC Address: [To be documented]
  - Used for: USB-C Ethernet recovery

### Device Specifications
- **Model**: ZimaBoard 832
- **Hostname**: `userver.local`
- **OS**: Ubuntu 24.04 LTS
- **Architecture**: x86_64

## Rescue Equipment

### Laptop (Rescue Station)
- **USB-C Ethernet Adapter**: Realtek RTL8153
  - Interface: `enx9cebe869e600`
  - MAC Address: `9c:eb:e8:69:e6:00`
  - Speed: 1000Mbps

- **WiFi Interface**: `wlp0s20f3`
  - MAC Address: `dc:21:5c:30:08:04`

### Network Infrastructure
- **Router/Gateway**: 
  - IP Address: `192.168.0.1`
  - MAC Address: `1c:3b:f3:78:7f:b8`
  - Network Range: `192.168.0.0/24`

## Usage Notes

- Keep these MAC addresses for quick device identification in:
  - Router admin interfaces
  - ARP tables (`ip neigh show`)
  - DHCP client lists
  
- Update IP addresses after successful recovery sessions

- Use this reference during network troubleshooting and device identification

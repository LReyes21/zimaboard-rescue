# ZimaBoard Rescue Repository

This repository was created from the [ZimaBoard Rescue Template](https://github.com/LReyes21/zimaboard-rescue).

## Quick Setup

1. **Update device information**:
   ```bash
   # Edit metadata.yml with your device details
   vim metadata.yml
   ```

2. **Install dependencies**:
   ```bash
   # Ubuntu/Debian
   sudo apt update
   sudo apt install python3 python3-pip shellcheck dnsmasq
   pip3 install flake8
   ```

3. **Initialize your first record**:
   ```bash
   python3 scripts/add_record.py \
     --source "YourDevice" \
     --type "setup" \
     --summary "Repository initialized" \
     --details "Created rescue repository from template"
   ```

4. **Generate dashboard**:
   ```bash
   python3 scripts/generate_dashboard.py
   # View: open dashboard/index.html
   ```

## Repository Structure

- `metadata.yml` - Your device configuration and network details
- `PLAYBOOK.md` - Step-by-step rescue procedures
- `scripts/` - Rescue automation scripts
- `diagnostics/` - Collected system diagnostics (add your own)
- `data/` - SQLite database for rescue records
- `dashboard/` - Generated HTML dashboard (auto-created)
- `docs/` - Documentation and incident reports

## Emergency Procedures

For immediate rescue operations, see [PLAYBOOK.md](PLAYBOOK.md).

**Quick Commands:**
```bash
sudo scripts/rescue_dhcp.sh          # Emergency DHCP server
scripts/collect_diagnostics.sh       # Gather diagnostics
sudo scripts/fix_boot_order.sh       # Repair boot issues
```

## Documentation

Customize these files for your specific environment:
- Update device MAC addresses in `metadata.yml`
- Document your network topology in `docs/device-inventory.md`
- Record incidents in detail using `scripts/add_record.py`

## GitHub Pages (Optional)

If you want a live dashboard:
1. Enable GitHub Pages in repository settings
2. Set source to "GitHub Actions"
3. The dashboard will auto-deploy on each push

---

*Remove this template README and replace with project-specific documentation as needed.*

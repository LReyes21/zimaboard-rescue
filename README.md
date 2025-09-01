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

# zimaboard-rescue (template)

![CI](https://github.com/LReyes21/zimaboard-rescue/actions/workflows/ci.yml/badge.svg)
![Pages](https://github.com/LReyes21/zimaboard-rescue/actions/workflows/pages.yml/badge.svg)

This repository is a proof-of-concept rescue & experiment template.

Useful links
- Repository: https://github.com/LReyes21/zimaboard-rescue
- GitHub Pages (dashboard): https://lreyes21.github.io/zimaboard-rescue/  # may take a minute after first deploy

Use as a template
- In the GitHub web UI click "Use this template" to create a new project repo.
- Or create from the CLI (after `gh auth login`) with:

```bash
gh repo create YOURUSER/zimaboard-rescue-example --template LReyes21/zimaboard-rescue --public
```

Quick start
1. Install dependencies for development:
  - Python 3.11+ and pip
  - Shell utilities: bash, dnsmasq (if using rescue DHCP), shellcheck (for linting)
2. Generate a record:

```bash
python3 scripts/add_record.py --source Zimaboard --type diagnostic --summary "Example" --details-file diagnostics/remote_privileged.txt
```

3. Generate the dashboard locally:

```bash
python3 scripts/generate_dashboard.py
# open dashboard/index.html
```

Publishing
- The repo is configured as a GitHub template and has a Pages workflow that publishes `dashboard/` to GitHub Pages.

Contributing
- CI runs shellcheck and flake8; fix lint errors before opening a PR.

# ZimaBoard Rescue Template

[![CI](https://github.com/LReyes21/zimaboard-rescue/actions/workflows/ci.yml/badge.svg)](https://github.com/LReyes21/zimaboard-rescue/actions/workflows/ci.yml)
[![Pages](https://github.com/LReyes21/zimaboard-rescue/actions/workflows/pages.yml/badge.svg)](https://github.com/LReyes21/zimaboard-rescue/actions/workflows/pages.yml)
[![Dashboard](https://img.shields.io/badge/Dashboard-Live-blue)](https://lreyes21.github.io/zimaboard-rescue/)

A comprehensive template for documenting and automating rescue procedures for ZimaBoard devices, with automated dashboard generation and CI/CD pipeline.

## 🚀 Features

- **Automated Rescue Scripts**: USB-C Ethernet recovery, DHCP server setup, and boot repair
- **Interactive Dashboard**: Live HTML dashboard showing rescue records and timeline
- **Template Repository**: Easy to use as a GitHub template for your own rescue scenarios
- **CI/CD Pipeline**: Automated linting, testing, and GitHub Pages deployment
- **Comprehensive Documentation**: Step-by-step playbooks and troubleshooting guides

## 📊 Live Dashboard

View the live dashboard at: **https://lreyes21.github.io/zimaboard-rescue/**

The dashboard automatically updates with each repository change and shows:
- Rescue session records with timestamps
- Device information and network details
- Links to detailed incident reports

## 🛠️ Quick Start

### Use as Template

Create your own rescue repository:

```bash
# Via GitHub CLI
gh repo create YOUR-USERNAME/my-rescue-repo --template LReyes21/zimaboard-rescue --public

# Or click "Use this template" on GitHub
```

### Local Development

1. **Clone and setup**:
   ```bash
   git clone https://github.com/YOUR-USERNAME/your-rescue-repo.git
   cd your-rescue-repo
   ```

2. **Install dependencies**:
   ```bash
   # Ubuntu/Debian
   sudo apt update
   sudo apt install python3 python3-pip shellcheck dnsmasq

   # Python packages
   pip3 install flake8
   ```

3. **Initialize project**:
   ```bash
   python3 scripts/add_record.py --init-project
   ```

4. **Add your first rescue record**:
   ```bash
   python3 scripts/add_record.py \
     --source "my-device" \
     --type "network-issue" \
     --summary "Device lost WiFi connection" \
     --details "Device became unreachable, used USB-C Ethernet for recovery"
   ```

5. **Generate dashboard**:
   ```bash
   python3 scripts/generate_dashboard.py
   # View: open dashboard/index.html in browser
   ```

## 📚 Documentation

| Document | Description |
|----------|-------------|
| [PLAYBOOK.md](PLAYBOOK.md) | Step-by-step rescue procedures |
| [docs/incident-analysis.md](docs/incident-analysis.md) | Detailed analysis from real rescue session |
| [docs/device-inventory.md](docs/device-inventory.md) | Device MACs, IPs, and hardware references |
| [CHANGELOG.md](CHANGELOG.md) | Version history and updates |
| [CONTRIBUTING.md](CONTRIBUTING.md) | How to contribute improvements |

## 🔧 Available Scripts

| Script | Purpose |
|--------|---------|
| `rescue_dhcp.sh` | Start temporary DHCP server via USB-C Ethernet |
| `collect_diagnostics.sh` | Gather system diagnostics remotely |
| `fix_boot_order.sh` | Repair UEFI boot order and GRUB configuration |
| `add_record.py` | Add rescue session records to database |
| `generate_dashboard.py` | Create HTML dashboard from records |

## 🏗️ Repository Structure

```
├── scripts/           # Rescue automation scripts
├── dashboard/         # Generated HTML dashboard (auto-created)
├── data/             # SQLite database for rescue records
├── diagnostics/      # Collected system diagnostics
├── template/         # Templates for new rescue repos
├── .github/workflows/ # CI/CD automation
└── docs/             # Additional documentation
```

## 🚨 Emergency Rescue Procedure

1. **Physical Connection**: Connect laptop to ZimaBoard via USB-C Ethernet adapter
2. **Network Setup**: Run `sudo scripts/rescue_dhcp.sh` to provide DHCP
3. **Diagnostics**: Use `scripts/collect_diagnostics.sh` to gather system info
4. **Boot Repair**: Apply `scripts/fix_boot_order.sh` if needed
5. **Documentation**: Record session with `scripts/add_record.py`

See [PLAYBOOK.md](PLAYBOOK.md) for detailed procedures.

## 🔄 Automation

The repository includes GitHub Actions workflows:

- **CI Pipeline**: Lints scripts, runs smoke tests
- **Pages Deployment**: Automatically deploys dashboard to GitHub Pages
- **Template Validation**: Ensures repository works as a template

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/improvement`
3. Make changes and run tests: `python3 scripts/generate_dashboard.py`
4. Commit with clear messages: `git commit -m "Add: new rescue feature"`
5. Push and create a Pull Request

See [CONTRIBUTING.md](CONTRIBUTING.md) for detailed guidelines.

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🏷️ Tags

`zimaboard` `rescue` `recovery` `network` `automation` `template` `dashboard` `github-pages`

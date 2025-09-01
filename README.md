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

### System Requirements

- **Operating System**: Ubuntu 20.04+ or Debian 11+
- **Python**: Python 3.8+
- **Privileges**: sudo access for network tools and rescue operations
- **Storage**: ~100MB for dependencies, ~50MB for project files
- **Network**: Internet access for package installation

### Prerequisites

This template requires several system packages and Python tools. Choose your setup method:

#### Option 1: Automated Setup (Recommended)

```bash
# Clone your repository
git clone https://github.com/YOUR-USERNAME/your-rescue-repo.git
cd your-rescue-repo

# Run automated setup
sudo scripts/setup-prerequisites.sh

# Verify installation
scripts/verify-setup.sh
```

#### Option 2: Manual Setup

<details>
<summary>Click to expand manual installation steps</summary>

```bash
# Update system packages
sudo apt update

# Install core system packages
sudo apt install -y \
  python3 python3-dev python3-pip python3-venv \
  shellcheck \
  dnsmasq \
  git \
  curl \
  tcpdump \
  arping \
  nmap \
  ethtool \
  net-tools \
  iputils-ping

# Install Python linting tools
sudo apt install -y python3-flake8

# Optional: Install GitHub CLI
curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
sudo apt update
sudo apt install gh
```

</details>

### Use as Template

Create your own rescue repository:

```bash
# Via GitHub CLI
gh repo create YOUR-USERNAME/my-rescue-repo --template LReyes21/zimaboard-rescue --public

# Or click "Use this template" on GitHub
```

### Local Development

1. **Clone your repository**:
   ```bash
   git clone https://github.com/YOUR-USERNAME/your-rescue-repo.git
   cd your-rescue-repo
   ```

2. **Setup prerequisites** (if not done already):
   ```bash
   sudo scripts/setup-prerequisites.sh
   ```

3. **Verify installation**:
   ```bash
   scripts/verify-setup.sh
   ```

4. **Configure your environment**:
   ```bash
   # Edit device information
   vim metadata.yml
   ```

5. **Initialize project**:
   ```bash
   python3 scripts/add_record.py \
     --source "my-device" \
     --type "setup" \
     --summary "Repository initialized" \
     --details "Created rescue repository from template"
   ```

6. **Generate dashboard**:
   ```bash
   python3 scripts/generate_dashboard.py
   # View: open dashboard/index.html in browser
   ```

### VS Code Development Environment

Set up a complete VS Code development environment with container support and remote access:

```bash
# Transfer and run setup script on your device
scp scripts/setup-vscode-dev-environment.sh user@your-device:~/
ssh user@your-device
chmod +x setup-vscode-dev-environment.sh
./setup-vscode-dev-environment.sh
```

**Features included**:
- 🌐 **Web-based VS Code**: Access from any browser at `http://device-ip:8080`
- 🐳 **Container Development**: Pre-configured devcontainer templates
- 🐙 **GitHub Integration**: CLI tools and VS Code extensions
- 🎨 **Dracula Theme**: Professional dark theme with JetBrains Mono font
- 🔧 **Development Tools**: Python, Docker, Git, and essential extensions

See [📖 VS Code Development Setup](docs/vscode-development-setup.md) for detailed instructions.

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
| `setup-prerequisites.sh` | **Automated setup** - Install all dependencies |
| `verify-setup.sh` | **Verification** - Test all installations and functionality |
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
3. Make changes and run tests: `scripts/verify-setup.sh`
4. Commit with clear messages: `git commit -m "Add: new rescue feature"`
5. Push and create a Pull Request

See [CONTRIBUTING.md](CONTRIBUTING.md) for detailed guidelines.

## 🔧 Troubleshooting

### Common Setup Issues

**"Command not found" errors:**
```bash
# Ensure prerequisites are installed
sudo scripts/setup-prerequisites.sh

# Verify installation
scripts/verify-setup.sh
```

**Permission denied on scripts:**
```bash
# Make scripts executable
chmod +x scripts/*.sh
```

**Python module import errors:**
```bash
# Check Python installation
python3 --version
python3 -c "import sqlite3; print('SQLite OK')"

# Reinstall if needed
sudo apt install python3 python3-dev
```

**Network tools not working:**
```bash
# Install missing network tools
sudo apt install tcpdump arping nmap ethtool net-tools dnsmasq
```

**Dashboard not generating:**
```bash
# Check database exists and create if needed
python3 scripts/add_record.py --source "test" --type "init" --summary "Setup test"
python3 scripts/generate_dashboard.py
```

### Getting Help

- 🐛 **Report bugs**: [GitHub Issues](https://github.com/LReyes21/zimaboard-rescue/issues)
- 📖 **Documentation**: [PLAYBOOK.md](PLAYBOOK.md) for emergency procedures
- 💬 **Discussions**: Use GitHub Discussions for questions
- 🔧 **Verification**: Run `scripts/verify-setup.sh` for diagnostics

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🏷️ Tags

`zimaboard` `rescue` `recovery` `network` `automation` `template` `dashboard` `github-pages`

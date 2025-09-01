#!/bin/bash
# setup-prerequisites.sh - Automated setup for ZimaBoard Rescue Template
# Installs all required dependencies on Ubuntu/Debian systems

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if running as root
check_sudo() {
    if [[ $EUID -eq 0 ]]; then
        print_error "This script should not be run as root. Please run with sudo privileges only when needed."
        exit 1
    fi
    
    if ! sudo -n true 2>/dev/null; then
        print_status "This script requires sudo privileges. You may be prompted for your password."
    fi
}

# Detect OS and version
detect_os() {
    if [[ -f /etc/os-release ]]; then
        # shellcheck source=/etc/os-release
        . /etc/os-release
        OS=$NAME
        VERSION=$VERSION_ID
    else
        print_error "Cannot detect operating system. This script supports Ubuntu/Debian only."
        exit 1
    fi
    
    print_status "Detected OS: $OS $VERSION"
    
    # Check if supported
    case $OS in
        "Ubuntu")
            if [[ $(echo "$VERSION >= 20.04" | bc -l) -eq 0 ]]; then
                print_warning "Ubuntu $VERSION detected. This script is tested on Ubuntu 20.04+."
            fi
            ;;
        "Debian GNU/Linux")
            if [[ $(echo "$VERSION >= 11" | bc -l) -eq 0 ]]; then
                print_warning "Debian $VERSION detected. This script is tested on Debian 11+."
            fi
            ;;
        *)
            print_warning "Unsupported OS: $OS. Attempting to continue anyway..."
            ;;
    esac
}

# Update package index
update_packages() {
    print_status "Updating package index..."
    if sudo apt update; then
        print_success "Package index updated successfully"
    else
        print_error "Failed to update package index"
        exit 1
    fi
}

# Install system packages
install_system_packages() {
    print_status "Installing system packages..."
    
    local packages=(
        "python3"
        "python3-dev"
        "python3-pip"
        "python3-venv"
        "python3-flake8"
        "shellcheck"
        "dnsmasq"
        "git"
        "curl"
        "tcpdump"
        "arping"
        "nmap"
        "ethtool"
        "net-tools"
        "iputils-ping"
        "bc"  # For version comparisons
    )
    
    local failed_packages=()
    
    for package in "${packages[@]}"; do
        print_status "Installing $package..."
        if sudo apt install -y "$package"; then
            print_success "✓ $package installed"
        else
            print_error "✗ Failed to install $package"
            failed_packages+=("$package")
        fi
    done
    
    if [[ ${#failed_packages[@]} -gt 0 ]]; then
        print_error "Failed to install: ${failed_packages[*]}"
        print_error "Please install these packages manually"
        exit 1
    fi
    
    print_success "All system packages installed successfully"
}

# Install GitHub CLI (optional)
install_github_cli() {
    print_status "Installing GitHub CLI (optional)..."
    
    if command -v gh &> /dev/null; then
        print_success "GitHub CLI already installed: $(gh --version | head -n1)"
        return 0
    fi
    
    # Add GitHub CLI repository
    if curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg; then
        print_success "Added GitHub CLI keyring"
    else
        print_warning "Failed to add GitHub CLI keyring, skipping GitHub CLI installation"
        return 0
    fi
    
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
    
    if sudo apt update && sudo apt install -y gh; then
        print_success "GitHub CLI installed successfully: $(gh --version | head -n1)"
    else
        print_warning "Failed to install GitHub CLI. You can install it later if needed."
    fi
}

# Verify installations
verify_installations() {
    print_status "Verifying installations..."
    
    local commands=(
        "python3:Python 3"
        "pip3:pip3"
        "shellcheck:ShellCheck"
        "dnsmasq:dnsmasq"
        "git:Git"
        "curl:curl"
        "tcpdump:tcpdump"
        "arping:arping"
        "nmap:Nmap"
        "ethtool:ethtool"
        "ping:ping"
        "flake8:flake8"
    )
    
    local missing_commands=()
    
    for cmd_info in "${commands[@]}"; do
        IFS=':' read -r cmd name <<< "$cmd_info"
        if command -v "$cmd" &> /dev/null; then
            print_success "✓ $name: $(command -v "$cmd")"
        else
            print_error "✗ $name: NOT FOUND"
            missing_commands+=("$name")
        fi
    done
    
    if [[ ${#missing_commands[@]} -gt 0 ]]; then
        print_error "Missing commands: ${missing_commands[*]}"
        return 1
    fi
    
    print_success "All required commands are available"
    return 0
}

# Test Python functionality
test_python_functionality() {
    print_status "Testing Python functionality..."
    
    # Test Python 3
    if python3 -c "import sys; print(f'Python {sys.version}')" 2>/dev/null; then
        print_success "✓ Python 3 working"
    else
        print_error "✗ Python 3 not working"
        return 1
    fi
    
    # Test SQLite3 (should be included with Python)
    if python3 -c "import sqlite3; print('SQLite3 available')" 2>/dev/null; then
        print_success "✓ SQLite3 available"
    else
        print_error "✗ SQLite3 not available"
        return 1
    fi
    
    # Test flake8
    if python3 -m flake8 --version 2>/dev/null; then
        print_success "✓ flake8 working"
    else
        print_error "✗ flake8 not working"
        return 1
    fi
    
    return 0
}

# Create directories if needed
setup_project_structure() {
    print_status "Setting up project structure..."
    
    local dirs=("data" "dashboard" "diagnostics")
    
    for dir in "${dirs[@]}"; do
        if [[ ! -d "$dir" ]]; then
            mkdir -p "$dir"
            print_success "Created directory: $dir"
        fi
    done
}

# Test script functionality
test_scripts() {
    print_status "Testing rescue scripts..."
    
    # Test dashboard generation
    if python3 scripts/generate_dashboard.py 2>/dev/null; then
        print_success "✓ Dashboard generation working"
    else
        print_warning "Dashboard generation failed - this is normal if no database exists yet"
    fi
    
    # Test add_record script help
    if python3 scripts/add_record.py --help &>/dev/null; then
        print_success "✓ Record addition script working"
    else
        print_error "✗ Record addition script failed"
        return 1
    fi
    
    return 0
}

# Main installation function
main() {
    echo "======================================"
    echo "ZimaBoard Rescue Template Setup"
    echo "======================================"
    echo
    
    check_sudo
    detect_os
    update_packages
    install_system_packages
    install_github_cli
    
    echo
    echo "======================================"
    echo "Verification Phase"
    echo "======================================"
    echo
    
    if verify_installations && test_python_functionality; then
        setup_project_structure
        test_scripts
        
        echo
        echo "======================================"
        print_success "SETUP COMPLETE!"
        echo "======================================"
        echo
        print_status "Next steps:"
        echo "  1. Edit metadata.yml with your device information"
        echo "  2. Run: python3 scripts/add_record.py --help"
        echo "  3. Run: python3 scripts/generate_dashboard.py"
        echo "  4. Run: scripts/verify-setup.sh"
        echo
        print_status "For emergency rescue, see: PLAYBOOK.md"
        
    else
        echo
        print_error "Setup incomplete. Please check the errors above and try again."
        exit 1
    fi
}

# Run main function
main "$@"

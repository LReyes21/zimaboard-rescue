#!/bin/bash

# VS Code Development Environment Setup for ZimaBoard
# This script sets up a complete development environment with VS Code, containers, and GitHub integration

set -euo pipefail

# Color output for better readability
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_step() {
    echo -e "${PURPLE}[STEP]${NC} $1"
}

# Check if running on target system
check_system() {
    log_step "Checking system requirements..."
    
    if [[ ! -f /etc/lsb-release ]]; then
        log_error "This script is designed for Ubuntu systems"
        exit 1
    fi
    
    source /etc/lsb-release
    if [[ "$DISTRIB_ID" != "Ubuntu" ]]; then
        log_error "This script requires Ubuntu"
        exit 1
    fi
    
    log_info "Running on $DISTRIB_DESCRIPTION"
    
    # Check architecture
    ARCH=$(uname -m)
    log_info "Architecture: $ARCH"
    
    # Check if we have sudo access
    if ! sudo echo "Testing sudo access..." >/dev/null 2>&1; then
        log_error "This script requires sudo access"
        exit 1
    fi
    
    log_success "System requirements met"
}

# Update system packages
update_system() {
    log_step "Updating system packages..."
    
    sudo apt update
    sudo apt upgrade -y
    sudo apt autoremove -y
    
    log_success "System updated"
}

# Install VS Code Server (code-server for remote access)
install_code_server() {
    log_step "Installing VS Code Server (code-server)..."
    
    # Download and install code-server
    curl -fsSL https://code-server.dev/install.sh | sh
    
    # Create configuration directory
    mkdir -p ~/.config/code-server
    
    # Generate secure password
    PASSWORD=$(openssl rand -base64 32)
    
    # Create configuration
    cat > ~/.config/code-server/config.yaml << EOF
bind-addr: 0.0.0.0:8080
auth: password
password: $PASSWORD
cert: false
EOF
    
    log_success "VS Code Server installed"
    log_warning "VS Code Server password: $PASSWORD"
    log_warning "Save this password! You'll need it to access VS Code"
    
    # Save password to file for reference
    echo "VS Code Server Password: $PASSWORD" > ~/vscode-password.txt
    chmod 600 ~/vscode-password.txt
    
    log_info "Password also saved to ~/vscode-password.txt"
}

# Setup code-server as a systemd service
setup_code_server_service() {
    log_step "Setting up VS Code Server as a system service..."
    
    # Create systemd service file
    sudo tee /etc/systemd/system/code-server@.service > /dev/null << EOF
[Unit]
Description=code-server
After=network.target

[Service]
Type=exec
ExecStart=/usr/bin/code-server
Restart=always
User=%i
Environment=PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

[Install]
WantedBy=multi-user.target
EOF
    
    # Enable and start the service
    sudo systemctl daemon-reload
    sudo systemctl enable code-server@$USER
    sudo systemctl start code-server@$USER
    
    log_success "VS Code Server service configured and started"
}

# Install essential VS Code extensions
install_vscode_extensions() {
    log_step "Installing essential VS Code extensions..."
    
    # Wait a moment for code-server to start
    sleep 5
    
    # List of essential extensions
    EXTENSIONS=(
        "ms-python.python"
        "ms-python.black-formatter"
        "ms-python.flake8"
        "ms-python.pylint"
        "ms-vscode.vscode-typescript-next"
        "ms-vscode-remote.remote-containers"
        "ms-vscode-remote.remote-ssh"
        "ms-vscode.sublime-text-keymap"
        "GitHub.vscode-pull-request-github"
        "GitHub.copilot"
        "ms-vscode.theme-dracula"
        "PKief.material-icon-theme"
        "bradlc.vscode-tailwindcss"
        "esbenp.prettier-vscode"
        "ms-vscode.vscode-json"
        "redhat.vscode-yaml"
        "ms-kubernetes-tools.vscode-kubernetes-tools"
        "ms-vscode-remote.remote-wsl"
    )
    
    for ext in "${EXTENSIONS[@]}"; do
        log_info "Installing extension: $ext"
        code-server --install-extension "$ext" || log_warning "Failed to install $ext"
    done
    
    log_success "VS Code extensions installed"
}

# Setup Docker for development
setup_docker_dev() {
    log_step "Configuring Docker for development..."
    
    # Add current user to docker group
    sudo usermod -aG docker $USER
    
    # Configure Docker daemon for development
    sudo mkdir -p /etc/docker
    
    cat > /tmp/docker-daemon.json << EOF
{
    "log-driver": "json-file",
    "log-opts": {
        "max-size": "10m",
        "max-file": "3"
    },
    "storage-driver": "overlay2",
    "features": {
        "buildkit": true
    }
}
EOF
    
    sudo mv /tmp/docker-daemon.json /etc/docker/daemon.json
    
    # Restart Docker
    sudo systemctl restart docker
    
    # Install Docker Compose
    COMPOSE_VERSION=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep tag_name | cut -d '"' -f 4)
    sudo curl -L "https://github.com/docker/compose/releases/download/${COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
    
    log_success "Docker configured for development"
    log_info "Docker Compose version: $COMPOSE_VERSION"
}

# Setup development directories
setup_dev_directories() {
    log_step "Setting up development directories..."
    
    # Create standard development structure
    mkdir -p ~/Development/{projects,containers,scripts,experiments}
    mkdir -p ~/Development/containers/{devcontainers,compose}
    
    # Create a sample devcontainer configuration
    mkdir -p ~/Development/containers/devcontainers/python-dev/.devcontainer
    
    cat > ~/Development/containers/devcontainers/python-dev/.devcontainer/devcontainer.json << EOF
{
    "name": "Python Development",
    "image": "mcr.microsoft.com/vscode/devcontainers/python:3.11",
    "features": {
        "ghcr.io/devcontainers/features/git:1": {},
        "ghcr.io/devcontainers/features/github-cli:1": {},
        "ghcr.io/devcontainers/features/docker-in-docker:2": {}
    },
    "customizations": {
        "vscode": {
            "extensions": [
                "ms-python.python",
                "ms-python.black-formatter",
                "ms-python.flake8",
                "GitHub.vscode-pull-request-github",
                "GitHub.copilot"
            ],
            "settings": {
                "python.defaultInterpreterPath": "/usr/local/bin/python",
                "python.formatting.provider": "black"
            }
        }
    },
    "postCreateCommand": "pip install -r requirements.txt",
    "remoteUser": "vscode"
}
EOF
    
    # Create sample requirements.txt
    cat > ~/Development/containers/devcontainers/python-dev/requirements.txt << EOF
# Development dependencies
black
flake8
pytest
requests
numpy
pandas
matplotlib
jupyter
EOF
    
    log_success "Development directories created"
}

# Install GitHub CLI and configure
install_github_cli() {
    log_step "Installing and configuring GitHub CLI..."
    
    # Install GitHub CLI
    curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
    sudo chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
    sudo apt update
    sudo apt install gh -y
    
    log_success "GitHub CLI installed"
    log_info "Run 'gh auth login' to authenticate with GitHub"
}

# Setup development environment variables
setup_environment() {
    log_step "Setting up development environment..."
    
    # Add development environment to bashrc
    cat >> ~/.bashrc << 'EOF'

# Development Environment Settings
export DEVELOPMENT_HOME="$HOME/Development"
export PATH="$PATH:$HOME/.local/bin"
export EDITOR="code-server"

# Docker development aliases
alias dps='docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"'
alias dlog='docker logs -f'
alias dexec='docker exec -it'
alias dc='docker-compose'
alias dcup='docker-compose up -d'
alias dcdown='docker-compose down'
alias dcbuild='docker-compose build'

# Development aliases
alias dev='cd $DEVELOPMENT_HOME'
alias projects='cd $DEVELOPMENT_HOME/projects'
alias containers='cd $DEVELOPMENT_HOME/containers'

# Git aliases for faster development
alias gs='git status'
alias ga='git add'
alias gc='git commit'
alias gp='git push'
alias gl='git log --oneline -10'
alias gb='git branch'
alias gco='git checkout'

# VS Code aliases
alias code='code-server'
alias vscode='code-server'
EOF
    
    log_success "Development environment configured"
}

# Create development workspace
create_workspace() {
    log_step "Creating VS Code workspace for ZimaBoard development..."
    
    mkdir -p ~/Development/projects/zimaboard-workspace
    
    cat > ~/Development/projects/zimaboard-workspace/zimaboard-dev.code-workspace << EOF
{
    "folders": [
        {
            "name": "ZimaBoard Rescue",
            "path": "./zimaboard-rescue"
        },
        {
            "name": "Development Containers",
            "path": "../containers"
        },
        {
            "name": "Scripts",
            "path": "../scripts"
        },
        {
            "name": "Experiments",
            "path": "../experiments"
        }
    ],
    "settings": {
        "python.defaultInterpreterPath": "/usr/bin/python3",
        "terminal.integrated.defaultProfile.linux": "bash",
        "workbench.colorTheme": "Dracula",
        "workbench.iconTheme": "material-icon-theme",
        "editor.fontFamily": "'JetBrains Mono', 'Courier New', monospace",
        "editor.fontSize": 14,
        "editor.lineHeight": 1.5,
        "docker.dockerPath": "/usr/bin/docker",
        "git.enableSmartCommit": true,
        "git.confirmSync": false
    },
    "extensions": {
        "recommendations": [
            "ms-python.python",
            "ms-vscode-remote.remote-containers",
            "GitHub.vscode-pull-request-github",
            "GitHub.copilot",
            "dracula-theme.theme-dracula",
            "PKief.material-icon-theme"
        ]
    }
}
EOF
    
    # Clone the zimaboard-rescue repository
    cd ~/Development/projects/zimaboard-workspace
    git clone https://github.com/LReyes21/zimaboard-rescue.git
    
    log_success "VS Code workspace created"
}

# Setup firewall rules for VS Code Server
setup_firewall() {
    log_step "Configuring firewall for VS Code Server..."
    
    # Allow VS Code Server port
    sudo ufw allow 8080/tcp comment "VS Code Server"
    
    # Check if ufw is active
    if sudo ufw status | grep -q "Status: active"; then
        log_success "Firewall configured for VS Code Server (port 8080)"
    else
        log_warning "UFW firewall is not active"
        log_info "To enable firewall: sudo ufw enable"
    fi
}

# Display connection information
show_connection_info() {
    log_step "Displaying connection information..."
    
    # Get local IP address
    LOCAL_IP=$(hostname -I | awk '{print $1}')
    
    echo
    echo -e "${CYAN}=== VS Code Development Environment Setup Complete ===${NC}"
    echo
    echo -e "${GREEN}VS Code Server Access:${NC}"
    echo -e "  Local:    http://localhost:8080"
    echo -e "  Network:  http://$LOCAL_IP:8080"
    echo -e "  External: http://$(curl -s ifconfig.me 2>/dev/null || echo "YOUR_PUBLIC_IP"):8080"
    echo
    echo -e "${GREEN}Credentials:${NC}"
    echo -e "  Password: $(cat ~/vscode-password.txt | cut -d: -f2 | xargs)"
    echo
    echo -e "${GREEN}Development Structure:${NC}"
    echo -e "  ~/Development/projects/          - Your development projects"
    echo -e "  ~/Development/containers/        - Container configurations"
    echo -e "  ~/Development/scripts/           - Development scripts"
    echo -e "  ~/Development/experiments/       - Experimental code"
    echo
    echo -e "${GREEN}Workspace:${NC}"
    echo -e "  Open: ~/Development/projects/zimaboard-workspace/zimaboard-dev.code-workspace"
    echo
    echo -e "${GREEN}Next Steps:${NC}"
    echo -e "  1. Access VS Code at http://$LOCAL_IP:8080"
    echo -e "  2. Enter the password shown above"
    echo -e "  3. Open the zimaboard-dev.code-workspace file"
    echo -e "  4. Run 'gh auth login' to connect GitHub"
    echo -e "  5. Configure GitHub Copilot in VS Code"
    echo
    echo -e "${YELLOW}Note: You may need to restart your shell or run 'source ~/.bashrc' to use new aliases${NC}"
}

# Main execution
main() {
    echo -e "${PURPLE}=== ZimaBoard VS Code Development Environment Setup ===${NC}"
    echo
    
    check_system
    update_system
    install_code_server
    setup_code_server_service
    install_vscode_extensions
    setup_docker_dev
    setup_dev_directories
    install_github_cli
    setup_environment
    create_workspace
    setup_firewall
    show_connection_info
    
    echo
    log_success "Development environment setup complete!"
    log_info "Reboot recommended to ensure all services start properly"
}

# Run main function
main "$@"

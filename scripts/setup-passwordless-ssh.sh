#!/bin/bash

# Passwordless SSH and Sudo Setup for ZimaBoard Development
# Configures secure, efficient connection between laptop and ZimaBoard

set -euo pipefail

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

# Configuration
ZIMABOARD_HOST="userver.local"
ZIMABOARD_IP="192.168.0.147"
ZIMABOARD_USER="luis"
LAPTOP_HOST="luis-ubuntu-lt"

# Logging functions
log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }
log_step() { echo -e "${PURPLE}[STEP]${NC} $1"; }

# Check prerequisites
check_prerequisites() {
    log_step "Checking prerequisites..."
    
    # Check if we can reach ZimaBoard
    if ! ping -c 1 "$ZIMABOARD_HOST" &>/dev/null && ! ping -c 1 "$ZIMABOARD_IP" &>/dev/null; then
        log_error "Cannot reach ZimaBoard at $ZIMABOARD_HOST or $ZIMABOARD_IP"
        exit 1
    fi
    
    # Check SSH client
    if ! command -v ssh &>/dev/null; then
        log_error "SSH client not found"
        exit 1
    fi
    
    log_success "Prerequisites met"
}

# Generate SSH key if it doesn't exist
generate_ssh_key() {
    log_step "Setting up SSH key authentication..."
    
    SSH_KEY="$HOME/.ssh/id_rsa_zimaboard"
    
    if [[ ! -f "$SSH_KEY" ]]; then
        log_info "Generating new SSH key for ZimaBoard..."
        ssh-keygen -t rsa -b 4096 -f "$SSH_KEY" -C "${USER}@${LAPTOP_HOST}-to-zimaboard" -N ""
        log_success "SSH key generated: $SSH_KEY"
    else
        log_info "SSH key already exists: $SSH_KEY"
    fi
    
    # Set proper permissions
    chmod 600 "$SSH_KEY"
    chmod 644 "$SSH_KEY.pub"
}

# Copy SSH key to ZimaBoard
copy_ssh_key() {
    log_step "Copying SSH key to ZimaBoard..."
    
    SSH_KEY="$HOME/.ssh/id_rsa_zimaboard"
    
    log_info "You'll need to enter your ZimaBoard password one last time..."
    if ssh-copy-id -i "$SSH_KEY.pub" "$ZIMABOARD_USER@$ZIMABOARD_HOST"; then
        log_success "SSH key copied to ZimaBoard"
    else
        log_warning "Failed with hostname, trying IP address..."
        ssh-copy-id -i "$SSH_KEY.pub" "$ZIMABOARD_USER@$ZIMABOARD_IP"
        log_success "SSH key copied to ZimaBoard via IP"
    fi
}

# Configure SSH client
configure_ssh_client() {
    log_step "Configuring SSH client..."
    
    SSH_CONFIG="$HOME/.ssh/config"
    SSH_KEY="$HOME/.ssh/id_rsa_zimaboard"
    
    # Backup existing config
    if [[ -f "$SSH_CONFIG" ]]; then
        cp "$SSH_CONFIG" "${SSH_CONFIG}.backup.$(date +%Y%m%d_%H%M%S)"
        log_info "Backed up existing SSH config"
    fi
    
    # Remove existing ZimaBoard entries
    if [[ -f "$SSH_CONFIG" ]]; then
        sed -i '/# ZimaBoard Configuration/,/# End ZimaBoard Configuration/d' "$SSH_CONFIG"
    fi
    
    # Add ZimaBoard configuration
    cat >> "$SSH_CONFIG" << EOF

# ZimaBoard Configuration - Added $(date)
Host zimaboard zima userver userver.local
    HostName $ZIMABOARD_HOST
    User $ZIMABOARD_USER
    IdentityFile $SSH_KEY
    IdentitiesOnly yes
    ServerAliveInterval 60
    ServerAliveCountMax 3
    ConnectTimeout 10
    StrictHostKeyChecking no
    UserKnownHostsFile /dev/null
    LogLevel QUIET

Host zimaboard-ip zima-ip
    HostName $ZIMABOARD_IP
    User $ZIMABOARD_USER
    IdentityFile $SSH_KEY
    IdentitiesOnly yes
    ServerAliveInterval 60
    ServerAliveCountMax 3
    ConnectTimeout 10
    StrictHostKeyChecking no
    UserKnownHostsFile /dev/null
    LogLevel QUIET
# End ZimaBoard Configuration

EOF
    
    chmod 600 "$SSH_CONFIG"
    log_success "SSH client configured"
}

# Test passwordless SSH
test_ssh_connection() {
    log_step "Testing passwordless SSH connection..."
    
    if ssh zimaboard "echo 'SSH connection successful!' && hostname && whoami"; then
        log_success "Passwordless SSH is working!"
    else
        log_error "SSH connection failed"
        return 1
    fi
}

# Configure passwordless sudo on ZimaBoard
configure_passwordless_sudo() {
    log_step "Configuring passwordless sudo on ZimaBoard..."
    
    log_info "This requires entering your sudo password on ZimaBoard one last time..."
    
    # Create sudoers entry
    SUDOERS_ENTRY="$ZIMABOARD_USER ALL=(ALL) NOPASSWD:ALL"
    
    if ssh zimaboard "echo '$SUDOERS_ENTRY' | sudo tee /etc/sudoers.d/99-$ZIMABOARD_USER-nopasswd > /dev/null"; then
        log_success "Passwordless sudo configured"
        
        # Test sudo access
        if ssh zimaboard "sudo whoami" | grep -q "root"; then
            log_success "Passwordless sudo is working!"
        else
            log_error "Sudo test failed"
            return 1
        fi
    else
        log_error "Failed to configure passwordless sudo"
        return 1
    fi
}

# Create convenience aliases and functions
create_dev_shortcuts() {
    log_step "Creating development shortcuts..."
    
    # Add to .bashrc if not already present
    if ! grep -q "# ZimaBoard Development Shortcuts" ~/.bashrc; then
        cat >> ~/.bashrc << 'EOF'

# ZimaBoard Development Shortcuts - Added by setup script
alias zima='ssh zimaboard'
alias zima-ip='ssh zimaboard-ip'
alias zsync='rsync -avz --progress'
alias zcode='ssh zimaboard "code-server"'
alias zstatus='ssh zimaboard "systemctl --user status code-server@\$USER"'
alias zdocker='ssh zimaboard "docker"'
alias zps='ssh zimaboard "docker ps --format \"table {{.Names}}\t{{.Status}}\t{{.Ports}}\""'

# Function to sync current directory to ZimaBoard
zsync-here() {
    local remote_dir="${1:-~/Development/sync/$(basename $(pwd))}"
    echo "Syncing $(pwd) to zimaboard:$remote_dir"
    ssh zimaboard "mkdir -p $remote_dir"
    rsync -avz --progress --exclude='.git' --exclude='node_modules' --exclude='__pycache__' . zimaboard:"$remote_dir/"
}

# Function to run commands on ZimaBoard with output
zrun() {
    echo "Running on ZimaBoard: $*"
    ssh zimaboard "$@"
}

# Function to edit files on ZimaBoard via VS Code Server
zedit() {
    local file="$1"
    if [[ -z "$file" ]]; then
        echo "Usage: zedit <file-path-on-zimaboard>"
        return 1
    fi
    echo "Opening $file in ZimaBoard VS Code..."
    ssh zimaboard "code-server $file"
}
EOF
        log_success "Development shortcuts added to ~/.bashrc"
        log_info "Run 'source ~/.bashrc' or restart terminal to use new aliases"
    else
        log_info "Development shortcuts already exist in ~/.bashrc"
    fi
}

# Create SSH tunnel script for VS Code
create_vscode_tunnel() {
    log_step "Creating VS Code tunnel script..."
    
    TUNNEL_SCRIPT="$HOME/bin/vscode-tunnel"
    mkdir -p "$HOME/bin"
    
    cat > "$TUNNEL_SCRIPT" << 'EOF'
#!/bin/bash

# VS Code Server Tunnel for ZimaBoard
# Creates a secure SSH tunnel to access VS Code Server locally

ZIMABOARD_HOST="zimaboard"
REMOTE_PORT="8080"
LOCAL_PORT="${1:-8080}"

echo "Creating SSH tunnel for VS Code Server..."
echo "ZimaBoard VS Code will be available at: http://localhost:$LOCAL_PORT"
echo "Press Ctrl+C to stop the tunnel"
echo

# Create SSH tunnel
ssh -L "$LOCAL_PORT:localhost:$REMOTE_PORT" -N "$ZIMABOARD_HOST"
EOF
    
    chmod +x "$TUNNEL_SCRIPT"
    
    # Add to PATH if not already there
    if ! echo "$PATH" | grep -q "$HOME/bin"; then
        echo 'export PATH="$HOME/bin:$PATH"' >> ~/.bashrc
        log_info "Added ~/bin to PATH in ~/.bashrc"
    fi
    
    log_success "VS Code tunnel script created: $TUNNEL_SCRIPT"
    log_info "Usage: vscode-tunnel [local-port] (default: 8080)"
}

# Create monitoring script
create_monitoring_script() {
    log_step "Creating ZimaBoard monitoring script..."
    
    MONITOR_SCRIPT="$HOME/bin/zima-status"
    
    cat > "$MONITOR_SCRIPT" << 'EOF'
#!/bin/bash

# ZimaBoard Status Monitor
# Quick overview of ZimaBoard system status

echo "=== ZimaBoard Status Monitor ==="
echo

# System info
echo "🖥️  System Information:"
ssh zimaboard "echo '  Hostname: '$(hostname) && echo '  Uptime: '$(uptime -p) && echo '  Load: '$(uptime | cut -d'load' -f2)"
echo

# VS Code Server status
echo "💻 VS Code Server:"
if ssh zimaboard "systemctl --user is-active code-server@\$USER" | grep -q "active"; then
    echo "  ✅ Running"
    echo "  🌐 Access: http://192.168.0.147:8080"
else
    echo "  ❌ Not running"
fi
echo

# Docker status
echo "🐳 Docker:"
ssh zimaboard "docker ps --format 'table {{.Names}}\t{{.Status}}' 2>/dev/null || echo '  Docker not available'"
echo

# Disk usage
echo "💾 Storage:"
ssh zimaboard "df -h / | tail -1 | awk '{print \"  Root: \" \$3 \"/\" \$2 \" (\" \$5 \" used)\"}'"
echo

# Memory usage
echo "🧠 Memory:"
ssh zimaboard "free -h | grep Mem | awk '{print \"  RAM: \" \$3 \"/\" \$2 \" used\"}'"
echo

# Network
echo "🌐 Network:"
ssh zimaboard "echo '  IP: '$(hostname -I | awk '{print \$1}')"
echo
EOF
    
    chmod +x "$MONITOR_SCRIPT"
    log_success "Monitoring script created: $MONITOR_SCRIPT"
    log_info "Usage: zima-status"
}

# Display connection summary
show_summary() {
    log_step "Setup Complete! Here's your new workflow:"
    
    echo
    echo -e "${CYAN}=== Passwordless SSH & Sudo Configured ===${NC}"
    echo
    echo -e "${GREEN}🔐 SSH Authentication:${NC}"
    echo -e "  • Passwordless SSH key: ~/.ssh/id_rsa_zimaboard"
    echo -e "  • SSH config: ~/.ssh/config (with aliases)"
    echo -e "  • Passwordless sudo: Configured on ZimaBoard"
    echo
    echo -e "${GREEN}🚀 Quick Commands:${NC}"
    echo -e "  • ${YELLOW}zima${NC}                 - Connect to ZimaBoard"
    echo -e "  • ${YELLOW}zrun 'command'${NC}       - Run command on ZimaBoard"
    echo -e "  • ${YELLOW}zsync-here [dir]${NC}     - Sync current directory"
    echo -e "  • ${YELLOW}zstatus${NC}              - Check VS Code Server status"
    echo -e "  • ${YELLOW}zima-status${NC}          - Full ZimaBoard status"
    echo -e "  • ${YELLOW}vscode-tunnel${NC}        - Create VS Code tunnel"
    echo
    echo -e "${GREEN}🛠️  Development Workflow:${NC}"
    echo -e "  1. ${CYAN}zima${NC} - Connect to ZimaBoard"
    echo -e "  2. ${CYAN}./setup-vscode-dev-environment.sh${NC} - Run VS Code setup"
    echo -e "  3. ${CYAN}exit${NC} - Return to laptop"
    echo -e "  4. ${CYAN}vscode-tunnel${NC} - Access VS Code locally"
    echo -e "  5. Open http://localhost:8080 in browser"
    echo
    echo -e "${GREEN}📁 File Transfer:${NC}"
    echo -e "  • ${CYAN}zsync-here${NC} - Sync current directory to ZimaBoard"
    echo -e "  • ${CYAN}scp file.txt zimaboard:~/Desktop/${NC} - Copy single file"
    echo -e "  • ${CYAN}rsync -avz . zimaboard:~/project/${NC} - Full sync"
    echo
    echo -e "${YELLOW}💡 Pro Tips:${NC}"
    echo -e "  • Use VS Code tunnel for secure remote access"
    echo -e "  • SSH config supports multiple aliases: zima, userver, zimaboard"
    echo -e "  • All commands work without passwords now!"
    echo -e "  • Run 'source ~/.bashrc' to load new aliases"
    echo
}

# Main execution
main() {
    echo -e "${PURPLE}=== ZimaBoard Passwordless SSH & Sudo Setup ===${NC}"
    echo -e "${BLUE}Laptop:${NC} ${LAPTOP_HOST} ($(hostname -I | awk '{print $1}'))"
    echo -e "${BLUE}ZimaBoard:${NC} ${ZIMABOARD_HOST} (${ZIMABOARD_IP})"
    echo
    
    check_prerequisites
    generate_ssh_key
    copy_ssh_key
    configure_ssh_client
    test_ssh_connection
    configure_passwordless_sudo
    create_dev_shortcuts
    create_vscode_tunnel
    create_monitoring_script
    show_summary
    
    echo
    log_success "Setup complete! You can now work efficiently between laptop and ZimaBoard."
    log_info "Next: Run 'zima' to connect and './setup-vscode-dev-environment.sh' to complete VS Code setup"
}

# Run main function
main "$@"

#!/bin/bash

# GitHub Repository Sync System for ZimaBoard
# Comprehensive solution for managing all GitHub repositories on 1TB drive

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
GITHUB_USER="LReyes21"
STORAGE_BASE="/opt/data"
GITHUB_BASE="$STORAGE_BASE/github"
REPOS_DIR="$GITHUB_BASE/repositories"
BACKUP_DIR="$GITHUB_BASE/backups"
LOGS_DIR="$GITHUB_BASE/logs"
CONFIG_DIR="$GITHUB_BASE/config"

# Logging functions
log_info() { echo -e "${BLUE}[INFO]${NC} $1" | tee -a "$LOGS_DIR/sync.log"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1" | tee -a "$LOGS_DIR/sync.log"; }
log_warning() { echo -e "${YELLOW}[WARNING]${NC} $1" | tee -a "$LOGS_DIR/sync.log"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1" | tee -a "$LOGS_DIR/sync.log"; }
log_step() { echo -e "${PURPLE}[STEP]${NC} $1" | tee -a "$LOGS_DIR/sync.log"; }

# Initialize GitHub workspace on 1TB drive
init_github_workspace() {
    log_step "Initializing GitHub workspace on 1TB drive..."
    
    # Create directory structure
    sudo mkdir -p "$GITHUB_BASE" "$REPOS_DIR" "$BACKUP_DIR" "$LOGS_DIR" "$CONFIG_DIR"
    sudo chown -R $USER:$USER "$GITHUB_BASE"
    
    # Create subdirectories for organization
    mkdir -p "$REPOS_DIR"/{personal,work,forks,experiments}
    mkdir -p "$BACKUP_DIR"/{daily,weekly,monthly}
    mkdir -p "$CONFIG_DIR"/{ssh,git,scripts}
    
    log_success "GitHub workspace initialized at $GITHUB_BASE"
}

# Setup GitHub-specific SSH keys
setup_github_ssh() {
    log_step "Setting up GitHub SSH authentication..."
    
    SSH_DIR="$CONFIG_DIR/ssh"
    GITHUB_KEY="$SSH_DIR/github_rsa"
    
    # Generate GitHub-specific SSH key if it doesn't exist
    if [[ ! -f "$GITHUB_KEY" ]]; then
        log_info "Generating GitHub SSH key..."
        ssh-keygen -t rsa -b 4096 -f "$GITHUB_KEY" -C "$USER@zimaboard-github" -N ""
        chmod 600 "$GITHUB_KEY"
        chmod 644 "$GITHUB_KEY.pub"
        log_success "GitHub SSH key generated: $GITHUB_KEY"
    fi
    
    # Configure SSH for GitHub
    cat > "$SSH_DIR/config" << EOF
# GitHub Configuration for ZimaBoard
Host github.com
    HostName github.com
    User git
    IdentityFile $GITHUB_KEY
    IdentitiesOnly yes
    ServerAliveInterval 60
    ServerAliveCountMax 3

Host github-personal
    HostName github.com
    User git
    IdentityFile $GITHUB_KEY
    IdentitiesOnly yes
EOF
    
    # Link to user's SSH config
    mkdir -p ~/.ssh
    if [[ ! -f ~/.ssh/config ]] || ! grep -q "Include $SSH_DIR/config" ~/.ssh/config; then
        echo "Include $SSH_DIR/config" >> ~/.ssh/config
        log_info "Added GitHub SSH config to user SSH configuration"
    fi
    
    log_success "GitHub SSH configuration complete"
    log_warning "Add this public key to your GitHub account:"
    echo "$(cat $GITHUB_KEY.pub)"
    echo
    log_info "Visit: https://github.com/settings/ssh/new"
}

# Install and configure GitHub CLI
setup_github_cli() {
    log_step "Setting up GitHub CLI..."
    
    # Check if GitHub CLI is installed
    if ! command -v gh &>/dev/null; then
        log_info "Installing GitHub CLI..."
        curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
        sudo chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg
        echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
        sudo apt update && sudo apt install gh -y
        log_success "GitHub CLI installed"
    else
        log_info "GitHub CLI already installed"
    fi
    
    # Configure Git with proper identity
    git config --global user.name "$GITHUB_USER"
    git config --global user.email "$(whoami)@zimaboard.local"
    git config --global init.defaultBranch main
    git config --global pull.rebase false
    git config --global core.autocrlf input
    
    log_success "Git configuration complete"
}

# Create repository management scripts
create_repo_scripts() {
    log_step "Creating repository management scripts..."
    
    SCRIPTS_DIR="$CONFIG_DIR/scripts"
    
    # Clone all user repositories script
    cat > "$SCRIPTS_DIR/clone-all-repos.sh" << 'EOF'
#!/bin/bash
# Clone all repositories for a GitHub user

GITHUB_USER="${1:-LReyes21}"
REPOS_DIR="/opt/data/github/repositories"
LOG_FILE="/opt/data/github/logs/clone-all.log"

echo "$(date): Starting clone of all repositories for $GITHUB_USER" >> "$LOG_FILE"

# Get list of all repositories
gh repo list "$GITHUB_USER" --limit 1000 --json name,sshUrl,isPrivate,isFork > /tmp/repos.json

# Process each repository
jq -r '.[] | "\(.name)|\(.sshUrl)|\(.isPrivate)|\(.isFork)"' /tmp/repos.json | while IFS='|' read -r name ssh_url is_private is_fork; do
    # Determine target directory
    if [[ "$is_fork" == "true" ]]; then
        target_dir="$REPOS_DIR/forks/$name"
    elif [[ "$is_private" == "true" ]]; then
        target_dir="$REPOS_DIR/personal/$name"
    else
        target_dir="$REPOS_DIR/personal/$name"
    fi
    
    echo "Processing: $name -> $target_dir" | tee -a "$LOG_FILE"
    
    if [[ -d "$target_dir" ]]; then
        echo "  Repository exists, pulling latest changes..." | tee -a "$LOG_FILE"
        cd "$target_dir" && git pull
    else
        echo "  Cloning repository..." | tee -a "$LOG_FILE"
        mkdir -p "$(dirname "$target_dir")"
        git clone "$ssh_url" "$target_dir"
    fi
done

echo "$(date): Clone operation completed" >> "$LOG_FILE"
EOF
    
    # Sync all repositories script
    cat > "$SCRIPTS_DIR/sync-all-repos.sh" << 'EOF'
#!/bin/bash
# Sync all local repositories

REPOS_DIR="/opt/data/github/repositories"
LOG_FILE="/opt/data/github/logs/sync-all.log"

echo "$(date): Starting sync of all repositories" >> "$LOG_FILE"

find "$REPOS_DIR" -name ".git" -type d | while read -r git_dir; do
    repo_dir="$(dirname "$git_dir")"
    repo_name="$(basename "$repo_dir")"
    
    echo "Syncing: $repo_name" | tee -a "$LOG_FILE"
    cd "$repo_dir"
    
    # Fetch all remotes
    git fetch --all --prune 2>&1 | tee -a "$LOG_FILE"
    
    # Pull if on main/master branch
    current_branch=$(git branch --show-current)
    if [[ "$current_branch" == "main" || "$current_branch" == "master" ]]; then
        git pull 2>&1 | tee -a "$LOG_FILE"
    fi
done

echo "$(date): Sync operation completed" >> "$LOG_FILE"
EOF
    
    # Backup repositories script
    cat > "$SCRIPTS_DIR/backup-repos.sh" << 'EOF'
#!/bin/bash
# Create backup of all repositories

REPOS_DIR="/opt/data/github/repositories"
BACKUP_DIR="/opt/data/github/backups"
DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="$BACKUP_DIR/daily/github_backup_$DATE.tar.gz"

echo "Creating backup: $BACKUP_FILE"
mkdir -p "$(dirname "$BACKUP_FILE")"

# Create compressed backup
tar -czf "$BACKUP_FILE" -C "$REPOS_DIR" .

# Keep only last 7 daily backups
find "$BACKUP_DIR/daily" -name "github_backup_*.tar.gz" -mtime +7 -delete

echo "Backup completed: $BACKUP_FILE"
ls -lh "$BACKUP_FILE"
EOF
    
    # Repository status script
    cat > "$SCRIPTS_DIR/repo-status.sh" << 'EOF'
#!/bin/bash
# Show status of all repositories

REPOS_DIR="/opt/data/github/repositories"

echo "=== GitHub Repository Status ==="
echo

total_repos=0
uncommitted_changes=0

find "$REPOS_DIR" -name ".git" -type d | while read -r git_dir; do
    repo_dir="$(dirname "$git_dir")"
    repo_name="$(basename "$repo_dir")"
    category="$(basename "$(dirname "$repo_dir")")"
    
    cd "$repo_dir"
    
    # Get branch and status
    branch=$(git branch --show-current 2>/dev/null || echo "detached")
    status=$(git status --porcelain 2>/dev/null)
    
    total_repos=$((total_repos + 1))
    
    printf "%-20s %-10s %-15s" "$repo_name" "$category" "$branch"
    
    if [[ -n "$status" ]]; then
        echo " 🔄 Changes"
        uncommitted_changes=$((uncommitted_changes + 1))
    else
        echo " ✅ Clean"
    fi
done

echo
echo "Total repositories: $total_repos"
echo "With uncommitted changes: $uncommitted_changes"
EOF
    
    # Make scripts executable
    chmod +x "$SCRIPTS_DIR"/*.sh
    
    log_success "Repository management scripts created"
}

# Create monitoring and automation
setup_automation() {
    log_step "Setting up automation and monitoring..."
    
    # Create sync service
    cat > /tmp/github-sync.service << EOF
[Unit]
Description=GitHub Repository Sync Service
After=network.target

[Service]
Type=oneshot
User=$USER
WorkingDirectory=$GITHUB_BASE
ExecStart=$CONFIG_DIR/scripts/sync-all-repos.sh
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF
    
    # Create sync timer (every 4 hours)
    cat > /tmp/github-sync.timer << EOF
[Unit]
Description=GitHub Repository Sync Timer
Requires=github-sync.service

[Timer]
OnCalendar=*-*-* 00,06,12,18:00:00
Persistent=true

[Install]
WantedBy=timers.target
EOF
    
    # Install systemd files
    sudo mv /tmp/github-sync.service /etc/systemd/system/
    sudo mv /tmp/github-sync.timer /etc/systemd/system/
    sudo systemctl daemon-reload
    sudo systemctl enable github-sync.timer
    
    log_success "Automation configured (sync every 6 hours)"
}

# Create development aliases
create_aliases() {
    log_step "Creating GitHub development aliases..."
    
    # Add GitHub aliases to bashrc
    if ! grep -q "# GitHub Development Aliases" ~/.bashrc; then
        cat >> ~/.bashrc << 'EOF'

# GitHub Development Aliases - ZimaBoard
export GITHUB_WORKSPACE="/opt/data/github"
export PATH="$GITHUB_WORKSPACE/config/scripts:$PATH"

# Navigation aliases
alias repos='cd /opt/data/github/repositories'
alias personal='cd /opt/data/github/repositories/personal'
alias forks='cd /opt/data/github/repositories/forks'
alias work='cd /opt/data/github/repositories/work'
alias experiments='cd /opt/data/github/repositories/experiments'

# Repository management aliases
alias clone-all='clone-all-repos.sh'
alias sync-all='sync-all-repos.sh'
alias backup-repos='backup-repos.sh'
alias repo-status='repo-status.sh'

# Git shortcuts optimized for many repos
alias gst='git status'
alias gpl='git pull'
alias gps='git push'
alias gco='git checkout'
alias gcm='git commit -m'
alias gad='git add .'

# GitHub CLI shortcuts
alias ghpr='gh pr create'
alias ghpv='gh pr view'
alias ghis='gh issue create'
alias ghiv='gh issue view'
alias ghrel='gh release create'
EOF
        log_success "GitHub aliases added to ~/.bashrc"
    fi
}

# Create workspace summary
show_workspace_summary() {
    log_step "GitHub Workspace Summary"
    
    echo
    echo -e "${CYAN}=== GitHub Repository Management System ===${NC}"
    echo
    echo -e "${GREEN}📁 Storage Structure:${NC}"
    echo -e "  Base: ${YELLOW}$GITHUB_BASE${NC}"
    echo -e "  Repositories: ${YELLOW}$REPOS_DIR${NC}"
    echo -e "    ├── personal/     - Your repositories"
    echo -e "    ├── work/         - Work repositories" 
    echo -e "    ├── forks/        - Forked repositories"
    echo -e "    └── experiments/  - Testing repositories"
    echo -e "  Backups: ${YELLOW}$BACKUP_DIR${NC}"
    echo -e "  Logs: ${YELLOW}$LOGS_DIR${NC}"
    echo -e "  Config: ${YELLOW}$CONFIG_DIR${NC}"
    echo
    echo -e "${GREEN}🔑 SSH Setup:${NC}"
    echo -e "  GitHub Key: $CONFIG_DIR/ssh/github_rsa"
    echo -e "  Add public key to GitHub: https://github.com/settings/ssh/new"
    echo
    echo -e "${GREEN}🛠️ Management Commands:${NC}"
    echo -e "  ${CYAN}clone-all${NC}     - Clone all your repositories"
    echo -e "  ${CYAN}sync-all${NC}      - Sync all local repositories" 
    echo -e "  ${CYAN}backup-repos${NC}  - Create backup of all repos"
    echo -e "  ${CYAN}repo-status${NC}   - Show status of all repos"
    echo
    echo -e "${GREEN}📁 Navigation:${NC}"
    echo -e "  ${CYAN}repos${NC}         - Go to repositories directory"
    echo -e "  ${CYAN}personal${NC}      - Go to personal repos"
    echo -e "  ${CYAN}forks${NC}        - Go to forked repos"
    echo -e "  ${CYAN}work${NC}         - Go to work repos"
    echo
    echo -e "${GREEN}⚡ Automation:${NC}"
    echo -e "  Auto-sync: Every 6 hours"
    echo -e "  Backups: Daily (kept for 7 days)"
    echo -e "  Logs: Stored in $LOGS_DIR"
    echo
    echo -e "${GREEN}🔄 Next Steps:${NC}"
    echo -e "  1. Add SSH public key to GitHub"
    echo -e "  2. Run 'gh auth login' to authenticate"
    echo -e "  3. Run 'clone-all' to sync all repositories"
    echo -e "  4. Use 'source ~/.bashrc' to load new aliases"
    echo
}

# Main execution
main() {
    echo -e "${PURPLE}=== ZimaBoard GitHub Repository Management Setup ===${NC}"
    echo
    
    init_github_workspace
    setup_github_ssh
    setup_github_cli
    create_repo_scripts
    setup_automation
    create_aliases
    show_workspace_summary
    
    log_success "GitHub repository management system setup complete!"
}

# Run main function
main "$@"

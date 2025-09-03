#!/bin/bash

# Advanced GitHub Sync with Webhooks, Cloud Triggers, and Automated Tasks
# Creates a comprehensive sync system with multiple trigger mechanisms

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
GITHUB_BASE="/opt/data/github"
WEBHOOK_PORT="9876"
WEBHOOK_SECRET="$(openssl rand -hex 32)"
NGROK_CONFIG_DIR="$GITHUB_BASE/config/ngrok"
WEBHOOK_DIR="$GITHUB_BASE/webhooks"
LOGS_DIR="$GITHUB_BASE/logs"

# Logging functions
log_info() { echo -e "${BLUE}[INFO]${NC} $1" | tee -a "$LOGS_DIR/advanced-sync.log"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1" | tee -a "$LOGS_DIR/advanced-sync.log"; }
log_warning() { echo -e "${YELLOW}[WARNING]${NC} $1" | tee -a "$LOGS_DIR/advanced-sync.log"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1" | tee -a "$LOGS_DIR/advanced-sync.log"; }
log_step() { echo -e "${PURPLE}[STEP]${NC} $1" | tee -a "$LOGS_DIR/advanced-sync.log"; }

# Install webhook server dependencies
install_webhook_dependencies() {
    log_step "Installing webhook server dependencies..."
    
    # Install Node.js if not present
    if ! command -v node &>/dev/null; then
        curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
        sudo apt-get install -y nodejs
        log_success "Node.js installed"
    fi
    
    # Install ngrok for public webhook access
    if ! command -v ngrok &>/dev/null; then
        log_info "Installing ngrok..."
        curl -s https://ngrok-agent.s3.amazonaws.com/ngrok.asc | sudo tee /etc/apt/trusted.gpg.d/ngrok.asc >/dev/null
        echo "deb https://ngrok-agent.s3.amazonaws.com buster main" | sudo tee /etc/apt/sources.list.d/ngrok.list
        sudo apt update && sudo apt install ngrok -y
        log_success "ngrok installed"
    fi
    
    # Create webhook directories
    mkdir -p "$WEBHOOK_DIR" "$NGROK_CONFIG_DIR"
    
    log_success "Dependencies installed"
}

# Create webhook server
create_webhook_server() {
    log_step "Creating GitHub webhook server..."
    
    # Create package.json
    cat > "$WEBHOOK_DIR/package.json" << EOF
{
  "name": "zimaboard-github-webhook",
  "version": "1.0.0",
  "description": "GitHub webhook server for ZimaBoard repository sync",
  "main": "webhook-server.js",
  "scripts": {
    "start": "node webhook-server.js",
    "dev": "nodemon webhook-server.js"
  },
  "dependencies": {
    "express": "^4.18.2",
    "crypto": "^1.0.1",
    "child_process": "^1.0.2"
  }
}
EOF

    # Create webhook server
    cat > "$WEBHOOK_DIR/webhook-server.js" << 'EOF'
const express = require('express');
const crypto = require('crypto');
const { exec } = require('child_process');
const fs = require('fs');
const path = require('path');

const app = express();
const PORT = process.env.WEBHOOK_PORT || 9876;
const SECRET = process.env.WEBHOOK_SECRET;
const GITHUB_BASE = '/opt/data/github';
const LOGS_DIR = path.join(GITHUB_BASE, 'logs');

// Middleware to parse raw body
app.use('/webhook', express.raw({ type: 'application/json' }));

// Logging function
function log(level, message) {
    const timestamp = new Date().toISOString();
    const logMessage = `${timestamp} [${level}] ${message}\n`;
    console.log(logMessage.trim());
    fs.appendFileSync(path.join(LOGS_DIR, 'webhook.log'), logMessage);
}

// Verify GitHub webhook signature
function verifySignature(payload, signature) {
    if (!SECRET) {
        log('WARNING', 'No webhook secret configured');
        return true; // Allow if no secret is set
    }
    
    const hmac = crypto.createHmac('sha256', SECRET);
    const digest = 'sha256=' + hmac.update(payload).digest('hex');
    return crypto.timingSafeEqual(Buffer.from(signature), Buffer.from(digest));
}

// Execute sync script
function executeSync(action, repoName) {
    return new Promise((resolve, reject) => {
        const script = path.join(GITHUB_BASE, 'config/scripts/clone-all-repos.sh');
        log('INFO', `Executing sync for ${action}: ${repoName}`);
        
        exec(`bash ${script}`, (error, stdout, stderr) => {
            if (error) {
                log('ERROR', `Sync failed: ${error.message}`);
                reject(error);
            } else {
                log('SUCCESS', `Sync completed for ${repoName}`);
                resolve(stdout);
            }
        });
    });
}

// Webhook endpoint
app.post('/webhook', async (req, res) => {
    try {
        const signature = req.get('X-Hub-Signature-256');
        const event = req.get('X-GitHub-Event');
        const delivery = req.get('X-GitHub-Delivery');
        
        log('INFO', `Received ${event} event (${delivery})`);
        
        // Verify signature if secret is configured
        if (!verifySignature(req.body, signature)) {
            log('ERROR', 'Invalid signature');
            return res.status(401).send('Unauthorized');
        }
        
        const payload = JSON.parse(req.body);
        
        // Handle different GitHub events
        switch (event) {
            case 'repository':
                if (payload.action === 'created') {
                    log('INFO', `New repository created: ${payload.repository.name}`);
                    await executeSync('new_repo', payload.repository.name);
                }
                break;
                
            case 'push':
                log('INFO', `Push to ${payload.repository.name}:${payload.ref}`);
                await executeSync('push', payload.repository.name);
                break;
                
            case 'ping':
                log('INFO', 'Webhook ping received');
                break;
                
            default:
                log('INFO', `Unhandled event: ${event}`);
        }
        
        res.status(200).send('OK');
        
    } catch (error) {
        log('ERROR', `Webhook error: ${error.message}`);
        res.status(500).send('Internal Server Error');
    }
});

// Health check endpoint
app.get('/health', (req, res) => {
    res.json({
        status: 'healthy',
        timestamp: new Date().toISOString(),
        uptime: process.uptime()
    });
});

// Start server
app.listen(PORT, '0.0.0.0', () => {
    log('INFO', `Webhook server listening on port ${PORT}`);
    log('INFO', `Health check: http://localhost:${PORT}/health`);
    log('INFO', `Webhook URL: http://localhost:${PORT}/webhook`);
});

// Graceful shutdown
process.on('SIGTERM', () => {
    log('INFO', 'Webhook server shutting down');
    process.exit(0);
});
EOF

    # Install npm dependencies
    cd "$WEBHOOK_DIR"
    npm install express
    
    log_success "Webhook server created"
}

# Setup webhook service
setup_webhook_service() {
    log_step "Setting up webhook systemd service..."
    
    # Create environment file
    cat > "$WEBHOOK_DIR/.env" << EOF
WEBHOOK_PORT=$WEBHOOK_PORT
WEBHOOK_SECRET=$WEBHOOK_SECRET
NODE_ENV=production
EOF
    
    # Create systemd service
    cat > /tmp/github-webhook.service << EOF
[Unit]
Description=GitHub Webhook Server for ZimaBoard
After=network.target

[Service]
Type=simple
User=$USER
WorkingDirectory=$WEBHOOK_DIR
Environment=NODE_ENV=production
EnvironmentFile=$WEBHOOK_DIR/.env
ExecStart=/usr/bin/node webhook-server.js
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF
    
    sudo mv /tmp/github-webhook.service /etc/systemd/system/
    sudo systemctl daemon-reload
    sudo systemctl enable github-webhook.service
    
    log_success "Webhook service configured"
}

# Setup ngrok for public webhook access
setup_ngrok_tunnel() {
    log_step "Setting up ngrok tunnel for webhook access..."
    
    # Create ngrok config
    cat > "$NGROK_CONFIG_DIR/ngrok.yml" << EOF
version: "2"
authtoken: "YOUR_NGROK_AUTH_TOKEN"
tunnels:
  github-webhook:
    addr: $WEBHOOK_PORT
    proto: http
    subdomain: zimaboard-github-webhook
    bind_tls: true
EOF
    
    # Create ngrok service
    cat > /tmp/ngrok-webhook.service << EOF
[Unit]
Description=ngrok tunnel for GitHub webhook
After=network.target github-webhook.service
Requires=github-webhook.service

[Service]
Type=simple
User=$USER
WorkingDirectory=$NGROK_CONFIG_DIR
ExecStart=/usr/bin/ngrok start github-webhook --config ngrok.yml
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF
    
    sudo mv /tmp/ngrok-webhook.service /etc/systemd/system/
    sudo systemctl daemon-reload
    
    log_success "ngrok tunnel service configured"
    log_warning "Add your ngrok auth token to: $NGROK_CONFIG_DIR/ngrok.yml"
}

# Create GitHub Actions workflow for backup triggers
create_github_actions_workflow() {
    log_step "Creating GitHub Actions workflow for backup triggers..."
    
    WORKFLOW_DIR="$GITHUB_BASE/github-actions"
    mkdir -p "$WORKFLOW_DIR"
    
    # Create workflow that can trigger ZimaBoard sync
    cat > "$WORKFLOW_DIR/trigger-zimaboard-sync.yml" << 'EOF'
name: Trigger ZimaBoard Sync

on:
  schedule:
    - cron: '0 2,8,14,20 * * *'  # Every 6 hours
  repository_dispatch:
    types: [zimaboard-sync]
  workflow_dispatch:  # Manual trigger

jobs:
  trigger-sync:
    runs-on: ubuntu-latest
    steps:
      - name: Trigger ZimaBoard Sync
        run: |
          # Send webhook to ZimaBoard
          curl -X POST \
            -H "Content-Type: application/json" \
            -H "X-GitHub-Event: repository_dispatch" \
            -d '{"action": "sync_request", "client_payload": {"trigger": "github_actions"}}' \
            ${{ secrets.ZIMABOARD_WEBHOOK_URL }}/webhook
            
      - name: Trigger Backup
        run: |
          # Send backup trigger
          curl -X POST \
            -H "Content-Type: application/json" \
            -H "X-GitHub-Event: backup_request" \
            -d '{"action": "backup_request", "client_payload": {"type": "scheduled"}}' \
            ${{ secrets.ZIMABOARD_WEBHOOK_URL }}/webhook
EOF
    
    log_success "GitHub Actions workflow created"
    log_info "Add this to any repository: $WORKFLOW_DIR/trigger-zimaboard-sync.yml"
}

# Create enhanced sync scripts with webhook support
create_enhanced_sync_scripts() {
    log_step "Creating enhanced sync scripts with webhook support..."
    
    SCRIPTS_DIR="$GITHUB_BASE/config/scripts"
    
    # Create intelligent sync script
    cat > "$SCRIPTS_DIR/intelligent-sync.sh" << 'EOF'
#!/bin/bash
# Intelligent sync with webhook support

GITHUB_BASE="/opt/data/github"
REPOS_DIR="$GITHUB_BASE/repositories"
LOGS_DIR="$GITHUB_BASE/logs"
LOG_FILE="$LOGS_DIR/intelligent-sync.log"

log() {
    echo "$(date): $*" | tee -a "$LOG_FILE"
}

# Check for new repositories
check_new_repos() {
    log "Checking for new repositories..."
    
    # Get current repos from GitHub
    gh repo list LReyes21 --limit 1000 --json name > /tmp/github_repos.json
    
    # Get local repos
    find "$REPOS_DIR" -name ".git" -type d | while read git_dir; do
        basename "$(dirname "$git_dir")"
    done > /tmp/local_repos.txt
    
    # Find differences
    jq -r '.[].name' /tmp/github_repos.json | sort > /tmp/github_repos.txt
    sort /tmp/local_repos.txt > /tmp/local_repos_sorted.txt
    
    NEW_REPOS=$(comm -23 /tmp/github_repos.txt /tmp/local_repos_sorted.txt)
    
    if [[ -n "$NEW_REPOS" ]]; then
        log "New repositories found: $NEW_REPOS"
        # Clone new repositories
        /opt/data/github/config/scripts/clone-all-repos.sh
        
        # Send notification
        if command -v notify-send &>/dev/null; then
            notify-send "ZimaBoard Sync" "New repositories cloned: $NEW_REPOS"
        fi
    else
        log "No new repositories found"
    fi
}

# Sync all existing repos
sync_existing() {
    log "Syncing existing repositories..."
    /opt/data/github/config/scripts/sync-all-repos.sh
}

# Main execution
log "Starting intelligent sync..."
check_new_repos
sync_existing
log "Intelligent sync completed"
EOF

    # Create cloud backup script with multiple destinations
    cat > "$SCRIPTS_DIR/cloud-backup.sh" << 'EOF'
#!/bin/bash
# Enhanced backup with cloud storage support

GITHUB_BASE="/opt/data/github"
BACKUP_DIR="$GITHUB_BASE/backups"
LOGS_DIR="$GITHUB_BASE/logs"
DATE=$(date +%Y%m%d_%H%M%S)

log() {
    echo "$(date): $*" | tee -a "$LOGS_DIR/cloud-backup.log"
}

# Create local backup
create_local_backup() {
    log "Creating local backup..."
    
    BACKUP_FILE="$BACKUP_DIR/daily/github_backup_$DATE.tar.gz"
    mkdir -p "$(dirname "$BACKUP_FILE")"
    
    # Create backup with metadata
    cd "$GITHUB_BASE"
    tar --exclude='./backups' --exclude='./logs/*.log' -czf "$BACKUP_FILE" .
    
    # Create backup manifest
    cat > "\$BACKUP_DIR/daily/manifest_\$DATE.json" << EOL
{
    "timestamp": "\$(date -u +%Y-%m-%dT%H:%M:%SZ)",
    "backup_file": "\$(basename "\$BACKUP_FILE")",
    "size_bytes": \$(stat -c%s "\$BACKUP_FILE"),
    "repositories_count": \$(find repositories -name ".git" -type d | wc -l),
    "checksum": "\$(sha256sum "\$BACKUP_FILE" | cut -d' ' -f1)"
}
EOL
    
    log "Local backup created: $BACKUP_FILE ($(du -h "$BACKUP_FILE" | cut -f1))"
}

# Upload to cloud storage (if configured)
upload_to_cloud() {
    log "Checking cloud storage configuration..."
    
    # Check for rclone configuration
    if command -v rclone &>/dev/null && rclone listremotes | grep -q "cloud:"; then
        log "Uploading to cloud storage..."
        rclone copy "$BACKUP_DIR/daily/github_backup_$DATE.tar.gz" cloud:zimaboard-backups/github/
        rclone copy "$BACKUP_DIR/daily/manifest_$DATE.json" cloud:zimaboard-backups/github/
        log "Cloud upload completed"
    else
        log "Cloud storage not configured (install rclone and configure 'cloud' remote)"
    fi
}

# Cleanup old backups
cleanup_old_backups() {
    log "Cleaning up old backups..."
    
    # Keep last 7 daily backups
    find "$BACKUP_DIR/daily" -name "github_backup_*.tar.gz" -mtime +7 -delete
    find "$BACKUP_DIR/daily" -name "manifest_*.json" -mtime +7 -delete
    
    log "Cleanup completed"
}

# Main execution
log "Starting enhanced backup..."
create_local_backup
upload_to_cloud
cleanup_old_backups
log "Enhanced backup completed"
EOF
    
    chmod +x "$SCRIPTS_DIR"/intelligent-sync.sh "$SCRIPTS_DIR"/cloud-backup.sh
    
    log_success "Enhanced sync scripts created"
}

# Setup monitoring and alerting
setup_monitoring() {
    log_step "Setting up monitoring and alerting..."
    
    MONITOR_DIR="$GITHUB_BASE/monitoring"
    mkdir -p "$MONITOR_DIR"
    
    # Create monitoring script
    cat > "$MONITOR_DIR/monitor-sync.sh" << 'EOF'
#!/bin/bash
# Monitor sync health and send alerts

GITHUB_BASE="/opt/data/github"
LOGS_DIR="$GITHUB_BASE/logs"
ALERT_EMAIL="your-email@example.com"  # Configure this

check_sync_health() {
    local last_sync=$(stat -c %Y "$LOGS_DIR/sync.log" 2>/dev/null || echo 0)
    local current_time=$(date +%s)
    local hours_since_sync=$(( (current_time - last_sync) / 3600 ))
    
    if [[ $hours_since_sync -gt 8 ]]; then
        echo "WARNING: Last sync was $hours_since_sync hours ago"
        return 1
    fi
    
    return 0
}

check_webhook_health() {
    if systemctl is-active --quiet github-webhook.service; then
        return 0
    else
        echo "ERROR: Webhook service is not running"
        return 1
    fi
}

check_disk_space() {
    local usage=$(df /opt/data | tail -1 | awk '{print $5}' | sed 's/%//')
    if [[ $usage -gt 90 ]]; then
        echo "WARNING: Disk usage is at $usage%"
        return 1
    fi
    return 0
}

# Send alert (configure email or other notification method)
send_alert() {
    local message="$1"
    echo "$(date): ALERT - $message" >> "$LOGS_DIR/alerts.log"
    
    # Uncomment and configure for email alerts
    # echo "$message" | mail -s "ZimaBoard GitHub Sync Alert" "$ALERT_EMAIL"
    
    # For Discord webhook (if configured)
    # curl -H "Content-Type: application/json" \
    #      -d "{\"content\": \"🚨 ZimaBoard Alert: $message\"}" \
    #      "$DISCORD_WEBHOOK_URL"
}

# Main health check
if ! check_sync_health; then
    send_alert "Sync health check failed"
fi

if ! check_webhook_health; then
    send_alert "Webhook service health check failed"
fi

if ! check_disk_space; then
    send_alert "Disk space warning"
fi
EOF
    
    chmod +x "$MONITOR_DIR/monitor-sync.sh"
    
    # Create monitoring timer
    cat > /tmp/github-monitoring.timer << EOF
[Unit]
Description=GitHub Sync Monitoring Timer
Requires=github-monitoring.service

[Timer]
OnCalendar=*:0/30  # Every 30 minutes
Persistent=true

[Install]
WantedBy=timers.target
EOF
    
    cat > /tmp/github-monitoring.service << EOF
[Unit]
Description=GitHub Sync Health Monitoring
After=network.target

[Service]
Type=oneshot
User=$USER
WorkingDirectory=$MONITOR_DIR
ExecStart=$MONITOR_DIR/monitor-sync.sh
StandardOutput=journal
StandardError=journal
EOF
    
    sudo mv /tmp/github-monitoring.{service,timer} /etc/systemd/system/
    sudo systemctl daemon-reload
    sudo systemctl enable github-monitoring.timer
    
    log_success "Monitoring and alerting configured"
}

# Create setup summary and instructions
create_setup_instructions() {
    log_step "Creating setup instructions..."
    
    cat > "$GITHUB_BASE/ADVANCED_SYNC_SETUP.md" << EOF
# Advanced GitHub Sync Setup Instructions

## 🎯 Overview
This system provides multiple trigger mechanisms for keeping your ZimaBoard synchronized with GitHub:

1. **Webhooks** - Real-time triggers from GitHub events
2. **GitHub Actions** - Cloud-based scheduled triggers  
3. **Local Timers** - System-level automated sync
4. **Manual Triggers** - On-demand sync and backup

## 🔧 Setup Steps

### 1. Configure ngrok (for webhooks)
\`\`\`bash
# Sign up for ngrok account: https://ngrok.com/
# Get your auth token from dashboard
sudo -u $USER ngrok config add-authtoken YOUR_AUTH_TOKEN

# Edit ngrok config
nano $NGROK_CONFIG_DIR/ngrok.yml
# Replace YOUR_NGROK_AUTH_TOKEN with your actual token
\`\`\`

### 2. Start Services
\`\`\`bash
sudo systemctl start github-webhook.service
sudo systemctl start ngrok-webhook.service
sudo systemctl start github-monitoring.timer

# Check status
sudo systemctl status github-webhook.service
sudo systemctl status ngrok-webhook.service
\`\`\`

### 3. Configure GitHub Webhooks
1. Go to each repository → Settings → Webhooks
2. Add webhook:
   - **Payload URL**: https://your-ngrok-subdomain.ngrok.io/webhook
   - **Content type**: application/json
   - **Secret**: $WEBHOOK_SECRET
   - **Events**: Repository, Push, Repository Creation

### 4. Setup GitHub Actions (Optional)
1. Add the workflow file to any repository: .github/workflows/trigger-zimaboard-sync.yml
2. Add repository secrets:
   - ZIMABOARD_WEBHOOK_URL: https://your-ngrok-subdomain.ngrok.io

### 5. Configure Cloud Backup (Optional)
\`\`\`bash
# Install rclone
curl https://rclone.org/install.sh | sudo bash

# Configure cloud storage (Google Drive, Dropbox, etc.)
rclone config
# Create a remote named 'cloud'
\`\`\`

## 🚀 Available Triggers

### Real-time Triggers
- **New Repository**: Automatic clone when you create a repo
- **Push Events**: Sync when you push to any repo
- **Manual Webhook**: Send POST to /webhook endpoint

### Scheduled Triggers  
- **Local Timer**: Every 6 hours (00:00, 06:00, 12:00, 18:00)
- **GitHub Actions**: Every 6 hours (cloud-based)
- **Backup Timer**: Daily at 02:00
- **Health Monitoring**: Every 30 minutes

### Manual Triggers
\`\`\`bash
# Intelligent sync (checks for new repos)
$GITHUB_BASE/config/scripts/intelligent-sync.sh

# Enhanced backup
$GITHUB_BASE/config/scripts/cloud-backup.sh

# Repository status
$GITHUB_BASE/config/scripts/repo-status.sh
\`\`\`

## 📊 Monitoring

### Logs
- **Webhook logs**: $LOGS_DIR/webhook.log
- **Sync logs**: $LOGS_DIR/intelligent-sync.log  
- **Backup logs**: $LOGS_DIR/cloud-backup.log
- **Alerts**: $LOGS_DIR/alerts.log

### Health Checks
\`\`\`bash
# Check webhook server
curl http://localhost:$WEBHOOK_PORT/health

# Check services
sudo systemctl status github-webhook.service
sudo systemctl status github-monitoring.timer

# View recent logs
journalctl -u github-webhook.service -f
\`\`\`

## 🔔 Alerting Configuration

### Email Alerts
Edit \`$MONITOR_DIR/monitor-sync.sh\` and configure:
- ALERT_EMAIL variable
- Uncomment mail command

### Discord Alerts  
Configure DISCORD_WEBHOOK_URL in monitoring script

### Custom Notifications
Add your preferred notification method to monitor-sync.sh

## 🛠️ Troubleshooting

### Webhook Not Receiving Events
1. Check ngrok tunnel: \`ngrok http $WEBHOOK_PORT\`
2. Verify GitHub webhook configuration
3. Check webhook secret matches
4. Review webhook logs

### Sync Not Working
1. Check GitHub CLI auth: \`gh auth status\`
2. Verify SSH keys: \`ssh -T git@github.com\`
3. Check script permissions
4. Review sync logs

### Services Not Starting
1. Check systemd status: \`systemctl status service-name\`
2. Review journal logs: \`journalctl -u service-name\`
3. Verify file permissions
4. Check dependencies

## 📈 Advanced Features

### Custom Sync Logic
Edit \`intelligent-sync.sh\` to add:
- Repository filtering
- Branch-specific sync
- Custom clone locations
- Integration with other tools

### Multi-Cloud Backup
Configure multiple rclone remotes for redundancy:
\`\`\`bash
rclone copy backup.tar.gz gdrive:backups/
rclone copy backup.tar.gz dropbox:backups/
rclone copy backup.tar.gz s3:bucket/backups/
\`\`\`

### Webhook Security
- Use strong webhook secrets
- Enable HTTPS with SSL certificates
- Consider IP whitelist for GitHub IPs
- Regular token rotation

## 🎯 Next Steps
1. Test webhook delivery
2. Verify automated sync
3. Configure cloud backup
4. Setup alerting
5. Monitor logs and performance

Your ZimaBoard now has enterprise-grade GitHub synchronization! 🚀
EOF

    log_success "Setup instructions created: $GITHUB_BASE/ADVANCED_SYNC_SETUP.md"
}

# Show configuration summary
show_configuration_summary() {
    log_step "Configuration Summary"
    
    echo
    echo -e "${CYAN}=== Advanced GitHub Sync Configuration ===${NC}"
    echo
    echo -e "${GREEN}🔧 Services Created:${NC}"
    echo -e "  • Webhook Server: http://localhost:$WEBHOOK_PORT"
    echo -e "  • Health Check: http://localhost:$WEBHOOK_PORT/health"
    echo -e "  • ngrok Tunnel: Public webhook access"
    echo -e "  • Monitoring: Every 30 minutes"
    echo
    echo -e "${GREEN}🎯 Trigger Mechanisms:${NC}"
    echo -e "  • Real-time: GitHub webhooks for instant sync"
    echo -e "  • Scheduled: GitHub Actions + Local timers"
    echo -e "  • Manual: Command-line triggers"
    echo -e "  • Health: Automated monitoring and alerts"
    echo
    echo -e "${GREEN}📁 File Locations:${NC}"
    echo -e "  • Webhook Server: $WEBHOOK_DIR"
    echo -e "  • ngrok Config: $NGROK_CONFIG_DIR"
    echo -e "  • Enhanced Scripts: $GITHUB_BASE/config/scripts"
    echo -e "  • Monitoring: $GITHUB_BASE/monitoring"
    echo -e "  • Setup Guide: $GITHUB_BASE/ADVANCED_SYNC_SETUP.md"
    echo
    echo -e "${GREEN}🔑 Configuration:${NC}"
    echo -e "  • Webhook Port: $WEBHOOK_PORT"
    echo -e "  • Webhook Secret: ${WEBHOOK_SECRET:0:8}...*** (saved in .env)"
    echo -e "  • User: $USER"
    echo
    echo -e "${YELLOW}⚡ Next Steps:${NC}"
    echo -e "  1. Configure ngrok auth token"
    echo -e "  2. Start services: sudo systemctl start github-webhook ngrok-webhook"
    echo -e "  3. Add webhooks to GitHub repositories"
    echo -e "  4. Test webhook delivery"
    echo -e "  5. Configure cloud backup (optional)"
    echo
    echo -e "${CYAN}📚 Read the complete setup guide: $GITHUB_BASE/ADVANCED_SYNC_SETUP.md${NC}"
    echo
}

# Main execution
main() {
    echo -e "${PURPLE}=== Advanced GitHub Sync with Webhooks and Cloud Triggers ===${NC}"
    echo
    
    install_webhook_dependencies
    create_webhook_server
    setup_webhook_service
    setup_ngrok_tunnel
    create_github_actions_workflow
    create_enhanced_sync_scripts
    setup_monitoring
    create_setup_instructions
    show_configuration_summary
    
    log_success "Advanced GitHub sync system setup complete!"
    log_info "Review the setup guide: $GITHUB_BASE/ADVANCED_SYNC_SETUP.md"
}

# Run main function
main "$@"

# VS Code Development Environment Setup

This guide explains how to set up a complete VS Code development environment on your ZimaBoard with container support, GitHub integration, and remote access capabilities.

## Quick Setup

The fastest way to set up the development environment is using our automated script:

```bash
# Transfer and run the setup script
scp scripts/setup-vscode-dev-environment.sh userver.local:~/
ssh userver.local
chmod +x setup-vscode-dev-environment.sh
./setup-vscode-dev-environment.sh
```

## What Gets Installed

### Core Components
- **VS Code Server (code-server)**: Web-based VS Code accessible from any browser
- **Docker Development Setup**: Configured for container-based development
- **GitHub CLI**: Command-line GitHub integration
- **Development Containers**: Pre-configured devcontainer templates

### VS Code Extensions
- Python development (Python, Black, Flake8, Pylint)
- Remote development (SSH, Containers, WSL)
- GitHub integration (Pull Requests, Copilot)
- Dracula theme and Material Icon theme
- Essential language support (TypeScript, JSON, YAML)
- Docker and Kubernetes tools

### Development Structure
```
~/Development/
├── projects/              # Your development projects
│   └── zimaboard-workspace/
│       ├── zimaboard-dev.code-workspace
│       └── zimaboard-rescue/  # This repository
├── containers/            # Container configurations
│   ├── devcontainers/    # VS Code devcontainer templates
│   └── compose/          # Docker Compose files
├── scripts/              # Development scripts
└── experiments/          # Experimental code
```

## Accessing VS Code

After setup, VS Code Server will be available at:
- **Local access**: `http://localhost:8080` (from ZimaBoard)
- **Network access**: `http://192.168.0.147:8080` (from other devices)
- **Password**: Automatically generated and saved to `~/vscode-password.txt`

## Development Workflow

### 1. Remote Development
Access VS Code from any device on your network:
1. Open `http://192.168.0.147:8080` in your browser
2. Enter the generated password
3. Start coding!

### 2. Container Development
Use devcontainers for isolated development environments:
1. Open the Command Palette (`Ctrl+Shift+P`)
2. Select "Dev Containers: Reopen in Container"
3. Choose from pre-configured templates

### 3. GitHub Integration
1. Authenticate: `gh auth login`
2. Clone repositories directly in VS Code
3. Create pull requests from the editor
4. Use GitHub Copilot for AI assistance

## Useful Aliases

The setup script adds helpful aliases to your shell:

```bash
# Docker development
dps              # Pretty docker ps
dlog <container> # Follow docker logs
dexec <container> # Execute in container
dc               # docker-compose
dcup             # docker-compose up -d
dcdown           # docker-compose down

# Navigation
dev              # cd ~/Development
projects         # cd ~/Development/projects
containers       # cd ~/Development/containers

# Git shortcuts
gs               # git status
ga               # git add
gc               # git commit
gp               # git push
gl               # git log --oneline -10

# VS Code
code             # code-server
vscode           # code-server
```

## Configuration Files

### VS Code Workspace
The setup creates a comprehensive workspace at:
`~/Development/projects/zimaboard-workspace/zimaboard-dev.code-workspace`

This workspace includes:
- ZimaBoard Rescue project
- Development containers
- Scripts and experiments folders
- Dracula theme configuration
- JetBrains Mono font
- Recommended extensions

### Systemd Service
VS Code Server runs as a systemd service:
```bash
# Service management
sudo systemctl status code-server@$USER
sudo systemctl restart code-server@$USER
sudo systemctl logs code-server@$USER
```

## Troubleshooting

### VS Code Server Won't Start
```bash
# Check service status
sudo systemctl status code-server@$USER

# Check logs
sudo journalctl -u code-server@$USER -f

# Restart service
sudo systemctl restart code-server@$USER
```

### Can't Access from Network
```bash
# Check if port 8080 is open
sudo ufw status
sudo ufw allow 8080/tcp

# Check if service is listening
sudo netstat -tlnp | grep 8080
```

### Docker Permission Issues
```bash
# Add user to docker group (requires logout/login)
sudo usermod -aG docker $USER

# Or use newgrp to apply immediately
newgrp docker
```

### Extension Installation Issues
```bash
# Install extensions manually
code-server --install-extension ms-python.python
code-server --install-extension GitHub.copilot

# List installed extensions
code-server --list-extensions
```

## Advanced Configuration

### Custom Devcontainer
Create custom devcontainers in `~/Development/containers/devcontainers/`:

```json
{
    "name": "My Custom Environment",
    "image": "ubuntu:22.04",
    "features": {
        "ghcr.io/devcontainers/features/git:1": {},
        "ghcr.io/devcontainers/features/python:1": {
            "version": "3.11"
        }
    },
    "customizations": {
        "vscode": {
            "extensions": ["ms-python.python"],
            "settings": {
                "python.defaultInterpreterPath": "/usr/local/bin/python"
            }
        }
    }
}
```

### Port Forwarding (External Access)
To access VS Code from outside your network:

1. **Router Configuration**: Forward port 8080 to 192.168.0.147
2. **Dynamic DNS**: Use a service like DuckDNS for a stable hostname
3. **SSL/TLS**: Consider using Cloudflare Tunnel for secure access

### Multiple Workspaces
Create specialized workspaces for different projects:

```bash
# Create new workspace
mkdir -p ~/Development/projects/my-project
cd ~/Development/projects/my-project
code-server my-project.code-workspace
```

## Security Considerations

### Password Security
- Change the generated password regularly
- Use a strong, unique password
- Consider setting up SSL/TLS for external access

### Firewall Configuration
```bash
# Restrict access to specific IPs
sudo ufw allow from 192.168.0.0/24 to any port 8080

# Remove general access
sudo ufw delete allow 8080/tcp
```

### Container Security
- Regularly update base images
- Use non-root users in containers
- Scan images for vulnerabilities

## Performance Optimization

### Resource Limits
Monitor resource usage and adjust as needed:

```bash
# Check system resources
htop
docker stats

# Limit VS Code Server memory (in systemd service)
sudo systemctl edit code-server@$USER
# Add:
# [Service]
# MemoryLimit=2G
```

### Storage Optimization
- Use `.dockerignore` files
- Clean up unused images: `docker system prune`
- Monitor disk usage: `df -h`

## Next Steps

1. **Explore Templates**: Check out the devcontainer templates in `~/Development/containers/devcontainers/`
2. **GitHub Copilot**: Set up AI pair programming
3. **Remote Tunnels**: Configure VS Code tunnels for external access
4. **Custom Extensions**: Install project-specific extensions
5. **Backup Configuration**: Version control your VS Code settings

## Support

For issues specific to this setup:
1. Check the troubleshooting section above
2. Review logs: `sudo journalctl -u code-server@$USER`
3. Verify setup: Run the verification script
4. Create an issue in the repository

For general VS Code issues:
- [VS Code Documentation](https://code.visualstudio.com/docs)
- [code-server Documentation](https://coder.com/docs/code-server)
- [Dev Containers Documentation](https://code.visualstudio.com/docs/remote/containers)

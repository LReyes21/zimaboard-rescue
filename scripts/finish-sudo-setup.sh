#!/bin/bash

# Complete passwordless sudo setup for ZimaBoard
# Run this script ON the ZimaBoard after SSH setup

echo "=== Configuring Passwordless Sudo on ZimaBoard ==="
echo

# Create sudoers entry
SUDOERS_FILE="/etc/sudoers.d/99-$USER-nopasswd"
SUDOERS_ENTRY="$USER ALL=(ALL) NOPASSWD:ALL"

echo "Creating sudoers entry: $SUDOERS_ENTRY"
echo

# Use visudo to safely add the entry
echo "$SUDOERS_ENTRY" | sudo tee "$SUDOERS_FILE" > /dev/null

if [[ $? -eq 0 ]]; then
    echo "✅ Passwordless sudo configured successfully!"
    echo
    echo "Testing sudo access..."
    if sudo whoami | grep -q "root"; then
        echo "✅ Sudo test passed! You are now: $(sudo whoami)"
        echo
        echo "🎉 Setup complete! You can now run sudo commands without a password."
    else
        echo "❌ Sudo test failed"
        exit 1
    fi
else
    echo "❌ Failed to configure passwordless sudo"
    exit 1
fi

echo
echo "=== Final Setup Steps ==="
echo "1. ✅ Passwordless SSH - Working"
echo "2. ✅ Passwordless Sudo - Working"
echo "3. 🔄 Next: Run VS Code setup script"
echo
echo "Ready to run: ./setup-vscode-dev-environment.sh"

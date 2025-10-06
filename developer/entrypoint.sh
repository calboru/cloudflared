#!/bin/bash
set -euo pipefail

# -----------------------
# Sanity checks
# -----------------------
if [[ -z "${PUBLIC_KEY:-}" ]]; then
    echo "Error: PUBLIC_KEY environment variable is not set."
    exit 1
fi

# -----------------------
# Set locale
# -----------------------
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8

# -----------------------
# Setup home/data directory
# -----------------------
echo "Setting up home/data directory..."
mkdir -p /home/developer
chown developer:developer /home/developer
chmod 700 /home/developer

# -----------------------
# Configure SSH
# -----------------------
echo "Configuring SSH..."
mkdir -p /run/sshd
chmod 755 /run/sshd

ssh-keygen -A || { echo "Failed to generate SSH host keys"; exit 1; }

mkdir -p /home/developer/.ssh
echo "$PUBLIC_KEY" > /home/developer/.ssh/authorized_keys
chown -R developer:developer /home/developer/.ssh
chmod 700 /home/developer/.ssh
chmod 600 /home/developer/.ssh/authorized_keys

# -----------------------
# Setup VSCode Server directory
# -----------------------
echo "Setting up VSCode Server directory..."
mkdir -p /home/developer/.vscode-server
chown -R developer:developer /home/developer/.vscode-server
chmod -R 700 /home/developer/.vscode-server

# -----------------------
# Debug NVM/Node
# -----------------------
echo "Debugging NVM and Node..."
su developer -c "bash -c 'source /home/developer/.nvm/nvm.sh && nvm --version && node --version && npm --version'" \
|| echo "Warning: NVM/Node debug failed (check .nvm or permissions)"

# -----------------------
# Start supervisord
# -----------------------
echo "Starting supervisord..."
exec /usr/bin/supervisord -c /etc/supervisor/conf.d/supervisor.conf

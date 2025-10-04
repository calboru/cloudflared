#!/bin/bash
set -euo pipefail

SSH_USER="${SSH_USER:-pyuser}"
PUBLIC_KEY="${PUBLIC_KEY:-}"

# --- Validate required env vars ---
if [ -z "$PUBLIC_KEY" ]; then
    echo "❌ ERROR: PUBLIC_KEY environment variable is required"
    exit 1
fi

# --- Create SSH user if not exists (key-only login) ---
if ! id "$SSH_USER" &>/dev/null; then
    echo "🔧 Creating SSH user: $SSH_USER"
    # -m: create home, -s: shell, -p '*': locked password (no password login)
    useradd -m -d /home/${SSH_USER} -s /bin/bash -p '*' ${SSH_USER}
fi

# --- Setup SSH authorized_keys ---
mkdir -p /home/${SSH_USER}/.ssh
echo "$PUBLIC_KEY" > /home/${SSH_USER}/.ssh/authorized_keys
chmod 700 /home/${SSH_USER}/.ssh
chmod 600 /home/${SSH_USER}/.ssh/authorized_keys
chown -R ${SSH_USER}:${SSH_USER} /home/${SSH_USER}/.ssh

# --- Configure /app ownership ---
mkdir -p /app
chown -R ${SSH_USER}:${SSH_USER} /app

# --- Ensure only this user can log in via SSH ---
if ! grep -q "AllowUsers ${SSH_USER}" /etc/ssh/sshd_config; then
    echo "AllowUsers ${SSH_USER}" >> /etc/ssh/sshd_config
fi

# --- Start Supervisor (manages sshd, nginx, glances) ---
echo "🚀 Starting Supervisor..."
exec /usr/local/bin/supervisord -c /etc/supervisord.conf

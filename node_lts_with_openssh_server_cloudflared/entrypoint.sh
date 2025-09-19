#!/usr/bin/env bash
set -e

# Defaults
SSH_USER="${SSH_USER:-sshuser}"
APP_PATH="${APP_PATH:-/app}"

# PUBLIC_KEY is required
if [ -z "${PUBLIC_KEY:-}" ]; then
    echo "❌ ERROR: PUBLIC_KEY environment variable is required"
    exit 1
fi

 
# Create user if not exists
if ! id "$SSH_USER" &>/dev/null; then
    adduser -D -s /bin/bash "$SSH_USER"
    # Unlock user so SSH key login works
    passwd -u "$SSH_USER" >/dev/null 2>&1 || true
fi


# Ensure APP_PATH exists and belongs to user
mkdir -p "$APP_PATH"
chown -R "$SSH_USER:$SSH_USER" "$APP_PATH"

# Setup SSH authorized_keys
USER_HOME=$(getent passwd "$SSH_USER" | cut -d: -f6)
mkdir -p "$USER_HOME/.ssh"
echo "$PUBLIC_KEY" > "$USER_HOME/.ssh/authorized_keys"
chmod 700 "$USER_HOME/.ssh"
chmod 600 "$USER_HOME/.ssh/authorized_keys"
chown -R "$SSH_USER:$SSH_USER" "$USER_HOME/.ssh"

echo "✅ User: $SSH_USER"
echo "✅ App path: $APP_PATH"
echo "✅ Public key installed"

# Start supervisord (which runs sshd)
exec /usr/bin/supervisord -c /etc/supervisord.conf

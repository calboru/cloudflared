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

# Generate Cloudflared proxy configs
if [ -f /usr/local/bin/start_cloudflared_proxies.sh ]; then
    echo "🚀 Generating Cloudflared proxies..."
    /usr/local/bin/start_cloudflared_proxies.sh || echo "⚠️ Proxy config script exited with nonzero code"
else
    echo "⚠️ start_cloudflared_proxies.sh not found"
fi

echo "🔄 Starting supervisord..."
# Run supervisord in foreground
/usr/bin/supervisord -n -c /etc/supervisord.conf &

# Wait for supervisord to start, then signal reload
sleep 2
if [ -f /tmp/supervisord.pid ]; then
    kill -HUP $(cat /tmp/supervisord.pid)
    echo "✅ Sent SIGHUP to supervisord to reload configurations"
else
    echo "⚠️ supervisord.pid not found, configs may not be reloaded"
fi

# Keep container running
wait
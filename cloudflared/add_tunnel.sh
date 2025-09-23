#!/usr/bin/env bash
set -e

# Check if tunnel name and token are provided
if [ $# -ne 2 ]; then
    echo "Usage: $0 <tunnel_name> <tunnel_token>"
    echo "Example: $0 NEW_SERVICE your_new_token"
    exit 1
fi

TUNNEL_NAME="$1"
TUNNEL_TOKEN="$2"

# Validate inputs
if [ -z "$TUNNEL_NAME" ]; then
    echo "Error: Tunnel name cannot be empty"
    exit 1
fi
if [ -z "$TUNNEL_TOKEN" ]; then
    echo "Error: Tunnel token cannot be empty"
    exit 1
fi

# Check if config already exists
if [ -f "/etc/supervisor/conf.d/cloudflared-${TUNNEL_NAME}.conf" ]; then
    echo "Warning: Configuration for $TUNNEL_NAME already exists. Overwriting..."
fi

# Generate supervisord config
cat > /etc/supervisor/conf.d/cloudflared-${TUNNEL_NAME}.conf <<EOF
[program:cloudflared-${TUNNEL_NAME}]
command=/usr/local/bin/cloudflared --no-autoupdate tunnel run --token "${TUNNEL_TOKEN}"
autostart=true
autorestart=true
startsecs=5
startretries=3
stdout_logfile=/var/log/cloudflared-${TUNNEL_NAME}.log
stderr_logfile=/var/log/cloudflared-${TUNNEL_NAME}-err.log
priority=100
EOF

# Reload supervisord to apply the new config
echo "Reloading supervisord to start tunnel $TUNNEL_NAME..."
supervisorctl update || { echo "Error: Failed to reload supervisord"; exit 1; }

echo "Successfully added tunnel $TUNNEL_NAME. Check status with 'supervisorctl status'."
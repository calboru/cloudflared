#!/usr/bin/env bash
set -e

# Create directory for supervisord program configs
mkdir -p /etc/supervisor/conf.d

# Iterate through TUNNEL_ environment variables
for tunnel_var in $(env | grep '^TUNNEL_' | cut -d= -f1); do
    tunnel_token=${!tunnel_var}
    tunnel_name=${tunnel_var#TUNNEL_}  # Extract name after TUNNEL_

    # Generate supervisord config for each tunnel
    cat > /etc/supervisor/conf.d/cloudflared-${tunnel_name}.conf <<EOF
[program:cloudflared-${tunnel_name}]
command=/usr/local/bin/cloudflared --no-autoupdate tunnel run --token "${tunnel_token}"
autostart=true
autorestart=true
startsecs=5
startretries=3
stdout_logfile=/var/log/cloudflared-${tunnel_name}.log
stderr_logfile=/var/log/cloudflared-${tunnel_name}-err.log
priority=100
EOF
done

# Check if any tunnel configs were created
if [ -z "$(ls -A /etc/supervisor/conf.d)" ]; then
    echo "⚠️ No TUNNEL_ environment variables found, no tunnels configured"
else
    echo "✅ Generated supervisord configs for cloudflared tunnels"
fi

# Generate Cloudflared proxy configs
if [ -f /usr/local/bin/start_cloudflared_proxies.sh ]; then
    /usr/local/bin/start_cloudflared_proxies.sh || echo "⚠️ Proxy config script exited with nonzero code"
else
    echo "⚠️ start_cloudflared_proxies.sh not found"
fi

echo "🔄 Starting supervisord..."
# Run supervisord in foreground
exec /usr/bin/supervisord -n -c /etc/supervisord.conf
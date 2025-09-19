#!/bin/bash
set -eo pipefail

echo "✅ User: ${SSH_USER:-root}"
echo "✅ App path: ${APP_PATH:-/app}"

# Install public key (redundant with entrypoint but harmless)
if [ -n "${PUBLIC_KEY:-}" ]; then
    mkdir -p /home/${SSH_USER}/.ssh
    echo "$PUBLIC_KEY" >> /home/${SSH_USER}/.ssh/authorized_keys
    chmod 600 /home/${SSH_USER}/.ssh/authorized_keys
    chown -R ${SSH_USER}:${SSH_USER} /home/${SSH_USER}/.ssh
    echo "✅ Public key installed"
fi

echo "🚀 Generating Cloudflared proxies..."

PROXY_FOUND=0

# Ensure log directory exists
mkdir -p /var/log
chmod 755 /var/log

# Check for PROXY_ environment variables
for var in $(env | grep '^PROXY_' | cut -d= -f1); do
    val="${!var}"
    if [ -n "$val" ]; then
        PROXY_FOUND=1
        IFS='&' read -ra PARTS <<< "$val"
        declare -A PROXY_PARAMS
        for part in "${PARTS[@]}"; do
            key="${part%%=*}"
            value="${part#*=}"
            PROXY_PARAMS["$key"]="$value"
        done

        # Validate required parameters
        if [ -z "${PROXY_PARAMS[hostname]:-}" ] || [ -z "${PROXY_PARAMS[listener]:-}" ] || [ -z "${PROXY_PARAMS[destination]:-}" ]; then
            echo "⚠️ Skipping $var: Missing required parameters (hostname, listener, destination)"
            continue
        fi

        # Check if upstream service is available
        DEST_HOST=$(echo "${PROXY_PARAMS[destination]}" | sed -e 's,^tcp://,,g' | cut -d: -f1)
        DEST_PORT=$(echo "${PROXY_PARAMS[destination]}" | sed -e 's,^tcp://,,g' | cut -d: -f2)
        if ! nc -z "$DEST_HOST" "$DEST_PORT" >/dev/null 2>&1; then
            echo "⚠️ Warning: No service detected at ${PROXY_PARAMS[destination]} for $var"
        fi

        echo "🔹 Configuring proxy $var => hostname=${PROXY_PARAMS[hostname]}, listener=${PROXY_PARAMS[listener]}, destination=${PROXY_PARAMS[destination]}"

        # Build cloudflared access tcp command
        CLOUDFLARED_CMD="/usr/local/bin/cloudflared access tcp --hostname ${PROXY_PARAMS[hostname]} --destination ${PROXY_PARAMS[destination]} --listener ${PROXY_PARAMS[listener]} --loglevel debug"
        if [ -n "${PROXY_PARAMS[service-token-id]:-}" ] && [ -n "${PROXY_PARAMS[service-token-secret]:-}" ]; then
            CLOUDFLARED_CMD="$CLOUDFLARED_CMD --service-token-id ${PROXY_PARAMS[service-token-id]} --service-token-secret ${PROXY_PARAMS[service-token-secret]}"
        fi

        # Create Supervisor config with increased retries
        mkdir -p /etc/supervisor/conf.d
        cat <<EOF >/etc/supervisor/conf.d/${var}.conf
[program:${var}]
command=$CLOUDFLARED_CMD
autostart=true
autorestart=true
startsecs=10
startretries=20
stdout_logfile=/var/log/${var}.log
stderr_logfile=/var/log/${var}_err.log
priority=20
EOF
    else
        echo "⚠️ Skipping $var: Empty value"
    fi
done

if [ "$PROXY_FOUND" -eq 0 ]; then
    echo "⚠️ No valid PROXY_* variables defined, skipping cloudflared proxy setup."
fi

echo "✅ Cloudflared proxy setup complete."
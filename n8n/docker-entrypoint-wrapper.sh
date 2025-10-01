#!/bin/sh
set -e

echo "[Entrypoint] Starting Glances Web UI on internal port 61209..."
glances -w -p 61209 &

echo "[Entrypoint] Starting Nginx..."
nginx -g "daemon off;" &

# Fix ownership of n8n folder
if [ "$(stat -c %U /home/node/.n8n)" = "root" ]; then
    echo "[n8n]: Changing ownership of /home/node/.n8n to node..."
    chown -R node:node /home/node/.n8n || echo "[n8n]: Warning: Could not chown /home/node/.n8n"
fi

# Drop back to node user and run original entrypoint
exec su-exec node /docker-entrypoint.sh "$@"

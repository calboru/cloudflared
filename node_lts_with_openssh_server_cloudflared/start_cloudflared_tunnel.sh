#!/usr/bin/env bash
set -e

# Ensure TUNNEL_TOKEN is set
if [ -z "${TUNNEL_TOKEN:-}" ]; then
    echo "❌ ERROR: TUNNEL_TOKEN environment variable is required" >&2
    exit 1
fi

echo "🚀 Starting Cloudflared tunnel..." >&2

# Loop to handle immediate crash retries (optional)
while true; do
    /usr/local/bin/cloudflared tunnel --no-autoupdate run --token "$TUNNEL_TOKEN" \
        >> /proc/1/fd/1 2>> /proc/1/fd/2
    EXIT_CODE=$?
    echo "⚠️ Cloudflared exited with code $EXIT_CODE. Restarting in 2s..." >&2
    sleep 2
done

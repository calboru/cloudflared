#!/bin/sh
set -eu

# If TUNNEL_TOKEN is set, start the tunnel
if [ -n "${TUNNEL_TOKEN:-}" ]; then
    exec /usr/local/bin/cloudflared tunnel run --no-autoupdate --token "$TUNNEL_TOKEN" --output default
else
    # Keep the script alive so supervisord doesn't restart it unnecessarily
    tail -f /dev/null
fi

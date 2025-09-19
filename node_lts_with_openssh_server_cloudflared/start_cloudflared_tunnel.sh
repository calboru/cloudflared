#!/usr/bin/env bash
set -e

# Ensure TUNNEL_TOKEN is set
if [ -z "${TUNNEL_TOKEN:-}" ]; then
    echo "❌ ERROR: TUNNEL_TOKEN environment variable is required" >&2
    exit 1
fi

echo "🚀 Starting Cloudflared tunnel..." >&2

# Run cloudflared tunnel directly, let Supervisor handle retries
exec /usr/local/bin/cloudflared tunnel --no-autoupdate run --token "$TUNNEL_TOKEN"
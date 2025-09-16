#!/bin/bash

# Retrieve TUNNEL_TOKEN from environment variable
TUNNEL_TOKEN=${TUNNEL_TOKEN}

# Check if TUNNEL_TOKEN is set
if [ -z "$TUNNEL_TOKEN" ]; then
  echo "Error: TUNNEL_TOKEN is not set"
  exit 1
fi

# Start cloudflared with TUNNEL_TOKEN in the background
echo "Starting cloudflared with TUNNEL_TOKEN"
cloudflared tunnel --no-autoupdate run --token "$TUNNEL_TOKEN" &

# Run the original Jenkins entrypoint
exec /usr/bin/tini -- /usr/local/bin/jenkins.sh
#!/bin/sh

# Check if N8N_ENCRYPTION_KEY is set
if [ -z "$N8N_ENCRYPTION_KEY" ]; then
  echo "Error: N8N_ENCRYPTION_KEY is not set."
  exit 1
fi

# Set default value for MODE if not set
MODE=${MODE:-worker}

# Validate MODE
if [ "$MODE" != "worker" ] && [ "$MODE" != "webhook" ]; then
  echo "Error: MODE must be 'worker' or 'webhook'. Defaulting to 'worker'."
  MODE="worker"
fi

# Update the Supervisor config
echo "Updating Supervisor configuration for MODE=$MODE..."
sed -i "s/command=n8n .*/command=n8n $MODE/" /etc/supervisord.conf

# Output the updated config for debugging (optional)
echo "Updated Supervisor config:"
cat /etc/supervisord.conf

# Start Supervisor
echo "Starting supervisord..."
exec /opt/venv/bin/supervisord -c /etc/supervisord.conf -n
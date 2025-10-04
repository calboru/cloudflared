#!/bin/sh

# Trust custom certificates if available
if [ -d /opt/custom-certificates ]; then
  echo "Trusting custom certificates from /opt/custom-certificates."
  export NODE_OPTIONS="--use-openssl-ca $NODE_OPTIONS"
  export SSL_CERT_DIR=/opt/custom-certificates
  c_rehash /opt/custom-certificates
fi

# Check if N8N_ENCRYPTION_KEY is set
if [ -z "$N8N_ENCRYPTION_KEY" ]; then
  echo "Error: N8N_ENCRYPTION_KEY is not set."
  exit 1
fi

# Default environment variables
unset EXECUTIONS_MODE
export N8N_DISABLE_UI=false  # UI enabled by default

# Determine n8n command and mode
if [ "$N8N_EXECUTION_TYPE" = "worker" ] || [ "$N8N_EXECUTION_TYPE" = "webhook" ]; then
  export EXECUTIONS_MODE=queue
  export N8N_DISABLE_UI=true  # Disable UI in worker/webhook mode
  N8N_CMD="n8n $N8N_EXECUTION_TYPE"
  MODE_DESC="$N8N_EXECUTION_TYPE (queue mode, UI disabled)"
else
  N8N_CMD="n8n"
  MODE_DESC="default mode (UI enabled)"
fi

# Log startup mode
echo "============================"
echo "Starting n8n in $MODE_DESC"
echo "Command: $N8N_CMD"

# General information about EXECUTIONS_MODE and UI
echo "EXECUTIONS_MODE & UI info:"
echo "- Environment key: N8N_EXECUTION_TYPE"
echo "- When N8N_EXECUTION_TYPE is set to 'worker' or 'webhook':"
echo "  * EXECUTIONS_MODE is automatically set to 'queue'."
echo "  * N8N_DISABLE_UI is set to 'true' to disable the web interface."
echo "- If N8N_EXECUTION_TYPE is not set, n8n runs in default mode:"
echo "  * EXECUTIONS_MODE is unset."
echo "  * N8N_DISABLE_UI=false (UI enabled)."
echo "- Queue mode allows n8n to scale via Redis."
echo "============================"

# Update the n8n command in Supervisor config
sed -i "s|^command=n8n.*|command=$N8N_CMD|" /etc/supervisord.conf

# Debug output: show updated Supervisor config
echo "Updated Supervisor config:"
cat /etc/supervisord.conf

# Start Supervisor
exec /opt/venv/bin/supervisord -c /etc/supervisord.conf -n

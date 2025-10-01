#!/bin/bash
set -e

# Start cron for weekly updates
service cron start

# GPU check
echo "=== Checking NVIDIA GPU availability ==="
if command -v nvidia-smi &> /dev/null; then
    nvidia-smi
else
    echo "nvidia-smi not found (GPU not available in this container)"
fi

# Start Supervisor to manage Ollama, model downloader, Glances, and Nginx
exec /usr/bin/supervisord -c /etc/supervisor/conf.d/supervisord.conf

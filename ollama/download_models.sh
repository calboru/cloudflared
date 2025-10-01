#!/bin/bash
set -e

# Ensure OLLAMA_PATH is set
export OLLAMA_PATH=${OLLAMA_PATH:-/mnt/data}
export OLLAMA_MODELS=$OLLAMA_PATH

# Default model if MODELS env variable is empty
MODELS=${MODELS:-llama3.2}

# Wait until Ollama server is fully ready
MAX_RETRIES=30
SLEEP=3
echo "=== Waiting for Ollama server to be ready ==="
for i in $(seq 1 $MAX_RETRIES); do
    if curl -s http://127.0.0.1:11434/v1/health &> /dev/null; then
        echo "Ollama server is ready."
        break
    fi
    echo "Waiting for Ollama server... ($i/$MAX_RETRIES)"
    sleep $SLEEP
done

if ! curl -s http://127.0.0.1:11434/v1/health &> /dev/null; then
    echo "Ollama server did not start after $((MAX_RETRIES*SLEEP)) seconds, exiting."
    exit 1
fi

# Split comma-separated MODELS
IFS=',' read -ra MODEL_LIST <<< "$MODELS"

# Download each model
for model in "${MODEL_LIST[@]}"; do
    model=$(echo "$model" | xargs)
    if [ -n "$model" ]; then
        echo "Downloading/updating Ollama model: $model"
        ollama pull "$model"
    fi
done

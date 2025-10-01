#!/bin/bash
set -euo pipefail

echo "[Entrypoint] Starting Glances Web UI on internal port 61209..."
glances -w -p 61209 &

# Start Nginx
echo "[Entrypoint] Starting Nginx..."
nginx -g "daemon off;" &

SSH_USER="${SSH_USER:-pyuser}"
PUBLIC_KEY="${PUBLIC_KEY:-}"
SPACY_MODEL_DIR="${SPACY_MODEL_DIR:-/app/models}"

if [ -z "$PUBLIC_KEY" ]; then
    echo "ERROR: PUBLIC_KEY environment variable is required"
    exit 1
fi

# --- Create SSH user if not exists ---
if ! id "$SSH_USER" &>/dev/null; then
    useradd -m -d /home/${SSH_USER} -s /bin/bash ${SSH_USER}
fi

# --- Setup SSH authorized_keys ---
mkdir -p /home/${SSH_USER}/.ssh
echo "$PUBLIC_KEY" > /home/${SSH_USER}/.ssh/authorized_keys
chmod 700 /home/${SSH_USER}/.ssh
chmod 600 /home/${SSH_USER}/.ssh/authorized_keys
chown -R ${SSH_USER}:${SSH_USER} /home/${SSH_USER}/.ssh

# --- Configure /app ownership ---
mkdir -p /app
chown -R ${SSH_USER}:${SSH_USER} /app

# --- Ensure only this user can log in ---
if ! grep -q "AllowUsers ${SSH_USER}" /etc/ssh/sshd_config; then
    echo "AllowUsers ${SSH_USER}" >> /etc/ssh/sshd_config
fi

# --- SpaCy model setup ---
mkdir -p "$SPACY_MODEL_DIR"
chown -R ${SSH_USER}:${SSH_USER} "$SPACY_MODEL_DIR"
chmod 755 "$SPACY_MODEL_DIR"

# Safely append to PYTHONPATH
export PYTHONPATH="$SPACY_MODEL_DIR:${PYTHONPATH:-}"

# Download SpaCy model in background if missing
(
    if ! python -c "import spacy; spacy.util.get_package_path('en_core_web_sm')" &>/dev/null; then
        echo "SpaCy model 'en_core_web_sm' not found. Downloading in background..."
        python -m spacy download en_core_web_sm --target "$SPACY_MODEL_DIR"
        echo "SpaCy model download complete."
    fi
) &

# --- Start sshd in foreground immediately ---
exec "$@"

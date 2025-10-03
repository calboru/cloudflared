#!/bin/bash
set -e

SSHD_CONFIG="/etc/ssh/sshd_config"
SSH_USER=${SSH_USER:-sshuser}
CLOUDFLARED_CERT_DIR="/usr/local/etc/cloudflared"
CLOUDFLARED_CERT_PATH="$CLOUDFLARED_CERT_DIR/cert.pem"

# --------------------------------------------
# Validate required env vars
# --------------------------------------------
if [[ -z "${CLOUDFLARED_CERT:-}" || -z "${TUNNEL_TOKEN:-}" || -z "${PUBLIC_KEY:-}" ]]; then
    echo "ERROR: CLOUDFLARED_CERT, TUNNEL_TOKEN, and PUBLIC_KEY must all be set"
    exit 1
fi

# --------------------------------------------
# Write CLOUDFLARED_CERT to /usr/local/etc/cloudflared/cert.pem
# --------------------------------------------
mkdir -p "$CLOUDFLARED_CERT_DIR"
echo "$CLOUDFLARED_CERT" > "$CLOUDFLARED_CERT_PATH"
chmod 600 "$CLOUDFLARED_CERT_PATH"
echo "[entrypoint] Wrote CLOUDFLARED_CERT to $CLOUDFLARED_CERT_PATH"

# --------------------------------------------
# Ensure home & .ssh directories
# --------------------------------------------
mkdir -p /home/$SSH_USER/.ssh
chown $SSH_USER:$SSH_USER /home/$SSH_USER
chmod 755 /home/$SSH_USER

# --------------------------------------------
# Handle public key
# --------------------------------------------
echo "$PUBLIC_KEY" > /home/$SSH_USER/.ssh/authorized_keys
chown $SSH_USER:$SSH_USER /home/$SSH_USER/.ssh/authorized_keys
chmod 600 /home/$SSH_USER/.ssh/authorized_keys
echo "[run_sshd] Public key written to /home/$SSH_USER/.ssh/authorized_keys"

# --------------------------------------------
# Generate host keys if missing
# --------------------------------------------
ssh-keygen -A

# Test SSH config
sshd -t -f "$SSHD_CONFIG"

# --------------------------------------------
# Setup cloudflared programs before Supervisor
# --------------------------------------------
if [ -x /usr/local/bin/setup_cloudflared.sh ]; then
    echo "[entrypoint] Running setup_cloudflared.sh..."
    /usr/local/bin/setup_cloudflared.sh
else
    echo "[entrypoint] setup_cloudflared.sh not found or not executable"
fi

# --------------------------------------------
# Start Supervisor as the main process
# --------------------------------------------
echo "[entrypoint] Starting supervisord..."
exec /opt/venv/bin/supervisord -n -c /etc/supervisor/supervisord.conf

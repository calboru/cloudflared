#!/bin/sh
set -eu

# --------------------------------------------
# Check required environment variable
# --------------------------------------------
if [ -z "${JENKINS_AGENT_SSH_PUBKEY:-}" ]; then
  echo "❌ ERROR: JENKINS_AGENT_SSH_PUBKEY is not set, exiting"
  exit 1
fi

# --------------------------------------------
# Ensure jenkins user is unlocked
# --------------------------------------------
if getent passwd jenkins >/dev/null 2>&1; then
  echo "🔓 Ensuring jenkins user is unlocked..."
  # Set a valid dummy SHA-512 password hash so the account is active but unusable
  echo "jenkins:dummy" | chpasswd --crypt-method SHA512 || true
  passwd -u jenkins >/dev/null 2>&1 || true
  # As a safety net, strip leading "!" if it persists in /etc/shadow
  sed -i 's/^jenkins:!*/jenkins:*/' /etc/shadow
else
  echo "⚠️ jenkins user does not exist!"
  exit 1
fi

# --------------------------------------------
# Setup home directory and SSH
# --------------------------------------------
HOME_DIR="/home/jenkins"
mkdir -p "$HOME_DIR/.ssh"

# Ensure perms
chmod 755 "$HOME_DIR"
chmod 700 "$HOME_DIR/.ssh"
chown -R jenkins:jenkins "$HOME_DIR"

# Install authorized_keys (avoid duplicates)
grep -qxF "$JENKINS_AGENT_SSH_PUBKEY" "$HOME_DIR/.ssh/authorized_keys" 2>/dev/null || \
  echo "$JENKINS_AGENT_SSH_PUBKEY" >> "$HOME_DIR/.ssh/authorized_keys"

chmod 600 "$HOME_DIR/.ssh/authorized_keys"
chown jenkins:jenkins "$HOME_DIR/.ssh/authorized_keys"

echo "✅ SSH key installed for jenkins user"

# --------------------------------------------
# Ensure JAVA_HOME and PATH are available
# --------------------------------------------
if [ -z "${JAVA_HOME:-}" ]; then
  JAVA_BIN=$(command -v java || true)
  if [ -n "$JAVA_BIN" ]; then
    JAVA_HOME=$(dirname "$(dirname "$(readlink -f "$JAVA_BIN")")")
    export JAVA_HOME
    echo "🔎 Auto-detected JAVA_HOME=$JAVA_HOME"
  else
    echo "⚠️ Java not found in PATH, Jenkins agent may fail"
  fi
fi

if [ -n "${JAVA_HOME:-}" ]; then
  grep -qxF "JAVA_HOME=$JAVA_HOME" /etc/environment || echo "JAVA_HOME=$JAVA_HOME" >> /etc/environment
fi

grep -qxF "PATH=$PATH" /etc/environment || echo "PATH=$PATH" >> /etc/environment

# Create sshd per-user environment (requires PermitUserEnvironment yes in sshd_config)
if [ -n "${JAVA_HOME:-}" ]; then
  {
    echo "JAVA_HOME=$JAVA_HOME"
    echo "PATH=$JAVA_HOME/bin:/usr/local/bin:/usr/bin:/bin"
  } > "$HOME_DIR/.ssh/environment"
  chown jenkins:jenkins "$HOME_DIR/.ssh/environment"
  chmod 600 "$HOME_DIR/.ssh/environment"
  echo "✅ SSH per-user environment written to $HOME_DIR/.ssh/environment"
fi

# --------------------------------------------
# Start supervisord in foreground
# --------------------------------------------
echo "🔄 Starting supervisord..."
exec /usr/local/bin/supervisord -n -c /etc/supervisord.conf

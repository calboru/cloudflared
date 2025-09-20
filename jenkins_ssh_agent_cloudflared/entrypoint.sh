#!/bin/sh
set -eu

# Check if JENKINS_AGENT_SSH_PUBKEY is set, or exit
if [ -z "${JENKINS_AGENT_SSH_PUBKEY:-}" ]; then
  echo "JENKINS_AGENT_SSH_PUBKEY is not set exiting"
  exit 1
fi

# Unlock the jenkins user account by setting a placeholder password
usermod -p '*' jenkins >/dev/null 2>&1 || true

# Ensure the jenkins user's home directory has correct ownership and permissions
chown jenkins:jenkins /home/jenkins
chmod 755 /home/jenkins

# Create .ssh directory if it doesn't exist, and set correct ownership and permissions
mkdir -p /home/jenkins/.ssh
chown jenkins:jenkins /home/jenkins/.ssh
chmod 700 /home/jenkins/.ssh

# Create authorized_keys file, write the public key, and set correct ownership and permissions
echo "$JENKINS_AGENT_SSH_PUBKEY" > /home/jenkins/.ssh/authorized_keys
chown jenkins:jenkins /home/jenkins/.ssh/authorized_keys
chmod 600 /home/jenkins/.ssh/authorized_keys

#Start cron for log rotation
cron


# Generate Cloudflared proxy configs
if [ -f /usr/local/bin/start_cloudflared_proxies.sh ]; then
    /usr/local/bin/start_cloudflared_proxies.sh || echo "⚠️ Proxy config script exited with nonzero code"
else
    echo "⚠️ start_cloudflared_proxies.sh not found"
fi

echo "🔄 Starting supervisord..."
# Run supervisord in foreground
/usr/bin/supervisord -n -c /etc/supervisord.conf &

# Keep container running
wait
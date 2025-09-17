#!/bin/sh
set -eu

# Retrieve TUNNEL_TOKEN from environment variable
TUNNEL_TOKEN=${TUNNEL_TOKEN:-}


# Check if TUNNEL_TOKEN is set
if [ -z "$TUNNEL_TOKEN" ]; then
  echo "TUNNEL_TOKEN is not set skipping cloudflared tunnel"
fi

# Check if JENKINS_AGENT_SSH_PUBKEY is set, or exit
if [ -z "${JENKINS_AGENT_SSH_PUBKEY:-}" ]; then
  echo "JENKINS_AGENT_SSH_PUBKEY is not set exiting"
  exit 1
fi

# Check if TUNNEL_TOKEN is set
if [ -z "$TUNNEL_TOKEN" ]; then
  echo "TUNNEL_TOKEN is not set"
fi

# Start cloudflared with TUNNEL_TOKEN in the background if TUNNEL_TOKEN is set
if [ -n "$TUNNEL_TOKEN" ]; then
  echo "Starting cloudflared with TUNNEL_TOKEN"
  /usr/local/bin/cloudflared tunnel --no-autoupdate run --token "$TUNNEL_TOKEN" &
  # Save PID so we can monitor/kill if needed
  CLOUDFLARED_PID=$!
fi



# Optionally wait a short time to ensure cloudflared started
sleep 1

# Ensure the jenkins user's home directory has correct ownership and permissions
chown jenkins:jenkins /home/jenkins
chmod 755 /home/jenkins

# Create .ssh directory if it doesn't exist, and set correct ownership and permissions
mkdir -p /home/jenkins/.ssh
chown jenkins:jenkins /home/jenkins/.ssh
chmod 700 /home/jenkins/.ssh

# Create authorized_keys file if it doesn't exist, and set correct ownership and permissions
touch /home/jenkins/.ssh/authorized_keys
chown jenkins:jenkins /home/jenkins/.ssh/authorized_keys
chmod 600 /home/jenkins/.ssh/authorized_keys

# Run add_proxy_hosts.sh as jenkins user
if [ -x /usr/local/bin/add_proxy_hosts.sh ]; then
    runuser -u jenkins -- /usr/local/bin/add_proxy_hosts.sh
fi

# Exec the original setup-sshd so it becomes PID 1 (replaces this shell).
# This preserves the original behavior of the upstream image.
# If setup-sshd is at a different path in your base image, change accordingly.
exec /usr/local/bin/setup-sshd
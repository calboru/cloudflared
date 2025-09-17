#!/bin/sh
set -eu

# Retrieve TUNNEL_TOKEN from environment variable
TUNNEL_TOKEN=${TUNNEL_TOKEN:-}

# Check if TUNNEL_TOKEN is set
if [ -z "$TUNNEL_TOKEN" ]; then
  echo "Error: TUNNEL_TOKEN is not set"
  exit 1
fi

# Start cloudflared with TUNNEL_TOKEN in the background
echo "Starting cloudflared with TUNNEL_TOKEN"
/usr/local/bin/cloudflared tunnel --no-autoupdate run --token "$TUNNEL_TOKEN" &

# Save PID so we can monitor/kill if needed
CLOUDFLARED_PID=$!

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

# Exec the original setup-sshd so it becomes PID 1 (replaces this shell).
# This preserves the original behavior of the upstream image.
# If setup-sshd is at a different path in your base image, change accordingly.
exec /usr/local/bin/setup-sshd
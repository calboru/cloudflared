#!/bin/sh
set -eu

# --------------------------------------------
# Check required environment variable
# --------------------------------------------
if [ -z "${JENKINS_AGENT_SSH_PUBKEY:-}" ]; then
  echo "JENKINS_AGENT_SSH_PUBKEY is not set, exiting"
  exit 1
fi

# --------------------------------------------
# Unlock Jenkins user account (placeholder password)
# --------------------------------------------
usermod -p '*' jenkins >/dev/null 2>&1 || true

# --------------------------------------------
# Setup home directory and SSH
# --------------------------------------------
chown -R jenkins:jenkins /home/jenkins
chmod 755 /home/jenkins

mkdir -p /home/jenkins/.ssh
chown jenkins:jenkins /home/jenkins/.ssh
chmod 700 /home/jenkins/.ssh

echo "$JENKINS_AGENT_SSH_PUBKEY" > /home/jenkins/.ssh/authorized_keys
chown jenkins:jenkins /home/jenkins/.ssh/authorized_keys
chmod 600 /home/jenkins/.ssh/authorized_keys

# --------------------------------------------
# Set Java environment for all users
# --------------------------------------------
export JAVA_HOME=/opt/java/openjdk
export PATH=$JAVA_HOME/bin:$PATH

echo "export JAVA_HOME=$JAVA_HOME" > /etc/profile.d/java.sh
echo "export PATH=\$JAVA_HOME/bin:\$PATH" >> /etc/profile.d/java.sh
chmod +x /etc/profile.d/java.sh

# --------------------------------------------
# Start supervisord in foreground
# --------------------------------------------
echo "🔄 Starting supervisord..."
exec /usr/local/bin/supervisord -n -c /etc/supervisord.conf

FROM jenkins/ssh-agent:latest

USER root

# --------------------------------------------
# retry_apt script for reliable installs
# --------------------------------------------
RUN echo '#!/bin/bash' > /usr/local/bin/retry_apt && \
    echo 'while true; do apt-get clean && apt-get update && [ -z "$@" ] || apt-get install -y --no-install-recommends -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" "$@" && break || { echo "Retrying apt-get $@ ..."; rm -rf /var/lib/apt/lists/* /var/cache/apt/archives/*; sleep 1; }; done' >> /usr/local/bin/retry_apt && \
    chmod +x /usr/local/bin/retry_apt

# --------------------------------------------
# Install base tools individually
# --------------------------------------------
RUN retry_apt wget
RUN retry_apt nano
RUN retry_apt iputils-ping
RUN retry_apt curl
RUN retry_apt ca-certificates
RUN retry_apt rsync
RUN retry_apt git
RUN retry_apt python3
RUN retry_apt python3-pip
RUN retry_apt nginx
RUN retry_apt apache2-utils
RUN retry_apt nodejs

 

ENV JAVA_HOME=/opt/java/openjdk
ENV PATH=$JAVA_HOME/bin:$PATH

# --------------------------------------------
# Install Node.js tools
# --------------------------------------------
RUN curl -fsSL https://www.npmjs.com/install.sh | sh
RUN npm install -g pnpm

# Verify Node + Java
RUN node -v && npm -v && pnpm -v && java -version

# --------------------------------------------
# Install Python packages
# --------------------------------------------
RUN python3 -m pip install --no-cache-dir --break-system-packages -i https://pypi.org/simple glances[web]
RUN python3 -m pip install --no-cache-dir --break-system-packages supervisor

# --------------------------------------------
# SSH & Nginx setup
# --------------------------------------------
RUN ssh-keygen -A

COPY sshd_config /etc/ssh/sshd_config
COPY nginx.conf /etc/nginx/nginx.conf
COPY .htpasswd /etc/nginx/.htpasswd
RUN chmod 644 /etc/nginx/.htpasswd

COPY supervisord.conf /etc/supervisord.conf
COPY glances.conf /etc/glances/glances.conf

# --------------------------------------------
# Entrypoint and working directory
# --------------------------------------------
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

EXPOSE 22 61208
WORKDIR /home/jenkins
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]

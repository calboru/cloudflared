FROM jenkins/ssh-agent:latest

USER root

# retry_apt globally
RUN echo '#!/bin/bash' > /usr/local/bin/retry_apt && \
    echo 'while true; do apt-get clean && apt-get update && [ -z "$@" ] || apt-get install -y --no-install-recommends -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" "$@" && break || { echo "Retrying apt-get $@ ..."; rm -rf /var/lib/apt/lists/* /var/cache/apt/archives/*; sleep 1; }; done' >> /usr/local/bin/retry_apt && \
    chmod +x /usr/local/bin/retry_apt

 
 
RUN retry_apt wget
RUN retry_apt nano
RUN retry_apt iputils-ping
RUN retry_apt curl
RUN retry_apt ca-certificates
RUN retry_apt rsync
RUN retry_apt git
RUN retry_apt python3-pip
RUN /usr/local/bin/retry_apt python3
RUN /usr/local/bin/retry_apt python3-pip
RUN /usr/local/bin/retry_apt nginx
RUN /usr/local/bin/retry_apt apache2-utils
RUN /usr/local/bin/retry_apt ca-certificates 
 
 

# Install Node.js LTS and npm explicitly
# RUN curl -fsSL https://deb.nodesource.com/setup_lts.x | bash - && \
#     apt-get update --allow-releaseinfo-change && \
#     apt-get install -y --no-install-recommends nodejs && \
#     rm -rf /var/lib/apt/lists/*

# Install Node.js LTS
RUN curl -fsSL https://deb.nodesource.com/setup_lts.x | bash - && \
    apt-get update --allow-releaseinfo-change && \
    apt-get install -y --no-install-recommends nodejs curl && \
    rm -rf /var/lib/apt/lists/*

# Install npm separately
RUN curl -fsSL https://www.npmjs.com/install.sh | sh

# Install pnpm globally via npm
RUN npm install -g pnpm

# Verify
RUN node -v && npm -v && pnpm -v

 
RUN python3 -m pip install --no-cache-dir --break-system-packages -i https://pypi.org/simple glances[web] supervisor

# Generate SSH host keys
RUN ssh-keygen -A

# Copy scripts
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

COPY supervisord.conf /etc/supervisord.conf
COPY sshd_config /etc/ssh/sshd_config
COPY nginx.conf /etc/nginx/nginx.conf
COPY .htpasswd /etc/nginx/.htpasswd
RUN chmod 644 /etc/nginx/.htpasswd
COPY glances.conf /etc/glances/glances.conf

# Set custom entrypoint
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]

EXPOSE 22 61208
WORKDIR /home/jenkins

 
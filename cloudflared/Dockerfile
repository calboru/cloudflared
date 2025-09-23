FROM alpine:latest

# Install bash and other required packages
RUN apk add --no-cache \
    bash \
    curl \
    wget \
    nano \
    iputils \
    supervisor \
    logrotate \
    openrc \
    && rm -rf /var/cache/apk/*

# Detect architecture and download appropriate cloudflared binary
RUN ARCH=$(uname -m) && \
    if [ "$ARCH" = "x86_64" ]; then \
        curl -L https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64 -o /usr/local/bin/cloudflared; \
    elif [ "$ARCH" = "aarch64" ]; then \
        curl -L https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-arm64 -o /usr/local/bin/cloudflared; \
    else \
        echo "Unsupported architecture: $ARCH" && exit 1; \
    fi && \
    chmod +x /usr/local/bin/cloudflared

# Create log directory
RUN mkdir -p /var/log && chmod -R 755 /var/log

# Ensure cron directory and logrotate script exist
RUN mkdir -p /etc/cron.daily && \
    echo '#!/bin/sh\n/usr/sbin/logrotate /etc/logrotate.conf' > /etc/cron.daily/logrotate && \
    chmod +x /etc/cron.daily/logrotate

# Copy configs and scripts
COPY supervisord.conf /etc/supervisord.conf
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
COPY add_tunnel.sh /usr/local/bin/add_tunnel.sh
RUN chmod +x /usr/local/bin/entrypoint.sh /usr/local/bin/add_tunnel.sh

# Copy logrotate configuration
COPY logrotate.conf /etc/logrotate.conf

# Set bash as the default shell
SHELL ["/bin/bash", "-c"]

# Set entrypoint
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
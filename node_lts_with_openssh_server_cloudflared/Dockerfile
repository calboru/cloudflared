FROM alpine:latest

# Use root
USER root

# Install required packages
RUN apk add --no-cache \
    openssh \
    bash \
    curl \
    ca-certificates \
    wget \
    nano \
    iputils \
    nodejs \
    npm \
    py3-pip \
    supervisor \
    && rm -rf /var/cache/apk/*

# Install cloudflared
RUN ARCH=$(uname -m) && \
    if [ "$ARCH" = "x86_64" ]; then \
        wget -q -O /usr/local/bin/cloudflared https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64; \
    elif [ "$ARCH" = "aarch64" ] || [ "$ARCH" = "arm64" ]; then \
        wget -q -O /usr/local/bin/cloudflared https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-arm64; \
    else \
        echo "Unsupported architecture: $ARCH" && exit 1; \
    fi && chmod +x /usr/local/bin/cloudflared

# Install pnpm and pm2 globally
RUN npm install -g pnpm pm2

# Generate SSH host keys
RUN ssh-keygen -A

# Copy configs and entrypoint
COPY sshd_config /etc/ssh/sshd_config
COPY supervisord.conf /etc/supervisord.conf
COPY entrypoint.sh /usr/local/bin/entrypoint.sh

# Make entrypoint executable
RUN chmod +x /usr/local/bin/entrypoint.sh

# Copy Cloudflared start script
COPY start_cloudflared_tunnel.sh /usr/local/bin/start_cloudflared_tunnel.sh
RUN chmod +x /usr/local/bin/start_cloudflared_tunnel.sh

# Expose SSH and app port
EXPOSE 22 3000

# Default entrypoint
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]

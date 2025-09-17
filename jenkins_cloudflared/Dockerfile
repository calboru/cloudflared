FROM jenkins/jenkins

USER root

ENV JENKINS_HOME=/mnt/data

# Make jenkins UID/GID match root
RUN usermod -u 0 -o jenkins && \
    groupmod -g 0 -o jenkins

# Install dependencies and cloudflared
RUN apt-get update && apt-get install -y wget iputils-ping nano ca-certificates && rm -rf /var/lib/apt/lists/* \
    && ARCH=$(uname -m) && \
    if [ "$ARCH" = "x86_64" ]; then \
        wget -q -O /usr/local/bin/cloudflared https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64; \
    elif [ "$ARCH" = "aarch64" ]; then \
        wget -q -O /usr/local/bin/cloudflared https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-arm64; \
    else \
        echo "Unsupported architecture: $ARCH" && exit 1; \
    fi \
    && chmod +x /usr/local/bin/cloudflared

# Create entrypoint script
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Now Jenkins runs as UID 0 but username is still 'jenkins'
USER jenkins

# Use custom entrypoint script
ENTRYPOINT ["/bin/sh", "-c", "/entrypoint.sh"]

EXPOSE 8080 50000
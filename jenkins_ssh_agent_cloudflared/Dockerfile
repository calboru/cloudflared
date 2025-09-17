FROM jenkins/ssh-agent:latest

USER root

# Configure Debian Trixie sources and apt retries
RUN echo 'deb http://ftp.us.debian.org/debian trixie main' > /etc/apt/sources.list && \
    echo 'deb http://security.debian.org/debian-security trixie-security main' >> /etc/apt/sources.list && \
    echo 'deb http://ftp.us.debian.org/debian trixie-updates main' >> /etc/apt/sources.list && \
    echo 'Acquire::Retries "3";' > /etc/apt/apt.conf.d/80-retries

# Install apt packages
RUN apt-get clean && \
    rm -rf /var/lib/apt/lists/* && \
    apt-get update --allow-releaseinfo-change && \
    apt-get install -y --no-install-recommends \
        wget \
        nano \
        iputils-ping \
        curl \
        ca-certificates \
        rsync \
        nodejs \
        npm && \
    rm -rf /var/lib/apt/lists/*

# Install Node.js LTS and npm explicitly
RUN curl -fsSL https://deb.nodesource.com/setup_lts.x | bash - && \
    apt-get update --allow-releaseinfo-change && \
    apt-get install -y --no-install-recommends nodejs && \
    rm -rf /var/lib/apt/lists/*

# Install pnpm globally using npm
RUN npm install -g pnpm    

# Install cloudflared for the current architecture
RUN ARCH=$(uname -m) && \
    if [ "$ARCH" = "x86_64" ]; then \
        wget -q -O /usr/local/bin/cloudflared https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64; \
    elif [ "$ARCH" = "aarch64" ] || [ "$ARCH" = "arm64" ]; then \
        wget -q -O /usr/local/bin/cloudflared https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-arm64; \
    else \
        echo "Unsupported architecture: $ARCH" && exit 1; \
    fi && \
    chmod +x /usr/local/bin/cloudflared

# Copy scripts
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
COPY add_proxy_hosts.sh /usr/local/bin/add_proxy_hosts.sh
RUN chmod +x /usr/local/bin/entrypoint.sh /usr/local/bin/add_proxy_hosts.sh

# Set custom entrypoint
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]

EXPOSE 22
WORKDIR /home/jenkins

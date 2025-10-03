FROM alpine:latest

# Install required packages
RUN apk add --no-cache \
    bash \
    curl \
    wget \
    nano \
    coreutils \
    iputils \
    openrc \
    openssh \
    sudo \
    py3-pip \
    rsync \
    nginx \
    apache2-utils \
    python3 \
    python3-dev \
    gcc \
    musl-dev \
    linux-headers \
    && rm -rf /var/cache/apk/*

# Persistent directories
RUN mkdir -p /mnt/data/supervisord /var/run/sshd 

# Add SSH user and allow sudo for supervisorctl
ENV SSH_USER=sshuser

RUN adduser -D -s /bin/bash "$SSH_USER" && \
    passwd -u "$SSH_USER" && \
    echo "$SSH_USER ALL=(ALL) NOPASSWD: /opt/venv/bin/supervisorctl -c /mnt/data/supervisord/supervisord.conf restart cloudflared, \
    /opt/venv/bin/supervisorctl -c /mnt/data/supervisord/supervisord.conf status cloudflared" > /etc/sudoers.d/sshuser_supervisor && \
    chmod 440 /etc/sudoers.d/sshuser_supervisor

# Download cloudflared to /mnt/data
RUN ARCH=$(uname -m) && \
    if [ "$ARCH" = "x86_64" ]; then \
        curl -L https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64 -o /mnt/data/cloudflared; \
    elif [ "$ARCH" = "aarch64" ]; then \
        curl -L https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-arm64 -o /mnt/data/cloudflared; \
    else \
        echo "Unsupported architecture: $ARCH" && exit 1; \
    fi && chmod +x /mnt/data/cloudflared


    
# Copy supervisord config
COPY supervisord.conf /etc/supervisor/supervisord.conf

# Copy SSH config and run scripts
COPY sshd_config /etc/ssh/sshd_config
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
COPY setup_cloudflared.sh /usr/local/bin/setup_cloudflared.sh

# Make scripts executable
RUN chmod +x /usr/local/bin/entrypoint.sh /usr/local/bin/setup_cloudflared.sh

# Glances config
COPY nginx.conf /etc/nginx/nginx.conf
COPY .htpasswd /etc/nginx/.htpasswd
RUN chmod 644 /etc/nginx/.htpasswd


# Runtime injection of PUBLIC_KEY
ENV PUBLIC_KEY=""

# Python venv + Glances + Supervisor
RUN python3 -m venv /opt/venv \
 && /opt/venv/bin/pip install --no-cache-dir --upgrade pip setuptools wheel \
 && /opt/venv/bin/pip install --no-cache-dir glances[web] supervisor

# Generate SSH host keys
RUN ssh-keygen -A

# Expose ports
EXPOSE 22 61208

ENTRYPOINT [ "/usr/local/bin/entrypoint.sh" ]


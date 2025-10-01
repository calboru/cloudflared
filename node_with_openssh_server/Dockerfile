FROM alpine:latest

ENV SSH_USER=sshuser
ENV APP_PATH=/app

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
    rsync \
    nginx \
    apache2-utils \
    python3 \
    python3-dev \
    gcc \
    musl-dev \
    linux-headers \
    && rm -rf /var/cache/apk/*

# Install pnpm and pm2 globally
RUN npm install -g pnpm pm2

# Generate SSH host keys
RUN ssh-keygen -A

# Setup Python virtual environment for Glances
RUN python3 -m venv /opt/venv \
    && /opt/venv/bin/pip install --no-cache-dir --upgrade pip \
    && /opt/venv/bin/pip install --no-cache-dir glances[web] passlib

ENV PATH="/opt/venv/bin:$PATH"

# Copy configs and entrypoint
COPY sshd_config /etc/ssh/sshd_config
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
COPY nginx.conf /etc/nginx/nginx.conf
COPY .htpasswd /etc/nginx/.htpasswd

RUN chmod +x /usr/local/bin/entrypoint.sh \
    && chmod 644 /etc/nginx/.htpasswd

# Expose SSH, app ports, Glances/Nginx
EXPOSE 22 3000-3010 61208

# Default entrypoint
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]

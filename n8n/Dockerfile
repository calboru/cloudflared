# Base image
FROM n8nio/n8n:latest

USER root

ENV EXECUTIONS_MODE=queue

# Verify /bin/sh exists
RUN ls -l /bin/sh || echo "/bin/sh not found"

# Install system dependencies
RUN apk add --no-cache \
    python3 \
    py3-pip \
    gcc \
    musl-dev \
    python3-dev \
    linux-headers \
    postgresql-client \
    nginx \
    apache2-utils

# Create virtual environment for glances and supervisor
RUN python3 -m venv /opt/venv \
 && /opt/venv/bin/pip install --no-cache-dir --upgrade pip setuptools wheel \
 && /opt/venv/bin/pip install --no-cache-dir glances[web] supervisor \
 && /opt/venv/bin/pip show supervisor \
 && ls -l /opt/venv/bin/ | grep supervisord || echo "supervisord not found in /opt/venv/bin"

# Add virtual environment to PATH
ENV PATH="/opt/venv/bin:$PATH"

# Copy configs and entrypoint script
COPY supervisord.conf /etc/supervisord.conf
COPY nginx.conf /etc/nginx/nginx.conf
COPY glances.conf /etc/glances/glances.conf
COPY .htpasswd /etc/nginx/.htpasswd
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh \
 && chmod 644 /etc/nginx/.htpasswd

# Create log directories
RUN mkdir -p /var/log/supervisor /var/log/nginx \
 && chown -R node:node /var/log/supervisor /var/log/nginx

# Enforce n8n permissions
ENV N8N_ENFORCE_SETTINGS_FILE_PERMISSIONS=true

# Expose ports
EXPOSE 61208

# Use entrypoint script
ENTRYPOINT ["/entrypoint.sh"]
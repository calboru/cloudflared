FROM n8nio/n8n:latest

USER root

# Install dependencies: build tools, Python, Nginx, htpasswd
RUN apk add --no-cache \
    su-exec nano iputils curl python3 python3-dev gcc musl-dev linux-headers \
    nginx apache2-utils bash

# Create virtual environment for Glances
RUN python3 -m venv /opt/venv

# Activate venv and install Glances + passlib
RUN /opt/venv/bin/pip install --no-cache-dir --upgrade pip \
    && /opt/venv/bin/pip install --no-cache-dir glances[web] passlib

# Add venv to PATH
ENV PATH="/opt/venv/bin:$PATH"

# Ensure mounted folder exists
RUN mkdir -p /home/node/.n8n

# Copy wrapper entrypoint
COPY docker-entrypoint-wrapper.sh /usr/local/bin/docker-entrypoint-wrapper.sh
RUN chmod +x /usr/local/bin/docker-entrypoint-wrapper.sh

# Copy Nginx config and htpasswd
COPY nginx.conf /etc/nginx/nginx.conf
COPY .htpasswd /etc/nginx/.htpasswd
RUN chmod 644 /etc/nginx/.htpasswd

# Expose ports
EXPOSE 5678     
EXPOSE 61208   

WORKDIR /home/node

ENTRYPOINT ["tini", "--", "/usr/local/bin/docker-entrypoint-wrapper.sh"]

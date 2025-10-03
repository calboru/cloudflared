FROM mongodb/mongodb-community-server:latest

USER root

# Install dependencies
RUN set -eux; \
    packages="iputils-ping nano curl git gosu wget python3 python3-pip python3-psutil python3-passlib lm-sensors procps nginx apache2-utils python3-venv"; \
    apt-get update; \
    for pkg in $packages; do apt-get install -y --no-install-recommends "$pkg"; done; \
    rm -rf /var/lib/apt/lists/*


RUN python3 -m venv /opt/venv \
 && /opt/venv/bin/pip install --no-cache-dir --upgrade pip setuptools wheel \
 && /opt/venv/bin/pip install --no-cache-dir glances[web] supervisor


# Copy configs and entrypoint
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

COPY supervisord.conf /etc/supervisord.conf
COPY glances.conf /etc/glances/glances.conf
COPY nginx.conf /etc/nginx/nginx.conf
COPY .htpasswd /etc/nginx/.htpasswd
RUN chmod 644 /etc/nginx/.htpasswd

EXPOSE 27017 28017 61208

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["/opt/venv/bin/supervisord", "-c", "/etc/supervisord.conf"]

FROM mongodb/mongodb-community-server:latest

USER root

# Install dependencies
RUN set -eux; \
    # List of Debian packages to install
    packages="iputils-ping nano curl git gosu wget python3 python3-pip python3-psutil python3-passlib lm-sensors procps nginx apache2-utils"; \
    \
    # Update and install packages
    apt-get update; \
    for pkg in $packages; do \
        apt-get install -y --no-install-recommends "$pkg"; \
    done; \
    \
    # Install Python packages for Glances
    pip3 install --no-cache-dir glances[web] bottle; \
    \
    # Clean up apt cache
    rm -rf /var/lib/apt/lists/*


# Copy wrapper entrypoint
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

# Glances config (internal, optional)
COPY glances.conf /etc/glances/glances.conf
 

# Copy Nginx config and password file
COPY nginx.conf /etc/nginx/sites-enabled/default
COPY .htpasswd /etc/nginx/.htpasswd
RUN chmod 644 /etc/nginx/.htpasswd

EXPOSE 27017 28017 61208

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]

CMD ["mongod"]

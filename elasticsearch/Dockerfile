# Base image
FROM ubuntu:24.04

ARG ES_VERSION=9.1.4

ENV ES_HOME=/usr/share/elasticsearch \
    ES_JAVA_OPTS="-Xms512m -Xmx512m" \
    PATH=$PATH:/usr/share/elasticsearch/bin \
    ES__CLUSTER_NAME=docker-cluster \
    ES__NODE_NAME=node-1 \
    ES__DISCOVERY_TYPE=single-node \
    ES__NETWORK_HOST=0.0.0.0 \
    ES__PATH_DATA=/mnt/data \
    ES__PATH_LOGS=/mnt/data/logs \
    ES__HTTP_PORT=9200 \
    ES__TRANSPORT_PORT=9300 \
    ES__XPACK_SECURITY_ENABLED=true \
    DEBIAN_FRONTEND=noninteractive

SHELL ["/bin/bash", "-c"]

# ---------------------------
# retry_apt globally
# ---------------------------
RUN echo '#!/bin/bash' > /usr/local/bin/retry_apt && \
    echo 'while true; do apt-get clean && apt-get update && [ -z "$@" ] || apt-get install -y --no-install-recommends -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" "$@" && break || { echo "Retrying apt-get $@ ..."; rm -rf /var/lib/apt/lists/* /var/cache/apt/archives/*; sleep 1; }; done' >> /usr/local/bin/retry_apt && \
    chmod +x /usr/local/bin/retry_apt


# Update sources & upgrade
RUN rm -rf /var/lib/apt/lists/* /var/cache/apt/archives/* && \
    if [ "$(dpkg --print-architecture)" = "amd64" ]; then \
        echo "deb http://archive.ubuntu.com/ubuntu/ noble main restricted universe multiverse" > /etc/apt/sources.list && \
        echo "deb http://archive.ubuntu.com/ubuntu/ noble-updates main restricted universe multiverse" >> /etc/apt/sources.list && \
        echo "deb http://archive.ubuntu.com/ubuntu/ noble-security main restricted universe multiverse" >> /etc/apt/sources.list; \
    else \
        echo "deb http://ports.ubuntu.com/ubuntu-ports/ noble main restricted universe multiverse" > /etc/apt/sources.list && \
        echo "deb http://ports.ubuntu.com/ubuntu-ports/ noble-updates main restricted universe multiverse" >> /etc/apt/sources.list && \
        echo "deb http://ports.ubuntu.com/ubuntu-ports/ noble-security main restricted universe multiverse" >> /etc/apt/sources.list; \
    fi && \
    apt-get upgrade -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold"

# Install system packages individually
# ---------------------------
RUN /usr/local/bin/retry_apt curl
RUN /usr/local/bin/retry_apt gnupg
RUN /usr/local/bin/retry_apt gosu
RUN /usr/local/bin/retry_apt ca-certificates
RUN /usr/local/bin/retry_apt openjdk-17-jdk-headless
RUN /usr/local/bin/retry_apt bash
RUN /usr/local/bin/retry_apt procps
RUN /usr/local/bin/retry_apt iputils-ping
RUN /usr/local/bin/retry_apt nano
RUN /usr/local/bin/retry_apt python3
RUN /usr/local/bin/retry_apt python3-pip
RUN /usr/local/bin/retry_apt nginx
RUN /usr/local/bin/retry_apt apache2-utils

# Python packages
RUN python3 -m pip install --no-cache-dir --break-system-packages -i https://pypi.org/simple glances[web] supervisor


# Create Elasticsearch user/group
RUN groupadd -g 2000 elasticsearch && \
    useradd -r -u 2000 -g elasticsearch elasticsearch

# Download and install Elasticsearch
RUN ARCH="$(dpkg --print-architecture)"; \
    case "$ARCH" in \
        amd64) ES_ARCH=linux-x86_64 ;; \
        arm64) ES_ARCH=linux-aarch64 ;; \
        *) echo "Unsupported architecture: $ARCH"; exit 1 ;; \
    esac; \
    curl -fsSL -o /tmp/elasticsearch.tar.gz "https://artifacts.elastic.co/downloads/elasticsearch/elasticsearch-$ES_VERSION-$ES_ARCH.tar.gz"; \
    tar -xzf /tmp/elasticsearch.tar.gz -C /usr/share/; \
    mv /usr/share/elasticsearch-$ES_VERSION $ES_HOME; \
    rm /tmp/elasticsearch.tar.gz; \
    chown -R elasticsearch:elasticsearch $ES_HOME

# Create persistent directories
RUN mkdir -p /mnt/data /mnt/data/logs && \
    chown -R elasticsearch:elasticsearch /mnt/data

# Glances config
COPY glances.conf /etc/glances/glances.conf

# Copy Nginx config and password file
COPY nginx.conf /etc/nginx/sites-enabled/default
COPY .htpasswd /etc/nginx/.htpasswd
RUN chmod 644 /etc/nginx/.htpasswd

# Copy entrypoint
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

COPY supervisord.conf /etc/supervisor/supervisord.conf

# Expose Elasticsearch + Glances Web UI
EXPOSE 9200 9300 61208

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]

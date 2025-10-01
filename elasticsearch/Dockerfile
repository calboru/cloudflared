# Base image
FROM debian:bullseye-slim

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
    ES__XPACK_SECURITY_ENABLED=true

# Install dependencies + Glances + Nginx + htpasswd tool
RUN set -eux; \
    for i in $(seq 1 25); do \
        apt-get clean && rm -rf /var/lib/apt/lists/* && \
        apt-get update && \
        apt-get install -y --no-install-recommends \
            curl \
            gnupg \
            gosu \
            ca-certificates \
            openjdk-17-jdk-headless \
            bash \
            procps \
            iputils-ping \
            nano \
            python3 \
            python3-pip \
            nginx \
            apache2-utils && break || echo "APT attempt $i failed, retrying..."; \
        sleep 5; \
    done; \
    pip3 install --no-cache-dir glances[all] passlib

# Create Elasticsearch user/group
RUN groupadd -g 1000 elasticsearch && \
    useradd -r -u 1000 -g elasticsearch elasticsearch

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

# Expose Elasticsearch + Glances Web UI
EXPOSE 9200 9300 61208 61209

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]

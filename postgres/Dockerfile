FROM postgres:latest

ENV POSTGRES_USER=postgres
ENV PGDATA=/mnt/data/postgres
ENV CREATE_DBS="n8n"
ENV DEBIAN_FRONTEND=noninteractive

SHELL ["/bin/bash", "-c"]

# ---------------------------
# retry_apt globally
# ---------------------------
RUN echo '#!/bin/bash' > /usr/local/bin/retry_apt && \
    echo 'while true; do \
        apt-get clean && apt-get update && \
        [ -z "$@" ] || apt-get install -y --no-install-recommends \
        -o Dpkg::Options::="--force-confdef" \
        -o Dpkg::Options::="--force-confold" "$@" && break || { \
            echo "Retrying apt-get $@ ..."; \
            rm -rf /var/lib/apt/lists/* /var/cache/apt/archives/*; \
            sleep 1; \
        }; \
    done' >> /usr/local/bin/retry_apt && \
    chmod +x /usr/local/bin/retry_apt

# ---------------------------
# Create PGDATA directory
# ---------------------------
RUN mkdir -p /mnt/data/postgres

# ---------------------------
# Install dependencies with retry_apt
# ---------------------------
RUN retry_apt iputils-ping \
    && retry_apt nano \
    && retry_apt curl \
    && retry_apt git \
    && retry_apt gosu \
    && retry_apt wget \
    && retry_apt nginx \
    && retry_apt apache2-utils \
    && retry_apt supervisor \
    && retry_apt python3-pip \
    && retry_apt python3-venv \
    && retry_apt python3-dev \
    && rm -rf /var/lib/apt/lists/*

RUN python3 -m pip install --no-cache-dir --break-system-packages -i https://pypi.org/simple glances[web] 

# ---------------------------
# Configs
# ---------------------------
COPY supervisord.conf /etc/supervisord.conf
COPY nginx.conf /etc/nginx/nginx.conf
COPY glances.conf /etc/glances/glances.conf
COPY .htpasswd /etc/nginx/.htpasswd

# ---------------------------
# Entrypoint
# ---------------------------
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

# ---------------------------
# Ports
# ---------------------------
EXPOSE 5432 61208

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]

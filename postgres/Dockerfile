FROM postgres:latest

# ---------------------------
# Environment variables
# ---------------------------
ENV POSTGRES_USER=postgres
ENV PGDATA=/mnt/data/postgres
ENV CREATE_DBS="n8n"

# ---------------------------
# Install additional packages
# ---------------------------
RUN apt-get update && apt-get install -y --no-install-recommends \
    iputils-ping \
    nano \
    curl \
    git \
    gosu \
    wget \
    && rm -rf /var/lib/apt/lists/*

# ---------------------------
# Copy custom entrypoint
# ---------------------------
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

# ---------------------------
# Expose PostgreSQL port
# ---------------------------
EXPOSE 5432

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["postgres"]

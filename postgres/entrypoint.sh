#!/bin/bash
set -euo pipefail

# ---------------------------
# Ensure PGDATA directory exists with correct permissions
# ---------------------------
mkdir -p "$PGDATA"
chown -R "$(id -u "$POSTGRES_USER")":"$(id -g "$POSTGRES_USER")" "$PGDATA"
chmod 700 "$PGDATA"

# ---------------------------
# First-time initialization
# ---------------------------
if [ -z "$(ls -A "$PGDATA")" ]; then
    echo "PGDATA is empty, initializing PostgreSQL cluster..."
    gosu "$POSTGRES_USER" initdb -D "$PGDATA"
fi

# ---------------------------
# Configure temporary pg_hba.conf to allow all connections for DB creation
# ---------------------------
cat >> "$PGDATA/pg_hba.conf" <<EOF
# Temporary rules for CREATE_DBS
host    all             all             0.0.0.0/0               trust
host    all             all             ::/0                    trust
EOF

# ---------------------------
# Start temporary PostgreSQL to create additional databases
# ---------------------------
echo "Starting temporary PostgreSQL to create databases..."
gosu "$POSTGRES_USER" pg_ctl -D "$PGDATA" \
    -o "-c listen_addresses='0.0.0.0'" \
    -w start

# ---------------------------
# Create additional databases with logging
# ---------------------------
if [ -n "${CREATE_DBS:-}" ]; then
    echo "Creating databases: $CREATE_DBS"
    IFS=',' read -ra DBS <<< "$CREATE_DBS"
    for db in "${DBS[@]}"; do
        exists=$(psql --username "$POSTGRES_USER" --dbname "postgres" -tAc "SELECT 1 FROM pg_database WHERE datname='$db'")
        if [ "$exists" = "1" ]; then
            echo "Database '$db' already exists, skipping."
        else
            echo "Database '$db' does not exist. Creating..."
            psql --username "$POSTGRES_USER" --dbname "postgres" -c "CREATE DATABASE \"$db\";"
            echo "Database '$db' created successfully."
        fi
    done
fi

# ---------------------------
# Stop temporary PostgreSQL
# ---------------------------
echo "Stopping temporary PostgreSQL..."
gosu "$POSTGRES_USER" pg_ctl -D "$PGDATA" -m fast -w stop

# ---------------------------
# Start PostgreSQL normally
# ---------------------------
exec docker-entrypoint.sh "$@"

#!/bin/bash
set -euo pipefail

echo "[INIT] Ensuring PGDATA directory exists..."
mkdir -p "$PGDATA"
chown -R "$POSTGRES_USER":"$POSTGRES_USER" "$PGDATA"
chmod 700 "$PGDATA"

# ---------------------------
# First-time initialization
# ---------------------------
if [ -z "$(ls -A "$PGDATA")" ]; then
    echo "[INIT] PGDATA is empty, initializing PostgreSQL cluster..."
    gosu "$POSTGRES_USER" initdb -D "$PGDATA"
else
    echo "[INIT] PGDATA already initialized, skipping initdb."
fi

# ---------------------------
# Configure temporary pg_hba.conf
# ---------------------------
echo "[INIT] Configuring pg_hba.conf for temporary access..."
cat >> "$PGDATA/pg_hba.conf" <<EOF
# Temporary rules for CREATE_DBS
host    all             all             0.0.0.0/0               trust
host    all             all             ::/0                    trust
EOF

# ---------------------------
# Start temporary PostgreSQL
# ---------------------------
echo "[INIT] Starting temporary PostgreSQL for DB creation..."
gosu "$POSTGRES_USER" pg_ctl -D "$PGDATA" \
    -o "-c listen_addresses='0.0.0.0'" \
    -w start

# ---------------------------
# Create additional databases
# ---------------------------
if [ -n "${CREATE_DBS:-}" ]; then
    echo "[INIT] Creating databases: $CREATE_DBS"
    IFS=',' read -ra DBS <<< "$CREATE_DBS"
    for db in "${DBS[@]}"; do
        exists=$(psql --username "$POSTGRES_USER" --dbname "postgres" -tAc "SELECT 1 FROM pg_database WHERE datname='$db'")
        if [ "$exists" = "1" ]; then
            echo "[INIT] Database '$db' already exists, skipping."
        else
            echo "[INIT] Database '$db' does not exist. Creating..."
            psql --username "$POSTGRES_USER" --dbname "postgres" -c "CREATE DATABASE \"$db\";"
            echo "[INIT] Database '$db' created successfully."
        fi
    done
fi

# ---------------------------
# Stop temporary PostgreSQL
# ---------------------------
echo "[INIT] Stopping temporary PostgreSQL..."
gosu "$POSTGRES_USER" pg_ctl -D "$PGDATA" -m fast -w stop

echo "[INIT] Database initialization finished. Supervisor will now start Postgres normally."

# Important: just exec supervisord
exec /usr/bin/supervisord -c /etc/supervisord.conf

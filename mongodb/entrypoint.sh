#!/bin/bash
set -euo pipefail

# Ensure MongoDB root username is supplied
if [ -z "${MONGO_INITDB_ROOT_USERNAME:-}" ]; then
    echo "[Entrypoint][ERROR] MONGO_INITDB_ROOT_USERNAME is not set. Exiting." >&2
    exit 1
fi

echo "[Entrypoint] Using MongoDB root username: $MONGO_INITDB_ROOT_USERNAME" >&2

# Fix permissions for the data directory using the real OS user
echo "[Entrypoint] Fixing permissions for /data/db ..." >&2
chown -R mongodb:mongodb /data/db

# Ensure home directory exists
mkdir -p /home/mongodb
chown -R mongodb:mongodb /home/mongodb

echo "[Entrypoint] Starting supervisord ..." >&2
exec "$@"

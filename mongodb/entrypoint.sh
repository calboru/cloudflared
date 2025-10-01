#!/bin/bash
set -euo pipefail

echo "[Entrypoint] Starting Glances Web UI..."
glances -w -p 61209 &

echo "[Entrypoint] Starting Nginx..."
nginx -g "daemon off;" &

echo "[Entrypoint] Fixing permissions for /data/db ..."
chown -R mongodb:mongodb /data/db

echo "[Entrypoint] Ensuring /home/mongodb exists ..."
mkdir -p /home/mongodb
chown -R mongodb:mongodb /home/mongodb

echo "[Entrypoint] Delegating to official MongoDB entrypoint as mongodb user ..."
exec gosu mongodb python3 /usr/local/bin/docker-entrypoint.py "$@"

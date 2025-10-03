#!/bin/bash
set -euo pipefail

echo "Running as user: $(whoami)"
echo "Elastic user info: $(id)"

# ---------------------------
# Strict vm.max_map_count check
# ---------------------------
MAX_MAP_COUNT=$(cat /proc/sys/vm/max_map_count 2>/dev/null || echo 0)
if [ "$MAX_MAP_COUNT" -lt 262144 ]; then
    echo "ERROR: vm.max_map_count is $MAX_MAP_COUNT."
    echo "Elasticsearch requires vm.max_map_count >= 262144 for production."
    echo "Please run on the host: sudo sysctl -w vm.max_map_count=262144"
fi

# ---------------------------
# Paths
# ---------------------------
ES_HOME="${ES_HOME:-/usr/share/elasticsearch}"
ES_USER="${ES_USER:-elasticsearch}"
ES_GROUP="${ES_GROUP:-elasticsearch}"
ES_CONFIG="$ES_HOME/config/elasticsearch.yml"
ES_DATA="${ES_PATH_DATA:-/mnt/data}"
ES_LOGS="${ES_PATH_LOGS:-/mnt/data/logs}"
CONF_DIR="${SUPERVISOR_CONF_DIR:-/etc/supervisor/conf.d}"

mkdir -p "$ES_DATA" "$ES_LOGS" "$(dirname "$ES_CONFIG")" "$CONF_DIR"
touch "$ES_CONFIG"

# ---------------------------
# Permissions
# ---------------------------
if [ "$(id -u)" -eq 0 ]; then
  chown -R "$ES_USER:$ES_GROUP" "$ES_DATA" "$ES_LOGS" "$ES_HOME/config" || true
  chmod -R 755 "$ES_DATA" "$ES_LOGS" "$ES_HOME/config" || true
  chown "$ES_USER:$ES_GROUP" "$ES_CONFIG" || true
else
  echo "Not running as root; skipping chown/chmod."
fi

# ---------------------------
# Helper: escape value for sed
# ---------------------------
_escape_for_sed_replacement() {
  printf '%s' "$1" | sed -e 's/[\\&|]/\\&/g'
}

# ---------------------------
# Inject ES__* env vars into elasticsearch.yml
# ---------------------------
SKIP_LIST="ES__HOME ES__JAVA_OPTS"

while IFS='=' read -r name value; do
  case "$name" in
    ES__*)
      for reserved in $SKIP_LIST; do
        if [ "$name" = "$reserved" ]; then
          continue 2
        fi
      done

      key="${name#ES__}"
      key="$(printf '%s' "$key" | tr '[:upper:]' '[:lower:]' | tr '_' '.')"
      value="$(printf '%s' "$value" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"

      if grep -qE "^[[:space:]]*${key}[[:space:]]*:" "$ES_CONFIG"; then
        esc_value=$(_escape_for_sed_replacement "$value")
        sed -E -i "s|^([[:space:]]*${key}[[:space:]]*:[[:space:]]*).*$|\1${esc_value}|" "$ES_CONFIG"
        echo "Updated $key -> $value"
      else
        echo "${key}: ${value}" >> "$ES_CONFIG"
        echo "Appended $key -> $value"
      fi
      ;;
  esac
done < <(env)

echo "==== Final $ES_CONFIG ===="
cat "$ES_CONFIG"
echo "================================"

# ---------------------------
# Non-interactive bootstrap password
# ---------------------------
if [ -n "${SET_ES_PASSWORD+x}" ]; then
    echo "⚙️  Setting bootstrap.password for 'elastic' user..."
    if [ "$(id -u)" -eq 0 ]; then
        gosu "$ES_USER" "$ES_HOME/bin/elasticsearch-keystore" add -x -f "bootstrap.password" <<< "$SET_ES_PASSWORD"
    else
        "$ES_HOME/bin/elasticsearch-keystore" add -x -f "bootstrap.password" <<< "$SET_ES_PASSWORD"
    fi
    echo "✅ bootstrap.password set — elastic user will use this password on first start."
fi

# ---------------------------
# Write Supervisor Program for Elasticsearch
# ---------------------------
ES_SUPERVISOR_CONF="$CONF_DIR/elasticsearch.conf"

cat > "$ES_SUPERVISOR_CONF" <<EOF
[program:elasticsearch]
command=$ES_HOME/bin/elasticsearch
user=$ES_USER
autostart=true
autorestart=true
stdout_logfile=/dev/stdout
stdout_logfile_maxbytes=0
stderr_logfile=/dev/stderr
stderr_logfile_maxbytes=0
EOF

echo "✅ Wrote Supervisor config: $ES_SUPERVISOR_CONF"

# ---------------------------
# Run Supervisor (PID 1)
# ---------------------------
echo "🚀 Starting supervisord..."
exec /usr/local/bin/supervisord -n -c /etc/supervisor/supervisord.conf

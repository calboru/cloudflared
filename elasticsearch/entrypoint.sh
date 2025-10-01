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
# Glances run
# ---------------------------
(glances -w -p 61209) &
 
echo "[Entrypoint] Starting Nginx..."
nginx -g "daemon off;" & 

# Resolve defaults
ES_HOME="${ES_HOME:-/usr/share/elasticsearch}"
ES_USER="${ES_USER:-elasticsearch}"
ES_GROUP="${ES_GROUP:-elasticsearch}"
ES_CONFIG="$ES_HOME/config/elasticsearch.yml"
ES_DATA="${ES_PATH_DATA:-/mnt/data}"
ES_LOGS="${ES_PATH_LOGS:-/mnt/data/logs}"

# Ensure directories exist
mkdir -p "$ES_DATA" "$ES_LOGS" "$(dirname "$ES_CONFIG")"
touch "$ES_CONFIG"

# Fix permissions if running as root
if [ "$(id -u)" -eq 0 ]; then
  chown -R "$ES_USER:$ES_GROUP" "$ES_DATA" "$ES_LOGS" "$ES_HOME/config" || true
  chmod -R 755 "$ES_DATA" "$ES_LOGS" "$ES_HOME/config" || true
  chown "$ES_USER:$ES_GROUP" "$ES_CONFIG" || true
else
  echo "Not running as root; skipping chown/chmod."
fi

# Helper: escape value for sed
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
      # skip reserved
      for reserved in $SKIP_LIST; do
        if [ "$name" = "$reserved" ]; then
          continue 2
        fi
      done

      # transform env → elasticsearch.yml key
      key="${name#ES__}"  # strip double underscore
      key="$(printf '%s' "$key" | tr '[:upper:]' '[:lower:'] | tr '_' '.')"
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

# -----------------------------------------------------------
# NEW BLOCK: Non-interactive Password Setup via SET_ES_PASSWORD
# -----------------------------------------------------------
if [ -n "${SET_ES_PASSWORD+x}" ]; then
    echo "SET_ES_PASSWORD variable found. Preparing to set 'elastic' user password..."
    
    if [ "$(id -u)" -eq 0 ]; then
        # If running as root, we must switch user to manage the keystore
        echo "Adding bootstrap.password to keystore as user $ES_USER..."
        # Pass the password via stdin using 'echo | ...' to keep it out of shell history/logs
        gosu "$ES_USER" "$ES_HOME/bin/elasticsearch-keystore" add "bootstrap.password" -x -f <<< "$SET_ES_PASSWORD"
    else
        echo "Adding bootstrap.password to keystore..."
        "$ES_HOME/bin/elasticsearch-keystore" add "bootstrap.password" -x -f <<< "$SET_ES_PASSWORD"
    fi

    # Start Elasticsearch in the background
    echo "Starting Elasticsearch in the background..."
    if [ "$(id -u)" -eq 0 ]; then
        # Use gosu to start ES as the non-root user
        gosu "$ES_USER:$ES_GROUP" "$ES_HOME/bin/elasticsearch" &
    else
        "$ES_HOME/bin/elasticsearch" &
    fi
    
    ES_PID=$!
    
    # Wait for Elasticsearch to be available (checks for HTTP 200)
    echo "Waiting for Elasticsearch to be available on port 9200..."
    for i in {1..30}; do
        if curl -s -o /dev/null -w "%{http_code}" "http://localhost:9200" | grep 200; then
            echo "Elasticsearch is ready."
            break
        fi
        echo -n "."
        sleep 5
    done
    
    if ! curl -s "http://localhost:9200" &>/dev/null; then
        echo "ERROR: Elasticsearch failed to start or is unreachable. Aborting password setup."
        exit 1
    fi
    
    # Set the permanent password for the 'elastic' user using the API
    echo "Setting permanent password for 'elastic' user..."
    curl -X POST "http://localhost:9200/_security/user/elastic/_password" \
      -H "Content-Type: application/json" \
      -u "elastic:$SET_ES_PASSWORD" \
      -d '{ "password" : "'"$SET_ES_PASSWORD"'" }'
    
    echo
    echo "✅ Password for 'elastic' user has been set successfully."
    echo "Waiting for the background Elasticsearch process to remain primary..."
    
    # Wait for the background Elasticsearch process to exit gracefully or keep running
    wait $ES_PID
    
else
# ---------------------------
# Original: Drop to elasticsearch user and exec the main command
# ---------------------------
    echo "SET_ES_PASSWORD not set. Executing Elasticsearch normally."
    if [ "$(id -u)" -eq 0 ]; then
      echo "Switching to $ES_USER..."
      # Use exec gosu to replace the shell process with the ES process
      exec gosu "$ES_USER:$ES_GROUP" "$ES_HOME/bin/elasticsearch"
    else
      exec "$ES_HOME/bin/elasticsearch"
    fi
fi

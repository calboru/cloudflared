#!/usr/bin/env bash
set -euo pipefail

# ============================================
# Configuration
# ============================================
CONF_DIR="${SUPERVISOR_CONF_DIR:-/etc/supervisor/conf.d}"
TMP_DIR="${TMPDIR:-/tmp}"

mkdir -p "$CONF_DIR"

# ============================================
# Supervisor program config templates
# ============================================
generate_proxy_conf() {
  cat <<'TEMPLATE'
[program:cloudflared_{{NAME}}]
command=/bin/bash -lc "{{CMD}}"
autostart=true
autorestart=true
startsecs=5
stopwaitsecs=20
stopsignal=TERM
stdout_logfile=/dev/fd/1
stdout_logfile_maxbytes=0
stderr_logfile=/dev/fd/2
stderr_logfile_maxbytes=0
environment={{NAME}}="%(ENV_{{NAME}})s"
TEMPLATE
}

generate_tunnel_conf() {
  cat <<'TEMPLATE'
[program:cloudflared_tunnel]
command=/bin/bash -lc "{{CMD}}"
autostart=true
autorestart=true
startsecs=5
stopwaitsecs=20
stopsignal=TERM
stdout_logfile=/dev/fd/1
stdout_logfile_maxbytes=0
stderr_logfile=/dev/fd/2
stderr_logfile_maxbytes=0
environment=TUNNEL_TOKEN="%(ENV_TUNNEL_TOKEN)s"
TEMPLATE
}

# ============================================
# Track active configs for cleanup
# ============================================
declare -A active_configs=()

# ============================================
# Process PROXY_* env vars
# ============================================
while IFS= read -r line; do
  [[ -z "$line" ]] && continue
  name="${line%%=*}"
  value="${line#*=}"

  case "$name" in
    PROXY_*)
      if [[ -z "${value// /}" ]]; then
        echo "Skipping $name: empty value"
        continue
      fi

      conf_file="${CONF_DIR}/cloudflared_${name}.conf"
      tmp_conf="${TMP_DIR}/cloudflared_${name}.conf.$$"

      cmd="\$${name}"
      escaped_cmd="$(printf '%s' "$cmd" | sed -e 's/\\/\\\\/g' -e 's/"/\\"/g')"

      generate_proxy_conf \
        | sed "s/{{NAME}}/$name/g; s/{{CMD}}/$escaped_cmd/g" \
        > "$tmp_conf"

      mv -f "$tmp_conf" "$conf_file"
      chmod 644 "$conf_file"
      active_configs["$conf_file"]=1
      echo "Upserted $conf_file (secrets hidden)"
      ;;
  esac
done < <(env)

# ============================================
# Process TUNNEL_TOKEN
# ============================================
if [[ -n "${TUNNEL_TOKEN:-}" ]]; then
  conf_file="${CONF_DIR}/cloudflared_tunnel.conf"
  tmp_conf="${TMP_DIR}/cloudflared_tunnel.conf.$$"

  cmd="/mnt/data/cloudflared tunnel run --token \$TUNNEL_TOKEN"
  escaped_cmd="$(printf '%s' "$cmd" | sed -e 's/\\/\\\\/g' -e 's/"/\\"/g')"

  generate_tunnel_conf \
    | sed "s|{{CMD}}|$escaped_cmd|g" \
    > "$tmp_conf"

  mv -f "$tmp_conf" "$conf_file"
  chmod 644 "$conf_file"
  active_configs["$conf_file"]=1
  echo "Upserted $conf_file (TUNNEL_TOKEN hidden)"
else
  conf_file="${CONF_DIR}/cloudflared_tunnel.conf"
  if [[ -e "$conf_file" ]]; then
    echo "Removing stale tunnel config $conf_file"
    rm -f "$conf_file"
  fi
fi

# ============================================
# Cleanup stale PROXY_* configs
# ============================================
for f in "$CONF_DIR"/cloudflared_PROXY_*.conf; do
  [[ -e "$f" ]] || continue
  if [[ -z "${active_configs[$f]+x}" ]]; then
    echo "Removing stale config $f"
    rm -f "$f"
  fi
done


echo "Cloudflared setup complete."
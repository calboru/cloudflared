#!/bin/sh
# add_proxy_hosts.sh
# PROXY_HOST_n=sshhost,user,destport,targethost

SSH_CONFIG="${SSH_CONFIG:-$HOME/.ssh/config}"
CLOUDFLARED_BIN="${CLOUDFLARED_BIN:-/usr/local/bin/cloudflared/cloudflared}"
BACKUP="${SSH_CONFIG}.bak.$(date +%Y%m%d%H%M%S)"
TMP="$(mktemp)"

start_marker="# BEGIN MANAGED PROXY HOSTS (cloudflared) - DO NOT EDIT"
end_marker="# END MANAGED PROXY HOSTS (cloudflared)"

mkdir -p "$(dirname "$SSH_CONFIG")"
touch "$SSH_CONFIG"
chmod 600 "$SSH_CONFIG"

{
  echo "$start_marker"
  env | awk -F= '/^PROXY_HOST_[0-9]+=/ { print $0 }' | \
  awk -F'=' '{ print $1, $2 }' | \
  while IFS= read -r line; do
    value=$(printf "%s" "$line" | awk '{ $1=""; sub(/^ /,""); print }')

    SSH_HOST=$(printf "%s" "$value" | awk -F, '{print $1}')
    SSH_USER=$(printf "%s" "$value" | awk -F, '{print $2}')
    DEST_PORT=$(printf "%s" "$value" | awk -F, '{print $3}')
    TARGET_HOST=$(printf "%s" "$value" | awk -F, '{print $4}')

    [ -z "$SSH_HOST" ] && continue
    [ -z "$SSH_USER" ] && SSH_USER="jenkins"
    [ -z "$DEST_PORT" ] && DEST_PORT="22"
    [ -z "$TARGET_HOST" ] && TARGET_HOST="localhost"

    cat <<-EOF
Host ${SSH_HOST}
  User ${SSH_USER}
  ProxyCommand cloudflared access tcp --hostname %h --destination ${TARGET_HOST}:${DEST_PORT}
EOF

  done
  echo "$end_marker"
} > "$TMP"

if ! grep -q "^$start_marker$" "$TMP"; then
  echo "No PROXY_HOST_* environment variables found. Nothing to do."
  rm -f "$TMP"
  exit 0
fi

cp -p "$SSH_CONFIG" "$BACKUP" || { echo "Failed to back up $SSH_CONFIG"; rm -f "$TMP"; exit 1; }

awk -v start="$start_marker" -v end="$end_marker" '
  BEGIN { in_block=0 }
  {
    if ($0 == start) { in_block=1; next }
    if ($0 == end) { in_block=0; next }
    if (!in_block) print
  }
' "$SSH_CONFIG" > "${SSH_CONFIG}.tmp" && cat "$TMP" >> "${SSH_CONFIG}.tmp" && mv "${SSH_CONFIG}.tmp" "$SSH_CONFIG"

chmod 600 "$SSH_CONFIG"
rm -f "$TMP"

echo "Updated $SSH_CONFIG — backup saved as $BACKUP"

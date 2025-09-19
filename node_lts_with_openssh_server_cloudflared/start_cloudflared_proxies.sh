#!/bin/sh

TMP_CONF=/etc/supervisord_dynamic.conf

# Base supervisord config
cat <<'EOF' > $TMP_CONF
[supervisord]
nodaemon=true
logfile=/var/log/supervisord.log
loglevel=info

[program:sshd]
command=/usr/sbin/sshd -D -e
autostart=true
autorestart=true
stderr_logfile=/var/log/sshd_err.log
EOF

# Loop over PROXY_n environment variables
i=1
while eval "val=\$PROXY_$i"; [ -n "$val" ]; do
    # Parse key=value pairs
    HOST=$(echo $val | sed -n 's/.*host=\([^&]*\).*/\1/p')
    URL=$(echo $val | sed -n 's/.*url=\([^&]*\).*/\1/p')
    LISTENER=$(echo $val | sed -n 's/.*listener=\([^&]*\).*/\1/p')
    SERVICE_TOKEN_ID=$(echo $val | sed -n 's/.*service-token-id=\([^&]*\).*/\1/p')
    SERVICE_TOKEN_SECRET=$(echo $val | sed -n 's/.*service-token-secret=\([^&]*\).*/\1/p')

    # Add a program section to supervisord config using the host name
    cat <<EOF >> $TMP_CONF

[program:$HOST]
command=/usr/local/bin/cloudflared access tcp --hostname $HOST --url $URL --listener $LISTENER --service-token-id $SERVICE_TOKEN_ID --service-token-secret $SERVICE_TOKEN_SECRET
autostart=true
autorestart=true
stderr_logfile=/var/log/cloudflared_${HOST}.err.log
EOF

    i=$((i+1))
done

# Run supervisord with dynamic config
exec /usr/bin/supervisord -c $TMP_CONF

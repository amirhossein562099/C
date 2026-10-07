#!/bin/sh

set -eu

NGINX_PORT="${PORT:-3000}"
PANEL_PORT="${PANEL_PORT:-8090}"
DATA_DIR="${DATA_DIR:-/data}"
NGINX_CONF="${NGINX_CONF:-/tmp/nginx.conf}"

for used in "$PANEL_PORT" "${XRAY_API_PORT:-10085}"; do
    if [ "$NGINX_PORT" = "$used" ]; then
        echo "The public port ($NGINX_PORT) collides with an internal one."
        echo "Change PANEL_PORT or XRAY_API_PORT."
        exit 1
    fi
done

if [ ! -w "$DATA_DIR" ]; then
    echo "$DATA_DIR is not writable."
    exit 1
fi

mkdir -p /run/nginx
mkdir -p /tmp/nginx-proxy
mkdir -p /tmp/nginx-client

echo "public=$NGINX_PORT panel=$PANEL_PORT data=$DATA_DIR nginx_conf=$NGINX_CONF"

sed -e "s/\${NGINX_PORT}/$NGINX_PORT/g" \
    -e "s/\${PANEL_PORT}/$PANEL_PORT/g" \
    /app/nginx.conf.tmpl > "$NGINX_CONF"

nginx -c "$NGINX_CONF" -t

nginx -c "$NGINX_CONF"

export NGINX_PORT
export NGINX_CONF

exec node /app/server/index.js

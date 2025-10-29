#!/bin/sh
set -e

# Determine primary vs secondary based on ACTIVE_POOL
if [ "${ACTIVE_POOL:-blue}" = "green" ]; then
  export PRIMARY_HOST="${GREEN_HOST:-host.docker.internal}"
  export PRIMARY_PORT="${GREEN_PORT:-8082}"
  export SECONDARY_HOST="${BLUE_HOST:-host.docker.internal}"
  export SECONDARY_PORT="${BLUE_PORT:-8081}"
else
  export PRIMARY_HOST="${BLUE_HOST:-host.docker.internal}"
  export PRIMARY_PORT="${BLUE_PORT:-8081}"
  export SECONDARY_HOST="${GREEN_HOST:-host.docker.internal}"
  export SECONDARY_PORT="${GREEN_PORT:-8082}"
fi

# Render template
envsubst '${PRIMARY_HOST} ${PRIMARY_PORT} ${SECONDARY_HOST} ${SECONDARY_PORT} ${PROXY_CONNECT_TIMEOUT} ${PROXY_READ_TIMEOUT} ${PROXY_SEND_TIMEOUT}' \
  < /etc/nginx/nginx.conf.template > /etc/nginx/nginx.conf

# Start nginx in foreground
nginx -g "daemon off;"

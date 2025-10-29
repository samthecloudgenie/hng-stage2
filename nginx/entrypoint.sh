#!/bin/sh
set -e

# Determine primary vs secondary based on ACTIVE_POOL
if [ "${ACTIVE_POOL:-blue}" = "green" ]; then
  export PRIMARY_HOST="${GREEN_HOST:-app_green}"
  export PRIMARY_PORT="${GREEN_PORT:-3000}"
  export SECONDARY_HOST="${BLUE_HOST:-app_blue}"
  export SECONDARY_PORT="${BLUE_PORT:-3000}"
else
  export PRIMARY_HOST="${BLUE_HOST:-app_blue}"
  export PRIMARY_PORT="${BLUE_PORT:-3000}"
  export SECONDARY_HOST="${GREEN_HOST:-app_green}"
  export SECONDARY_PORT="${GREEN_PORT:-3000}"
fi

# Ensure default timeout values if not set
export PROXY_CONNECT_TIMEOUT="${PROXY_CONNECT_TIMEOUT:-1s}"
export PROXY_SEND_TIMEOUT="${PROXY_SEND_TIMEOUT:-5s}"
export PROXY_READ_TIMEOUT="${PROXY_READ_TIMEOUT:-5s}"

# Render Nginx configuration from template
envsubst '${PRIMARY_HOST} ${PRIMARY_PORT} ${SECONDARY_HOST} ${SECONDARY_PORT} \
${PROXY_CONNECT_TIMEOUT} ${PROXY_READ_TIMEOUT} ${PROXY_SEND_TIMEOUT}' \
  < /etc/nginx/nginx.conf.template > /etc/nginx/nginx.conf

# Start nginx
nginx -g "daemon off;"

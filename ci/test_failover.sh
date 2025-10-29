#!/usr/bin/env bash
set -euo pipefail

NGINX_URL="http://localhost:8080/version"
BLUE_CHAOS_START="http://localhost:8081/chaos/start?mode=error"
BLUE_CHAOS_STOP="http://localhost:8081/chaos/stop"
# Timeouts
TOTAL_LOOP_SECS=10
SLEEP_BETWEEN=0.2

echo "1) Baseline check - expect blue responses"
resp=$(curl -s -D - "$NGINX_URL" -o /dev/null --max-time 5 -w "%{http_code} %{redirect_url}")
code=$(curl -s -I "$NGINX_URL" --max-time 5 | head -n 1 | awk '{print $2}')
xpool=$(curl -s -I "$NGINX_URL" | grep -i 'X-App-Pool' || true)
xrel=$(curl -s -I "$NGINX_URL" | grep -i 'X-Release-Id' || true)
if [ "$code" != "200" ]; then
  echo "Baseline failed: expected 200, got $code"
  exit 1
fi
echo "Baseline GET returned 200 and headers:"
curl -s -I "$NGINX_URL" | grep -i 'X-App-' || true

# loop a few times to ensure stable blue
for i in $(seq 1 5); do
  code=$(curl -s -o /dev/null -w "%{http_code}" --max-time 5 "$NGINX_URL")
  if [ "$code" != "200" ]; then
    echo "Unexpected non-200 during baseline loop: $code"
    exit 1
  fi
done
echo "Baseline stable: OK"

echo "2) Start chaos on Blue (simulate downtime)"
curl -s -X POST "$BLUE_CHAOS_START" || true

echo "3) Immediate check loop for ${TOTAL_LOOP_SECS}s: expect responses from green, no non-200s"
start=$(date +%s)
end=$((start + TOTAL_LOOP_SECS))
total=0
non200=0
green_count=0

while [ $(date +%s) -lt $end ]; do
  total=$((total+1))
  out_headers=$(curl -s -I --max-time 6 "$NGINX_URL" || true)
  code=$(echo "$out_headers" | head -n1 | awk '{print $2}' || echo "000")
  xpool=$(echo "$out_headers" | grep -i 'X-App-Pool:' | awk -F': ' '{print $2}' | tr -d '\r' || echo "")
  xrel=$(echo "$out_headers" | grep -i 'X-Release-Id:' | awk -F': ' '{print $2}' | tr -d '\r' || echo "")
  if [ "$code" != "200" ]; then
    echo "Non-200 detected during failover: $code"
    non200=$((non200+1))
  fi
  if [ "$xpool" = "green" ]; then
    green_count=$((green_count+1))
  fi
  sleep $SLEEP_BETWEEN
done

echo "Total requests: $total, non200: $non200, green: $green_count"
# validation
if [ "$non200" -ne 0 ]; then
  echo "Fail: there were $non200 non-200 responses during the observation window."
  exit 1
fi

# Percentage from green
percent_green=$((100 * green_count / total))
echo "Green percent: ${percent_green}%"
if [ "$percent_green" -lt 95 ]; then
  echo "Fail: Less than 95% responses served by green."
  exit 1
fi

echo "4) Stop chaos (cleanup)"
curl -s -X POST "$BLUE_CHAOS_STOP" || true

echo "All checks passed"

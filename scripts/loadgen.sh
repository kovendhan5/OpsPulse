#!/usr/bin/env bash
# Simple traffic generator so dashboards and canary analysis have data.
# Usage: ./scripts/loadgen.sh http://<node-public-ip>
# BUG FIX: Added -w to curl to log status codes; added GET /health for
# readiness traffic; added trap for clean exit.

set -euo pipefail

URL="${1:?usage: loadgen.sh <base-url>}"
echo "Sending traffic to $URL (Ctrl+C to stop)"

trap 'echo ""; echo "Load generator stopped."; exit 0' INT TERM

while true; do
  curl -s -o /dev/null -w "%{http_code} POST /orders\n" \
       -X POST "$URL/orders" -H 'Content-Type: application/json' \
       -d '{"item":"book","quantity":1}'
  curl -s -o /dev/null -w "%{http_code} GET  /orders\n" "$URL/orders"
  curl -s -o /dev/null -w "%{http_code} GET  /health\n" "$URL/health"
  sleep 0.2
done



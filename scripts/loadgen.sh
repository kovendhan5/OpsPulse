#!/usr/bin/env bash
# Simple traffic generator so dashboards and canary analysis have data.
# Usage: ./scripts/loadgen.sh http://<node-public-ip>
URL="${1:?usage: loadgen.sh <base-url>}"
echo "Sending traffic to $URL (Ctrl+C to stop)"
while true; do
  curl -s -o /dev/null -X POST "$URL/orders" -H 'Content-Type: application/json' \
       -d '{"item":"book","quantity":1}'
  curl -s -o /dev/null "$URL/orders"
  sleep 0.2
done

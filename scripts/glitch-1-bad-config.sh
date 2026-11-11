#!/usr/bin/env bash
# 💥 Glitch 1: "A teammate deploys v2 with a typo in the config."
# The env var APP_PORT is renamed to APP_PROT by mistake → the app crashes on startup.
set -euo pipefail
echo "👷 Teammate: 'Deploying v2, just a small config change…'"
kubectl set env deployment/coffee-shop -n coffee APP_VERSION=v2 APP_PROT=8080 APP_PORT- >/dev/null
echo "💥 v2 deployed. Refresh http://localhost:8888 in ~20 seconds."

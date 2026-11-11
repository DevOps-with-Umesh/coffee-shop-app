#!/usr/bin/env bash
# 💥 Glitch 3 (bonus): "A teammate turns on a new 300 MB menu cache."
# The container memory limit is 128Mi → the pod is OOMKilled → site down.
set -euo pipefail
echo "👷 Teammate: 'Turning on the new menu cache feature for v3…'"
kubectl set env deployment/coffee-shop -n coffee APP_VERSION=v3 MENU_CACHE_MB=300 >/dev/null
echo "💥 Deployed. Refresh http://localhost:8888 in ~20 seconds."

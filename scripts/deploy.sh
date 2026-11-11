#!/usr/bin/env bash
# Deploys the healthy Coffee Shop app (v1) and waits until it is ready.
set -euo pipefail
cd "$(dirname "$0")/.."
echo "🚀 Deploying DevOps Coffee v1 ..."
kubectl apply -f app.yaml
kubectl rollout status deployment/coffee-shop -n coffee --timeout=180s
echo
echo "✅ App is running. Now open it with:  ./scripts/open-app.sh"

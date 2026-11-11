#!/usr/bin/env bash
# Deletes the app completely and deploys a fresh, healthy v1.
set -euo pipefail
cd "$(dirname "$0")/.."
echo "🧹 Deleting namespace coffee ..."
kubectl delete namespace coffee --ignore-not-found --wait=true
./scripts/deploy.sh

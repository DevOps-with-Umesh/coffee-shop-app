#!/usr/bin/env bash
# Makes the app available at http://localhost:8888 and keeps reconnecting
# automatically when pods are replaced. Leave this running in its own Terminal tab.
# Stop it with Ctrl + C.
echo "🌐 Coffee Shop → http://localhost:8888   (Ctrl + C to stop)"
while true; do
  kubectl port-forward svc/coffee-shop 8888:80 -n coffee >/dev/null 2>&1
  sleep 2
done

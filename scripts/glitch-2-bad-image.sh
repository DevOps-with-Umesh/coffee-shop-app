#!/usr/bin/env bash
# 💥 Glitch 2: "A teammate upgrades the base image and makes a typo in the tag."
# python:3.12-alpne does not exist → ImagePullBackOff → site down.
set -euo pipefail
echo "👷 Teammate: 'Upgrading the base image, quick change…'"
kubectl set image deployment/coffee-shop -n coffee web=python:3.12-alpne >/dev/null
echo "💥 Deployed. Refresh http://localhost:8888 in ~20 seconds."

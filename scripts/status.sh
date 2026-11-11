#!/usr/bin/env bash
# Shows the app's pods and service.
kubectl get pods,svc -n coffee -o wide

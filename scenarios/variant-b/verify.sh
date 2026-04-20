#!/bin/bash
# Verify: at least one ready pod confirms the probe configuration is corrected.
READY=$(kubectl get deployment mobility-api -n mobility \
  -o jsonpath='{.status.readyReplicas}' 2>/dev/null || echo "0")

if [ "${READY:-0}" -ge 1 ] 2>/dev/null; then
  echo "Service is healthy — ${READY} pod(s) ready."
  exit 0
else
  echo "No ready pods found. Pods may still be restarting."
  exit 1
fi

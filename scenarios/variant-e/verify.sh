#!/bin/bash
# Verify: Deployment must have at least one ready replica (replicaCount > 0 and pods healthy).
READY=$(kubectl get deployment mobility-api -n mobility \
  -o jsonpath='{.status.readyReplicas}' 2>/dev/null || echo "0")

if [ "${READY:-0}" -ge 1 ] 2>/dev/null; then
  echo "Service is healthy — ${READY} pod(s) ready."
  exit 0
else
  echo "No ready pods. The deployment may still have replicaCount: 0."
  exit 1
fi

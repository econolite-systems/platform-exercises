#!/bin/bash
# Verify: pods must be running (no ImagePullBackOff) with at least one ready.
READY=$(kubectl get deployment mobility-api -n mobility \
  -o jsonpath='{.status.readyReplicas}' 2>/dev/null || echo "0")

if [ "${READY:-0}" -ge 1 ] 2>/dev/null; then
  echo "Service is healthy — ${READY} pod(s) ready."
  exit 0
else
  echo "No ready pods. Image may still be pulling or tag is incorrect."
  exit 1
fi

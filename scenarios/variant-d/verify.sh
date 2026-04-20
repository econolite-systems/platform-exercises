#!/bin/bash
# Verify: Service must have at least one endpoint IP (selector now matches pods).
ENDPOINTS=$(kubectl get endpoints mobility-api -n mobility \
  -o jsonpath='{.subsets[*].addresses[*].ip}' 2>/dev/null)

if [ -n "$ENDPOINTS" ]; then
  echo "Service is healthy — endpoints resolved: ${ENDPOINTS}"
  exit 0
else
  echo "Service still has no endpoints. The selector may still be mismatched."
  exit 1
fi

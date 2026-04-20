#!/bin/bash
echo "Preparing your environment. This takes about 90 seconds..."
while [ ! -f /tmp/background-done ]; do
  sleep 2
done
echo ""
echo "Environment ready. Read the instructions on the left panel and begin."
echo ""

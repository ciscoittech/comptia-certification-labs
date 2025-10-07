#!/bin/bash

# NAT/PAT Configuration Lab - Cleanup Script

set -e

echo "========================================"
echo "NAT/PAT Configuration Lab Cleanup"
echo "========================================"
echo ""

cd "$(dirname "$0")/.."

# Check if lab is deployed
if ! docker ps | grep -q "clab-nat-pat-configuration"; then
    echo "⚠️  Lab is not currently deployed."
    exit 0
fi

echo "Destroying lab topology..."
containerlab destroy -t topology.clab.yml --cleanup

echo ""
echo "✅ Lab cleanup complete!"
echo ""
echo "To redeploy the lab, run: ./scripts/deploy.sh"

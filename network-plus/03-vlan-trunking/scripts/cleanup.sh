#!/bin/bash

# VLAN Configuration & Trunking Lab - Cleanup Script
# Destroys lab and cleans up resources

set -e

echo "========================================"
echo "VLAN Lab Cleanup"
echo "========================================"
echo ""

# Check if lab is deployed
if ! docker ps | grep -q "clab-vlan-trunking-basics"; then
    echo "ℹ️  Lab is not currently deployed. Nothing to clean up."
    exit 0
fi

echo "Destroying lab topology..."
cd "$(dirname "$0")/.."
containerlab destroy -t topology.clab.yml --cleanup

echo ""
echo "✅ Lab cleanup complete!"
echo ""
echo "To redeploy the lab, run: ./scripts/deploy.sh"

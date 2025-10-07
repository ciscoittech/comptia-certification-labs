#!/bin/bash

# Static Routing Basics Lab - Cleanup Script

set -e

echo "========================================"
echo "Static Routing Lab Cleanup"
echo "========================================"
echo ""

if ! docker ps | grep -q "clab-static-routing-basics"; then
    echo "ℹ️  Lab is not currently deployed."
    exit 0
fi

echo "Destroying lab topology..."
cd "$(dirname "$0")/.."
containerlab destroy -t topology.clab.yml --cleanup

echo ""
echo "✅ Lab cleanup complete!"
echo ""
echo "To redeploy: ./scripts/deploy.sh"

#!/bin/bash

# Network Interface Configuration Lab - Cleanup Script

set -e

echo "========================================"
echo "Network Interface Configuration Lab Cleanup"
echo "========================================"
echo ""

cd "$(dirname "$0")/.."

if ! docker ps | grep -q "clab-network-interface-config"; then
    echo "⚠️  Lab is not currently deployed."
    exit 0
fi

echo "Destroying lab topology..."
containerlab destroy -t topology.clab.yml --cleanup

echo ""
echo "✅ Lab cleanup complete!"

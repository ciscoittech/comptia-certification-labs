#!/bin/bash

set -e

echo "========================================"
echo "DMZ Network Design Lab - Cleanup"
echo "========================================"
echo ""

cd "$(dirname "$0")/.."

if ! docker ps | grep -q "clab-dmz-network-design"; then
    echo "⚠️  Lab is not currently deployed."
    exit 0
fi

echo "Destroying lab topology..."
containerlab destroy -t topology.clab.yml --cleanup

echo ""
echo "✅ Lab cleanup complete!"

#!/bin/bash

# Network Interface Configuration Lab - Deployment Script

set -e

echo "========================================"
echo "Network Interface Configuration Lab"
echo "========================================"
echo ""

if ! command -v containerlab &> /dev/null; then
    echo "❌ Error: containerlab is not installed"
    exit 1
fi

if docker ps | grep -q "clab-network-interface-config"; then
    echo "⚠️  Lab already deployed. Run './scripts/cleanup.sh' first."
    exit 1
fi

echo "Deploying topology..."
cd "$(dirname "$0")/.."
containerlab deploy -t topology.clab.yml

echo ""
echo "Waiting for initialization (10 seconds)..."
sleep 10

echo ""
echo "✅ Lab deployment complete!"
echo ""
echo "Quick commands:"
echo "  docker exec -it clab-network-interface-config-host1 sh"
echo "  docker exec -it clab-network-interface-config-host2 sh"
echo "  docker exec clab-network-interface-config-host1 ping 192.168.1.20"
echo ""
echo "Run validation: cd scripts && ./validate.sh"

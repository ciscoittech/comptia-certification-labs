#!/bin/bash

# NAT/PAT Configuration Lab - Deployment Script

set -e

echo "========================================"
echo "NAT/PAT Configuration Lab Deployment"
echo "========================================"
echo ""

# Check if containerlab is installed
if ! command -v containerlab &> /dev/null; then
    echo "❌ Error: containerlab is not installed"
    echo "Please install: https://containerlab.dev/install/"
    exit 1
fi

# Check if already deployed
if docker ps | grep -q "clab-nat-pat-configuration"; then
    echo "⚠️  Lab already deployed. Run './scripts/cleanup.sh' first."
    exit 1
fi

echo "1. Deploying topology..."
cd "$(dirname "$0")/.."
containerlab deploy -t topology.clab.yml

echo ""
echo "2. Waiting for containers to initialize (15 seconds)..."
sleep 15

echo ""
echo "✅ Lab deployment complete!"
echo ""
echo "========================================"
echo "Quick Access Commands"
echo "========================================"
echo ""
echo "Access router:"
echo "  docker exec -it clab-nat-pat-configuration-router sh"
echo ""
echo "Access internal client:"
echo "  docker exec -it clab-nat-pat-configuration-internal-client sh"
echo ""
echo "Access external server:"
echo "  docker exec -it clab-nat-pat-configuration-external-server sh"
echo ""
echo "Test NAT connectivity:"
echo "  docker exec clab-nat-pat-configuration-internal-client ping 203.0.113.10"
echo ""
echo "Test HTTP through NAT:"
echo "  docker exec clab-nat-pat-configuration-internal-client curl http://203.0.113.10"
echo ""
echo "View NAT table:"
echo "  docker exec clab-nat-pat-configuration-router iptables -t nat -L -v -n"
echo ""
echo "Run validation:"
echo "  cd scripts && ./validate.sh"
echo ""
echo "Ready to learn NAT/PAT! 🚀"

#!/bin/bash

# Static Routing Basics Lab - Deployment Script

set -e

echo "========================================"
echo "Static Routing Lab Deployment"
echo "========================================"
echo ""

# Check if containerlab is installed
if ! command -v containerlab &> /dev/null; then
    echo "❌ Error: containerlab is not installed"
    echo "Please install: https://containerlab.dev/install/"
    exit 1
fi

# Check if already deployed
if docker ps | grep -q "clab-static-routing-basics"; then
    echo "⚠️  Lab already deployed. Run './scripts/cleanup.sh' first."
    exit 1
fi

echo "1. Deploying topology..."
cd "$(dirname "$0")/.."
containerlab deploy -t topology.clab.yml

echo ""
echo "2. Waiting for containers to initialize (10 seconds)..."
sleep 10

echo ""
echo "✅ Lab deployment complete!"
echo ""
echo "========================================"
echo "Quick Access Commands"
echo "========================================"
echo ""
echo "Access routers:"
echo "  docker exec -it clab-static-routing-basics-r1 sh"
echo "  docker exec -it clab-static-routing-basics-r2 sh"
echo "  docker exec -it clab-static-routing-basics-r3 sh"
echo ""
echo "Access PCs:"
echo "  docker exec -it clab-static-routing-basics-pc1 sh"
echo "  docker exec -it clab-static-routing-basics-pc2 sh"
echo ""
echo "View routing tables:"
echo "  docker exec clab-static-routing-basics-r1 ip route show"
echo ""
echo "Test connectivity:"
echo "  docker exec clab-static-routing-basics-pc1 ping 10.3.3.10"
echo ""
echo "Run validation:"
echo "  cd scripts && ./validate.sh"
echo ""
echo "Ready to learn! 🚀"

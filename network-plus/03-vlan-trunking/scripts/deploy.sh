#!/bin/bash

# VLAN Configuration & Trunking Lab - Deployment Script
# Automated deployment and configuration

set -e

echo "========================================"
echo "VLAN Lab Deployment"
echo "========================================"
echo ""

# Check if containerlab is installed
if ! command -v containerlab &> /dev/null; then
    echo "❌ Error: containerlab is not installed"
    echo "Please install containerlab first: https://containerlab.dev/install/"
    exit 1
fi

# Check if already deployed
if docker ps | grep -q "clab-vlan-trunking-basics"; then
    echo "⚠️  Lab is already deployed. Run './cleanup.sh' first to redeploy."
    exit 1
fi

echo "1. Deploying topology..."
cd "$(dirname "$0")/.."
containerlab deploy -t topology.clab.yml

echo ""
echo "2. Waiting for containers to initialize (15 seconds)..."
sleep 15

echo ""
echo "3. Verifying VLAN bridge configuration..."
docker exec clab-vlan-trunking-basics-sw1 bridge vlan show
docker exec clab-vlan-trunking-basics-sw2 bridge vlan show

echo ""
echo "✅ Lab deployment complete!"
echo ""
echo "========================================"
echo "Quick Access Commands"
echo "========================================"
echo ""
echo "Access switches:"
echo "  docker exec -it clab-vlan-trunking-basics-sw1 sh"
echo "  docker exec -it clab-vlan-trunking-basics-sw2 sh"
echo ""
echo "Access clients:"
echo "  docker exec -it clab-vlan-trunking-basics-client1 sh  # VLAN 10"
echo "  docker exec -it clab-vlan-trunking-basics-client2 sh  # VLAN 20"
echo "  docker exec -it clab-vlan-trunking-basics-client3 sh  # VLAN 10"
echo "  docker exec -it clab-vlan-trunking-basics-client4 sh  # VLAN 20"
echo ""
echo "Run validation tests:"
echo "  cd scripts && ./validate.sh"
echo ""
echo "========================================"
echo "Lab Information"
echo "========================================"
echo "VLAN 10 (Engineering): 10.10.10.0/24"
echo "VLAN 20 (Sales):       10.10.20.0/24"
echo "VLAN 30 (Management):  10.10.30.0/24"
echo ""
echo "Ready to learn! 🚀"

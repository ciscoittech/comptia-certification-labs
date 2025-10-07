#!/bin/bash

set -e

echo "========================================"
echo "SSH Key Authentication Lab"
echo "========================================"
echo ""

if ! command -v containerlab &> /dev/null; then
    echo "❌ Error: containerlab is not installed"
    exit 1
fi

if docker ps | grep -q "clab-ssh-key-authentication"; then
    echo "⚠️  Lab already deployed. Run './scripts/cleanup.sh' first."
    exit 1
fi

echo "Deploying topology..."
cd "$(dirname "$0")/.."
containerlab deploy -t topology.clab.yml

echo ""
echo "Waiting for initialization (15 seconds)..."
sleep 15

echo ""
echo "✅ Lab deployment complete!"
echo ""
echo "Run validation: cd scripts && ./validate.sh"

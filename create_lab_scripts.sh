#!/bin/bash

# Helper function to create deploy.sh
create_deploy_script() {
    local lab_path="$1"
    local lab_display_name="$2"
    local lab_clab_name="$3"
    
    cat > "$lab_path/scripts/deploy.sh" << 'EOF'
#!/bin/bash

set -e

echo "========================================"
echo "LAB_DISPLAY_NAME"
echo "========================================"
echo ""

if ! command -v containerlab &> /dev/null; then
    echo "❌ Error: containerlab is not installed"
    exit 1
fi

if docker ps | grep -q "clab-LAB_CLAB_NAME"; then
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
EOF

    sed -i '' "s/LAB_DISPLAY_NAME/$lab_display_name/g" "$lab_path/scripts/deploy.sh"
    sed -i '' "s/LAB_CLAB_NAME/$lab_clab_name/g" "$lab_path/scripts/deploy.sh"
    chmod +x "$lab_path/scripts/deploy.sh"
}

# Helper function to create cleanup.sh
create_cleanup_script() {
    local lab_path="$1"
    local lab_display_name="$2"
    local lab_clab_name="$3"
    
    cat > "$lab_path/scripts/cleanup.sh" << 'EOF'
#!/bin/bash

set -e

echo "========================================"
echo "LAB_DISPLAY_NAME - Cleanup"
echo "========================================"
echo ""

cd "$(dirname "$0")/.."

if ! docker ps | grep -q "clab-LAB_CLAB_NAME"; then
    echo "⚠️  Lab is not currently deployed."
    exit 0
fi

echo "Destroying lab topology..."
containerlab destroy -t topology.clab.yml --cleanup

echo ""
echo "✅ Lab cleanup complete!"
EOF

    sed -i '' "s/LAB_DISPLAY_NAME/$lab_display_name/g" "$lab_path/scripts/cleanup.sh"
    sed -i '' "s/LAB_CLAB_NAME/$lab_clab_name/g" "$lab_path/scripts/cleanup.sh"
    chmod +x "$lab_path/scripts/cleanup.sh"
}

# Helper function to create devcontainer.json
create_devcontainer() {
    local lab_path="$1"
    local lab_display_name="$2"
    
    cat > "$lab_path/.devcontainer/devcontainer.json" << 'EOF'
{
  "name": "LAB_DISPLAY_NAME",
  "image": "ghcr.io/srl-labs/containerlab:latest",
  "features": {
    "ghcr.io/devcontainers/features/docker-outside-of-docker:1": {}
  },
  "customizations": {
    "vscode": {
      "extensions": ["ms-azuretools.vscode-docker"]
    }
  },
  "postCreateCommand": "containerlab version",
  "remoteUser": "root"
}
EOF

    sed -i '' "s/LAB_DISPLAY_NAME/$lab_display_name/g" "$lab_path/.devcontainer/devcontainer.json"
}

# Create scripts for each lab
BASE="/Users/bhunt/development/claude/comptia-certification-labs"

# Linux+ iptables Firewall
create_deploy_script "$BASE/linux-plus/02-iptables-firewall-basics" "iptables Firewall Basics Lab" "iptables-firewall-basics"
create_cleanup_script "$BASE/linux-plus/02-iptables-firewall-basics" "iptables Firewall Basics Lab" "iptables-firewall-basics"
create_devcontainer "$BASE/linux-plus/02-iptables-firewall-basics" "iptables Firewall Basics Lab"

# Linux+ systemd Service Management  
create_deploy_script "$BASE/linux-plus/03-systemd-service-management" "systemd Service Management Lab" "systemd-service-management"
create_cleanup_script "$BASE/linux-plus/03-systemd-service-management" "systemd Service Management Lab" "systemd-service-management"
create_devcontainer "$BASE/linux-plus/03-systemd-service-management" "systemd Service Management Lab"

# Security+ DMZ Network Design
create_deploy_script "$BASE/security-plus/01-dmz-network-design" "DMZ Network Design Lab" "dmz-network-design"
create_cleanup_script "$BASE/security-plus/01-dmz-network-design" "DMZ Network Design Lab" "dmz-network-design"
create_devcontainer "$BASE/security-plus/01-dmz-network-design" "DMZ Network Design Lab"

# Security+ SSH Key Authentication
create_deploy_script "$BASE/security-plus/02-ssh-key-authentication" "SSH Key Authentication Lab" "ssh-key-authentication"
create_cleanup_script "$BASE/security-plus/02-ssh-key-authentication" "SSH Key Authentication Lab" "ssh-key-authentication"
create_devcontainer "$BASE/security-plus/02-ssh-key-authentication" "SSH Key Authentication Lab"

# Security+ Network Segmentation
create_deploy_script "$BASE/security-plus/03-network-segmentation-zones" "Network Segmentation with Zones Lab" "network-segmentation-zones"
create_cleanup_script "$BASE/security-plus/03-network-segmentation-zones" "Network Segmentation with Zones Lab" "network-segmentation-zones"
create_devcontainer "$BASE/security-plus/03-network-segmentation-zones" "Network Segmentation with Zones Lab"

echo "✅ All deploy/cleanup/devcontainer scripts created!"

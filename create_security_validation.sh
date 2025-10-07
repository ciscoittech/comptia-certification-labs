#!/bin/bash

BASE="/Users/bhunt/development/claude/comptia-certification-labs/security-plus"

# ============================================
# DMZ Network Design Validation
# ============================================

cat > "$BASE/01-dmz-network-design/scripts/validate.sh" << 'DMZVAL'
#!/bin/bash

set -e

GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

PASSED=0
FAILED=0

run_test() {
    echo -n "Testing: $1 ... "
    if eval "$2" &> /dev/null; then
        echo -e "${GREEN}✅ PASS${NC}"
        ((PASSED++))
    else
        echo -e "${RED}❌ FAIL${NC}"
        ((FAILED++))
    fi
}

echo "========================================"
echo "DMZ Network Design Lab Validation"
echo "========================================"
echo ""

echo "1. Container Status (5 nodes)"
echo "-------------------------------------------"
run_test "Firewall running" \
    "docker exec clab-dmz-network-design-firewall ip addr show eth1"
run_test "DMZ-web running" \
    "docker exec clab-dmz-network-design-dmz-web ip addr show eth1"
run_test "Internal-db running" \
    "docker exec clab-dmz-network-design-internal-db ip addr show eth1"
run_test "Internal-client running" \
    "docker exec clab-dmz-network-design-internal-client ip addr show eth1"
run_test "External-client running" \
    "docker exec clab-dmz-network-design-external-client ip addr show eth1"

echo ""
echo "2. IP Configuration"
echo "-------------------------------------------"
run_test "Firewall external IP (203.0.113.1)" \
    "docker exec clab-dmz-network-design-firewall ip addr show eth1 | grep '203.0.113.1'"
run_test "Firewall DMZ IP (10.10.10.1)" \
    "docker exec clab-dmz-network-design-firewall ip addr show eth2 | grep '10.10.10.1'"
run_test "Firewall internal IP (192.168.1.1)" \
    "docker exec clab-dmz-network-design-firewall ip addr show eth3 | grep '192.168.1.1'"

echo ""
echo "3. Firewall Configuration"
echo "-------------------------------------------"
run_test "IP forwarding enabled" \
    "docker exec clab-dmz-network-design-firewall sysctl net.ipv4.ip_forward | grep '= 1'"
run_test "FORWARD policy is DROP" \
    "docker exec clab-dmz-network-design-firewall iptables -L FORWARD -n | grep 'policy DROP'"
run_test "Allow established connections" \
    "docker exec clab-dmz-network-design-firewall iptables -L FORWARD -n | grep 'state RELATED,ESTABLISHED'"

echo ""
echo "4. Zone Isolation Tests"
echo "-------------------------------------------"
run_test "External can reach DMZ webserver (HTTP)" \
    "docker exec clab-dmz-network-design-external-client curl -s --max-time 5 http://10.10.10.10 | grep -i 'dmz\\|html'"
run_test "Internal client can reach DMZ" \
    "docker exec clab-dmz-network-design-internal-client ping -c 2 -W 2 10.10.10.10"

echo ""
echo "5. DMZ Services"
echo "-------------------------------------------"
run_test "Nginx running on DMZ webserver" \
    "docker exec clab-dmz-network-design-dmz-web sh -c 'ps | grep nginx | grep -v grep'"

echo ""
echo "========================================"
echo "Validation Summary"
echo "========================================"
echo -e "Tests Passed: ${GREEN}$PASSED${NC}"
echo -e "Tests Failed: ${RED}$FAILED${NC}"
echo ""

if [ $FAILED -eq 0 ]; then
    echo -e "${GREEN}✅ All tests passed!${NC}"
    exit 0
else
    echo -e "${RED}❌ Some tests failed.${NC}"
    exit 1
fi
DMZVAL

chmod +x "$BASE/01-dmz-network-design/scripts/validate.sh"

# ============================================
# SSH Key Authentication Validation
# ============================================

cat > "$BASE/02-ssh-key-authentication/scripts/validate.sh" << 'SSHVAL'
#!/bin/bash

set -e

GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

PASSED=0
FAILED=0

run_test() {
    echo -n "Testing: $1 ... "
    if eval "$2" &> /dev/null; then
        echo -e "${GREEN}✅ PASS${NC}"
        ((PASSED++))
    else
        echo -e "${RED}❌ FAIL${NC}"
        ((FAILED++))
    fi
}

echo "========================================"
echo "SSH Key Authentication Lab Validation"
echo "========================================"
echo ""

echo "1. Container Status"
echo "-------------------------------------------"
run_test "SSH server running" \
    "docker exec clab-ssh-key-authentication-ssh-server ip addr show eth1"
run_test "SSH client running" \
    "docker exec clab-ssh-key-authentication-ssh-client ip addr show eth1"

echo ""
echo "2. IP Configuration"
echo "-------------------------------------------"
run_test "Server has 192.168.1.10" \
    "docker exec clab-ssh-key-authentication-ssh-server ip addr show eth1 | grep '192.168.1.10'"
run_test "Client has 192.168.1.20" \
    "docker exec clab-ssh-key-authentication-ssh-client ip addr show eth1 | grep '192.168.1.20'"

echo ""
echo "3. SSH Services"
echo "-------------------------------------------"
run_test "SSH daemon running on server" \
    "docker exec clab-ssh-key-authentication-ssh-server sh -c 'ps | grep sshd | grep -v grep'"
run_test "SSH port 22 listening" \
    "docker exec clab-ssh-key-authentication-ssh-server netstat -tuln | grep ':22'"

echo ""
echo "4. SSH Tools Available"
echo "-------------------------------------------"
run_test "Client has ssh-keygen" \
    "docker exec clab-ssh-key-authentication-ssh-client which ssh-keygen"
run_test "Client has ssh" \
    "docker exec clab-ssh-key-authentication-ssh-client which ssh"

echo ""
echo "5. Connectivity"
echo "-------------------------------------------"
run_test "Client can ping server" \
    "docker exec clab-ssh-key-authentication-ssh-client ping -c 2 -W 2 192.168.1.10"

echo ""
echo "========================================"
echo "Validation Summary"
echo "========================================"
echo -e "Tests Passed: ${GREEN}$PASSED${NC}"
echo -e "Tests Failed: ${RED}$FAILED${NC}"
echo ""

if [ $FAILED -eq 0 ]; then
    echo -e "${GREEN}✅ All tests passed!${NC}"
    exit 0
else
    echo -e "${RED}❌ Some tests failed.${NC}"
    exit 1
fi
SSHVAL

chmod +x "$BASE/02-ssh-key-authentication/scripts/validate.sh"

# ============================================
# Network Segmentation Validation
# ============================================

cat > "$BASE/03-network-segmentation-zones/scripts/validate.sh" << 'SEGVAL'
#!/bin/bash

set -e

GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

PASSED=0
FAILED=0

run_test() {
    echo -n "Testing: $1 ... "
    if eval "$2" &> /dev/null; then
        echo -e "${GREEN}✅ PASS${NC}"
        ((PASSED++))
    else
        echo -e "${RED}❌ FAIL${NC}"
        ((FAILED++))
    fi
}

echo "========================================"
echo "Network Segmentation Lab Validation"
echo "========================================"
echo ""

echo "1. Container Status"
echo "-------------------------------------------"
run_test "Firewall running" \
    "docker exec clab-network-segmentation-zones-firewall ip addr show eth1"
run_test "HR client running" \
    "docker exec clab-network-segmentation-zones-hr-client ip addr show eth1"
run_test "Engineering client running" \
    "docker exec clab-network-segmentation-zones-eng-client ip addr show eth1"
run_test "Guest client running" \
    "docker exec clab-network-segmentation-zones-guest-client ip addr show eth1"
run_test "Internet server running" \
    "docker exec clab-network-segmentation-zones-internet-server ip addr show eth1"

echo ""
echo "2. VLAN/Zone IP Configuration"
echo "-------------------------------------------"
run_test "Firewall VLAN 10 (HR) - 10.10.0.1" \
    "docker exec clab-network-segmentation-zones-firewall ip addr show eth1 | grep '10.10.0.1'"
run_test "Firewall VLAN 20 (Eng) - 10.20.0.1" \
    "docker exec clab-network-segmentation-zones-firewall ip addr show eth2 | grep '10.20.0.1'"
run_test "Firewall VLAN 30 (Guest) - 10.30.0.1" \
    "docker exec clab-network-segmentation-zones-firewall ip addr show eth3 | grep '10.30.0.1'"
run_test "HR client has 10.10.0.10" \
    "docker exec clab-network-segmentation-zones-hr-client ip addr show eth1 | grep '10.10.0.10'"
run_test "Engineering client has 10.20.0.10" \
    "docker exec clab-network-segmentation-zones-eng-client ip addr show eth1 | grep '10.20.0.10'"
run_test "Guest client has 10.30.0.10" \
    "docker exec clab-network-segmentation-zones-guest-client ip addr show eth1 | grep '10.30.0.10'"

echo ""
echo "3. Firewall Configuration"
echo "-------------------------------------------"
run_test "IP forwarding enabled" \
    "docker exec clab-network-segmentation-zones-firewall sysctl net.ipv4.ip_forward | grep '= 1'"
run_test "FORWARD policy is DROP" \
    "docker exec clab-network-segmentation-zones-firewall iptables -L FORWARD -n | grep 'policy DROP'"

echo ""
echo "4. Zone Connectivity (Allowed)"
echo "-------------------------------------------"
run_test "HR can reach internet" \
    "docker exec clab-network-segmentation-zones-hr-client ping -c 2 -W 2 203.0.113.10"
run_test "Engineering can reach internet" \
    "docker exec clab-network-segmentation-zones-eng-client ping -c 2 -W 2 203.0.113.10"
run_test "Guest can reach internet (ping)" \
    "docker exec clab-network-segmentation-zones-guest-client curl -s --max-time 5 http://203.0.113.10 | grep -i 'html\\|directory'"

echo ""
echo "5. Zone Isolation (Blocked)"
echo "-------------------------------------------"
run_test "HR cannot reach Engineering (blocked)" \
    "! docker exec clab-network-segmentation-zones-hr-client ping -c 2 -W 2 10.20.0.10"
run_test "Guest cannot reach HR (blocked)" \
    "! docker exec clab-network-segmentation-zones-guest-client ping -c 2 -W 2 10.10.0.10"

echo ""
echo "========================================"
echo "Validation Summary"
echo "========================================"
echo -e "Tests Passed: ${GREEN}$PASSED${NC}"
echo -e "Tests Failed: ${RED}$FAILED${NC}"
echo ""

if [ $FAILED -eq 0 ]; then
    echo -e "${GREEN}✅ All tests passed!${NC}"
    exit 0
else
    echo -e "${RED}❌ Some tests failed.${NC}"
    exit 1
fi
SEGVAL

chmod +x "$BASE/03-network-segmentation-zones/scripts/validate.sh"

echo "✅ All Security+ validation scripts created!"

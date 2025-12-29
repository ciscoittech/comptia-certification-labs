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
        ((PASSED++)) || true
    else
        echo -e "${RED}❌ FAIL${NC}"
        ((FAILED++)) || true
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

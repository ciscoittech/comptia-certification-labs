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
    "docker exec clab-dmz-network-design-firewall ip addr show br-internal | grep '192.168.1.1'"

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

#!/bin/bash

# Network Interface Configuration Lab - Validation Script

set -e

echo "========================================"
echo "Network Interface Configuration Lab Validation"
echo "========================================"
echo ""

GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

PASSED=0
FAILED=0

run_test() {
    local test_name="$1"
    local command="$2"
    echo -n "Testing: $test_name ... "
    if eval "$command" &> /dev/null; then
        echo -e "${GREEN}✅ PASS${NC}"
        ((PASSED++)) || true
    else
        echo -e "${RED}❌ FAIL${NC}"
        ((FAILED++)) || true
    fi
}

echo "1. Container Status"
echo "-------------------------------------------"
run_test "Host1 container running" \
    "docker exec clab-network-interface-config-host1 ip addr show eth1"
run_test "Host2 container running" \
    "docker exec clab-network-interface-config-host2 ip addr show eth1"

echo ""
echo "2. IP Configuration"
echo "-------------------------------------------"
run_test "Host1 has 192.168.1.10" \
    "docker exec clab-network-interface-config-host1 ip addr show eth1 | grep '192.168.1.10'"
run_test "Host2 has 192.168.1.20" \
    "docker exec clab-network-interface-config-host2 ip addr show eth1 | grep '192.168.1.20'"

echo ""
echo "3. Interface State"
echo "-------------------------------------------"
run_test "Host1 eth1 is UP" \
    "docker exec clab-network-interface-config-host1 ip link show eth1 | grep 'state UP'"
run_test "Host2 eth1 is UP" \
    "docker exec clab-network-interface-config-host2 ip link show eth1 | grep 'state UP'"

echo ""
echo "4. Connectivity"
echo "-------------------------------------------"
run_test "Host1 can ping host2" \
    "docker exec clab-network-interface-config-host1 ping -c 2 -W 2 192.168.1.20"
run_test "Host2 can ping host1" \
    "docker exec clab-network-interface-config-host2 ping -c 2 -W 2 192.168.1.10"

echo ""
echo "5. ARP/Neighbor Discovery"
echo "-------------------------------------------"
docker exec clab-network-interface-config-host1 ping -c 1 192.168.1.20 &> /dev/null || true
sleep 1
run_test "Host1 has ARP entry for host2" \
    "docker exec clab-network-interface-config-host1 ip neigh show 192.168.1.20"

echo ""
echo "6. Routing Table"
echo "-------------------------------------------"
run_test "Host1 has connected route to 192.168.1.0/24" \
    "docker exec clab-network-interface-config-host1 ip route show | grep '192.168.1.0/24'"
run_test "Host2 has connected route to 192.168.1.0/24" \
    "docker exec clab-network-interface-config-host2 ip route show | grep '192.168.1.0/24'"

echo ""
echo "7. MTU Configuration"
echo "-------------------------------------------"
run_test "Host1 eth1 MTU is 1500" \
    "docker exec clab-network-interface-config-host1 ip link show eth1 | grep 'mtu 1500'"
run_test "Host2 eth1 MTU is 1500" \
    "docker exec clab-network-interface-config-host2 ip link show eth1 | grep 'mtu 1500'"

echo ""
echo "8. Advanced ip Commands"
echo "-------------------------------------------"
run_test "ip -br addr works on host1" \
    "docker exec clab-network-interface-config-host1 ip -br addr show"
run_test "ip -br link works on host1" \
    "docker exec clab-network-interface-config-host1 ip -br link show"
run_test "ip route get works on host1" \
    "docker exec clab-network-interface-config-host1 ip route get 192.168.1.20"
run_test "ip neigh show works on host1" \
    "docker exec clab-network-interface-config-host1 ip neigh show"

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

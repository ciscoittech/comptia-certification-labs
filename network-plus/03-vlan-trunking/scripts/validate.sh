#!/bin/bash

# VLAN Configuration & Trunking Lab - Validation Script
# Tests VLAN isolation, trunking, and inter-VLAN routing

set -e

echo "========================================"
echo "VLAN Lab Validation Tests"
echo "========================================"
echo ""

# Color codes for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

PASSED=0
FAILED=0

# Test function
run_test() {
    local test_name="$1"
    local command="$2"
    local expected_result="$3"

    echo -n "Testing: $test_name ... "

    if eval "$command" &> /dev/null; then
        echo -e "${GREEN}✅ PASS${NC}"
        ((PASSED++))
    else
        echo -e "${RED}❌ FAIL${NC}"
        ((FAILED++))
    fi
}

# Test 1: Verify all containers are running
echo "1. Container Status Checks"
echo "-------------------------------------------"

run_test "sw1 container running" \
    "docker exec clab-vlan-trunking-basics-sw1 ip addr show br0" \
    "success"

run_test "sw2 container running" \
    "docker exec clab-vlan-trunking-basics-sw2 ip addr show br0" \
    "success"

run_test "client1 container running" \
    "docker exec clab-vlan-trunking-basics-client1 ip addr show eth1" \
    "success"

run_test "client2 container running" \
    "docker exec clab-vlan-trunking-basics-client2 ip addr show eth1" \
    "success"

run_test "client3 container running" \
    "docker exec clab-vlan-trunking-basics-client3 ip addr show eth1" \
    "success"

run_test "client4 container running" \
    "docker exec clab-vlan-trunking-basics-client4 ip addr show eth1" \
    "success"

run_test "client5 container running (VLAN 30)" \
    "docker exec clab-vlan-trunking-basics-client5 ip addr show eth1" \
    "success"

echo ""

# Test 2: VLAN Configuration on sw1
echo "2. VLAN Interface Configuration"
echo "-------------------------------------------"

run_test "sw1 VLAN 10 interface exists" \
    "docker exec clab-vlan-trunking-basics-sw1 ip addr show br0.10 | grep '10.10.10.1'" \
    "success"

run_test "sw1 VLAN 20 interface exists" \
    "docker exec clab-vlan-trunking-basics-sw1 ip addr show br0.20 | grep '10.10.20.1'" \
    "success"

run_test "sw1 VLAN 30 interface exists" \
    "docker exec clab-vlan-trunking-basics-sw1 ip addr show br0.30 | grep '10.10.30.1'" \
    "success"

run_test "sw2 bridge VLAN filtering configured" \
    "docker exec clab-vlan-trunking-basics-sw2 bridge vlan show dev eth1 | grep '10'" \
    "success"

run_test "sw2 trunk carries VLAN 20" \
    "docker exec clab-vlan-trunking-basics-sw2 bridge vlan show dev eth1 | grep '20'" \
    "success"

echo ""

# Test 3: VLAN 10 Connectivity (Same VLAN)
echo "3. VLAN 10 Connectivity Tests"
echo "-------------------------------------------"

run_test "client1 can ping sw1 (VLAN 10 gateway)" \
    "docker exec clab-vlan-trunking-basics-client1 ping -c 2 -W 2 10.10.10.1" \
    "success"

run_test "client1 can ping client3 (same VLAN)" \
    "docker exec clab-vlan-trunking-basics-client1 ping -c 2 -W 2 10.10.10.11" \
    "success"

run_test "client3 can ping client1 (same VLAN)" \
    "docker exec clab-vlan-trunking-basics-client3 ping -c 2 -W 2 10.10.10.10" \
    "success"

echo ""

# Test 4: VLAN 20 Connectivity (Same VLAN)
echo "4. VLAN 20 Connectivity Tests"
echo "-------------------------------------------"

run_test "client2 can ping sw1 (VLAN 20 gateway)" \
    "docker exec clab-vlan-trunking-basics-client2 ping -c 2 -W 2 10.10.20.1" \
    "success"

run_test "client2 can ping client4 (same VLAN)" \
    "docker exec clab-vlan-trunking-basics-client2 ping -c 2 -W 2 10.10.20.11" \
    "success"

run_test "client4 can ping client2 (same VLAN)" \
    "docker exec clab-vlan-trunking-basics-client4 ping -c 2 -W 2 10.10.20.10" \
    "success"

echo ""

# Test 5: Inter-VLAN Routing
echo "5. Inter-VLAN Routing Tests"
echo "-------------------------------------------"

run_test "client1 (VLAN 10) can ping client2 (VLAN 20)" \
    "docker exec clab-vlan-trunking-basics-client1 ping -c 2 -W 2 10.10.20.10" \
    "success"

run_test "client2 (VLAN 20) can ping client1 (VLAN 10)" \
    "docker exec clab-vlan-trunking-basics-client2 ping -c 2 -W 2 10.10.10.10" \
    "success"

run_test "client1 (VLAN 10) can ping client4 (VLAN 20)" \
    "docker exec clab-vlan-trunking-basics-client1 ping -c 2 -W 2 10.10.20.11" \
    "success"

echo ""

# Test 6: Bridge VLAN Configuration
echo "6. Bridge VLAN Configuration Tests"
echo "-------------------------------------------"

run_test "sw1 bridge has VLAN filtering enabled" \
    "docker exec clab-vlan-trunking-basics-sw1 ip -d link show br0 | grep 'vlan_filtering 1'" \
    "success"

run_test "sw2 bridge has VLAN filtering enabled" \
    "docker exec clab-vlan-trunking-basics-sw2 ip -d link show br0 | grep 'vlan_filtering 1'" \
    "success"

run_test "sw1 trunk port carries VLAN 10" \
    "docker exec clab-vlan-trunking-basics-sw1 bridge vlan show dev eth1 | grep '10'" \
    "success"

run_test "sw2 trunk port carries VLAN 10" \
    "docker exec clab-vlan-trunking-basics-sw2 bridge vlan show dev eth1 | grep '10'" \
    "success"

echo ""

# Test 7: IP Forwarding (Required for Inter-VLAN Routing)
echo "7. IP Forwarding Configuration"
echo "-------------------------------------------"

run_test "sw1 IP forwarding enabled" \
    "docker exec clab-vlan-trunking-basics-sw1 sysctl net.ipv4.ip_forward | grep '= 1'" \
    "success"

echo ""

# Summary
echo "========================================"
echo "Validation Summary"
echo "========================================"
echo -e "Tests Passed: ${GREEN}$PASSED${NC}"
echo -e "Tests Failed: ${RED}$FAILED${NC}"
echo ""

if [ $FAILED -eq 0 ]; then
    echo -e "${GREEN}✅ All tests passed! Lab is functioning correctly.${NC}"
    exit 0
else
    echo -e "${RED}❌ Some tests failed. Review the output above.${NC}"
    exit 1
fi

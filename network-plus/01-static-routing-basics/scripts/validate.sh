#!/bin/bash

# Static Routing Basics Lab - Validation Script

set -e

echo "========================================"
echo "Static Routing Lab Validation"
echo "========================================"
echo ""

# Color codes
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
        ((PASSED++))
    else
        echo -e "${RED}❌ FAIL${NC}"
        ((FAILED++))
    fi
}

# Test 1: Container Status
echo "1. Container Status Checks"
echo "-------------------------------------------"

run_test "R1 container running" \
    "docker exec clab-static-routing-basics-r1 ip addr show eth1"

run_test "R2 container running" \
    "docker exec clab-static-routing-basics-r2 ip addr show eth1"

run_test "R3 container running" \
    "docker exec clab-static-routing-basics-r3 ip addr show eth1"

run_test "PC1 container running" \
    "docker exec clab-static-routing-basics-pc1 ip addr show eth1"

run_test "PC2 container running" \
    "docker exec clab-static-routing-basics-pc2 ip addr show eth1"

echo ""

# Test 2: IP Configuration
echo "2. IP Address Configuration"
echo "-------------------------------------------"

run_test "R1 eth1 has 10.1.1.1" \
    "docker exec clab-static-routing-basics-r1 ip addr show eth1 | grep '10.1.1.1'"

run_test "R2 eth1 has 10.1.2.2" \
    "docker exec clab-static-routing-basics-r2 ip addr show eth1 | grep '10.1.2.2'"

run_test "R3 eth2 has 10.3.3.3" \
    "docker exec clab-static-routing-basics-r3 ip addr show eth2 | grep '10.3.3.3'"

run_test "PC1 has 10.1.1.10" \
    "docker exec clab-static-routing-basics-pc1 ip addr show eth1 | grep '10.1.1.10'"

run_test "PC2 has 10.3.3.10" \
    "docker exec clab-static-routing-basics-pc2 ip addr show eth1 | grep '10.3.3.10'"

echo ""

# Test 3: Routing Tables
echo "3. Routing Table Verification"
echo "-------------------------------------------"

run_test "R1 has route to 10.3.3.0/24" \
    "docker exec clab-static-routing-basics-r1 ip route show | grep '10.3.3.0/24'"

run_test "R2 has route to 10.1.1.0/24" \
    "docker exec clab-static-routing-basics-r2 ip route show | grep '10.1.1.0/24'"

run_test "R3 has route to 10.1.2.0/24" \
    "docker exec clab-static-routing-basics-r3 ip route show | grep '10.1.2.0/24'"

run_test "PC1 has default route" \
    "docker exec clab-static-routing-basics-pc1 ip route show | grep 'default via 10.1.1.1'"

run_test "PC2 has default route" \
    "docker exec clab-static-routing-basics-pc2 ip route show | grep 'default via 10.3.3.3'"

echo ""

# Test 4: IP Forwarding
echo "4. IP Forwarding Configuration"
echo "-------------------------------------------"

run_test "R1 IP forwarding enabled" \
    "docker exec clab-static-routing-basics-r1 sysctl net.ipv4.ip_forward | grep '= 1'"

run_test "R2 IP forwarding enabled" \
    "docker exec clab-static-routing-basics-r2 sysctl net.ipv4.ip_forward | grep '= 1'"

run_test "R3 IP forwarding enabled" \
    "docker exec clab-static-routing-basics-r3 sysctl net.ipv4.ip_forward | grep '= 1'"

echo ""

# Test 5: Connectivity
echo "5. Connectivity Tests"
echo "-------------------------------------------"

run_test "PC1 can ping R1 (default gateway)" \
    "docker exec clab-static-routing-basics-pc1 ping -c 2 -W 2 10.1.1.1"

run_test "R1 can ping R2" \
    "docker exec clab-static-routing-basics-r1 ping -c 2 -W 2 10.1.2.2"

run_test "R2 can ping R3" \
    "docker exec clab-static-routing-basics-r2 ping -c 2 -W 2 10.2.2.3"

run_test "R3 can ping PC2" \
    "docker exec clab-static-routing-basics-r3 ping -c 2 -W 2 10.3.3.10"

run_test "PC1 can ping PC2 (end-to-end)" \
    "docker exec clab-static-routing-basics-pc1 ping -c 2 -W 2 10.3.3.10"

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
    echo -e "${RED}❌ Some tests failed. Review configuration.${NC}"
    exit 1
fi

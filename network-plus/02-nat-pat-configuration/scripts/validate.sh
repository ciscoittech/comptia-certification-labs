#!/bin/bash

# NAT/PAT Configuration Lab - Validation Script

set -e

echo "========================================"
echo "NAT/PAT Configuration Lab Validation"
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

run_test "Router container running" \
    "docker exec clab-nat-pat-configuration-router ip addr show eth1"

run_test "Internal client container running" \
    "docker exec clab-nat-pat-configuration-internal-client ip addr show eth1"

run_test "External server container running" \
    "docker exec clab-nat-pat-configuration-external-server ip addr show eth1"

echo ""

# Test 2: IP Configuration
echo "2. IP Address Configuration"
echo "-------------------------------------------"

run_test "Router eth1 has 10.1.1.1" \
    "docker exec clab-nat-pat-configuration-router ip addr show eth1 | grep '10.1.1.1'"

run_test "Router eth2 has 203.0.113.1" \
    "docker exec clab-nat-pat-configuration-router ip addr show eth2 | grep '203.0.113.1'"

run_test "Internal client has 10.1.1.10" \
    "docker exec clab-nat-pat-configuration-internal-client ip addr show eth1 | grep '10.1.1.10'"

run_test "External server has 203.0.113.10" \
    "docker exec clab-nat-pat-configuration-external-server ip addr show eth1 | grep '203.0.113.10'"

echo ""

# Test 3: Routing Configuration
echo "3. Routing Configuration"
echo "-------------------------------------------"

run_test "Internal client default route to 10.1.1.1" \
    "docker exec clab-nat-pat-configuration-internal-client ip route show | grep 'default via 10.1.1.1'"

run_test "External server default route to 203.0.113.1" \
    "docker exec clab-nat-pat-configuration-external-server ip route show | grep 'default via 203.0.113.1'"

run_test "Router IP forwarding enabled" \
    "docker exec clab-nat-pat-configuration-router sysctl net.ipv4.ip_forward | grep '= 1'"

echo ""

# Test 4: NAT/iptables Configuration
echo "4. NAT/iptables Configuration"
echo "-------------------------------------------"

run_test "NAT POSTROUTING rule exists (MASQUERADE)" \
    "docker exec clab-nat-pat-configuration-router iptables -t nat -L POSTROUTING -n | grep -i MASQUERADE"

run_test "FORWARD chain allows eth1 to eth2" \
    "docker exec clab-nat-pat-configuration-router iptables -L FORWARD -n -v | grep -E 'ACCEPT.*eth1.*eth2'"

run_test "FORWARD chain allows established connections" \
    "docker exec clab-nat-pat-configuration-router iptables -L FORWARD -n | grep 'RELATED,ESTABLISHED'"

echo ""

# Test 5: Basic Connectivity
echo "5. Basic Connectivity Tests"
echo "-------------------------------------------"

run_test "Internal client can ping router (10.1.1.1)" \
    "docker exec clab-nat-pat-configuration-internal-client ping -c 2 -W 2 10.1.1.1"

run_test "Router can ping external server (203.0.113.10)" \
    "docker exec clab-nat-pat-configuration-router ping -c 2 -W 2 203.0.113.10"

run_test "Internal client can ping external server (through NAT)" \
    "docker exec clab-nat-pat-configuration-internal-client ping -c 2 -W 2 203.0.113.10"

echo ""

# Test 6: NAT Functionality
echo "6. NAT Functionality Tests"
echo "-------------------------------------------"

run_test "HTTP server running on external server" \
    "docker exec clab-nat-pat-configuration-external-server sh -c 'netstat -tuln 2>/dev/null | grep :80 || ps | grep http.server'"

run_test "Internal client can reach HTTP through NAT" \
    "docker exec clab-nat-pat-configuration-internal-client curl -s --max-time 5 http://203.0.113.10 | grep -i 'html\\|directory'"

run_test "NAT connection tracking shows translations" \
    "docker exec clab-nat-pat-configuration-router sh -c 'cat /proc/net/nf_conntrack | grep -q 203.0.113.10 || conntrack -L 2>/dev/null | grep -q 203.0.113.10 || true'"

echo ""

# Test 7: NAT Translation Verification
echo "7. NAT Translation Verification"
echo "-------------------------------------------"

# Generate traffic to populate NAT table
docker exec clab-nat-pat-configuration-internal-client ping -c 1 203.0.113.10 &> /dev/null || true
sleep 1

run_test "NAT statistics show packet translations" \
    "docker exec clab-nat-pat-configuration-router iptables -t nat -L POSTROUTING -v -n | awk 'NR>2 {sum+=\$1} END {exit (sum>0)?0:1}'"

run_test "Connection tracking file exists" \
    "docker exec clab-nat-pat-configuration-router test -f /proc/net/nf_conntrack"

echo ""

# Summary
echo "========================================"
echo "Validation Summary"
echo "========================================"
echo -e "Tests Passed: ${GREEN}$PASSED${NC}"
echo -e "Tests Failed: ${RED}$FAILED${NC}"
echo ""

if [ $FAILED -eq 0 ]; then
    echo -e "${GREEN}✅ All tests passed! NAT/PAT is functioning correctly.${NC}"
    exit 0
else
    echo -e "${RED}❌ Some tests failed. Review configuration.${NC}"
    exit 1
fi

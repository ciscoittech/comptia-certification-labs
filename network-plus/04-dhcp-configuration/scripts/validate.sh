#!/bin/bash

# DHCP Configuration Lab - Validation Script

set -e

echo "========================================"
echo "DHCP Configuration Lab Validation"
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

run_test "DHCP server container running" \
    "docker exec clab-dhcp-configuration-dhcp-server ip addr show eth1"

run_test "Client1 container running" \
    "docker exec clab-dhcp-configuration-client1 ip addr show eth1"

run_test "Client2 container running" \
    "docker exec clab-dhcp-configuration-client2 ip addr show eth1"

run_test "Client3 container running" \
    "docker exec clab-dhcp-configuration-client3 ip addr show eth1"

echo ""

# Test 2: DHCP Server Configuration
echo "2. DHCP Server Configuration"
echo "-------------------------------------------"

run_test "DHCP server has 10.1.1.1 on eth1" \
    "docker exec clab-dhcp-configuration-dhcp-server ip addr show eth1 | grep '10.1.1.1'"

run_test "dnsmasq process is running" \
    "docker exec clab-dhcp-configuration-dhcp-server sh -c 'ps aux | grep -v grep | grep dnsmasq'"

run_test "dnsmasq config defines DHCP range" \
    "docker exec clab-dhcp-configuration-dhcp-server grep 'dhcp-range' /etc/dnsmasq.conf"

run_test "dnsmasq config has router option" \
    "docker exec clab-dhcp-configuration-dhcp-server grep 'option:router' /etc/dnsmasq.conf"

run_test "dnsmasq config has DNS option" \
    "docker exec clab-dhcp-configuration-dhcp-server grep 'option:dns-server' /etc/dnsmasq.conf"

run_test "DHCP reservation configured" \
    "docker exec clab-dhcp-configuration-dhcp-server grep 'dhcp-host' /etc/dnsmasq.conf"

echo ""

# Test 3: Client IP Assignment
echo "3. Client IP Assignment (DHCP Leases)"
echo "-------------------------------------------"

run_test "Client1 has an IP address on eth1" \
    "docker exec clab-dhcp-configuration-client1 ip addr show eth1 | grep 'inet '"

run_test "Client1 IP is in 10.1.1.0/24 subnet" \
    "docker exec clab-dhcp-configuration-client1 ip addr show eth1 | grep 'inet 10.1.1.'"

run_test "Client2 has an IP address on eth1" \
    "docker exec clab-dhcp-configuration-client2 ip addr show eth1 | grep 'inet '"

run_test "Client2 IP is in 10.1.1.0/24 subnet" \
    "docker exec clab-dhcp-configuration-client2 ip addr show eth1 | grep 'inet 10.1.1.'"

run_test "Client3 has an IP address on eth1" \
    "docker exec clab-dhcp-configuration-client3 ip addr show eth1 | grep 'inet '"

run_test "Client3 IP is in 10.1.1.0/24 subnet" \
    "docker exec clab-dhcp-configuration-client3 ip addr show eth1 | grep 'inet 10.1.1.'"

echo ""

# Test 4: DHCP Options Delivered
echo "4. DHCP Options Verification"
echo "-------------------------------------------"

run_test "Client1 received default gateway via DHCP" \
    "docker exec clab-dhcp-configuration-client1 ip route show | grep 'default via 10.1.1.1'"

run_test "Client2 received default gateway via DHCP" \
    "docker exec clab-dhcp-configuration-client2 ip route show | grep 'default via 10.1.1.1'"

run_test "Client3 received default gateway via DHCP" \
    "docker exec clab-dhcp-configuration-client3 ip route show | grep 'default via 10.1.1.1'"

run_test "Client1 received DNS server via DHCP" \
    "docker exec clab-dhcp-configuration-client1 sh -c 'cat /etc/resolv.conf | grep nameserver'"

echo ""

# Test 5: Lease File
echo "5. DHCP Lease Database"
echo "-------------------------------------------"

run_test "Lease file exists on DHCP server" \
    "docker exec clab-dhcp-configuration-dhcp-server test -f /var/lib/misc/dnsmasq.leases"

run_test "Lease file has active entries" \
    "docker exec clab-dhcp-configuration-dhcp-server sh -c 'test \$(wc -l < /var/lib/misc/dnsmasq.leases) -gt 0'"

run_test "At least one client IP in lease file" \
    "docker exec clab-dhcp-configuration-dhcp-server grep '10.1.1.' /var/lib/misc/dnsmasq.leases"

echo ""

# Test 6: Connectivity
echo "6. Connectivity Tests"
echo "-------------------------------------------"

run_test "Client1 can ping DHCP server" \
    "docker exec clab-dhcp-configuration-client1 ping -c 2 -W 2 10.1.1.1"

run_test "Client2 can ping DHCP server" \
    "docker exec clab-dhcp-configuration-client2 ping -c 2 -W 2 10.1.1.1"

run_test "Client3 can ping DHCP server" \
    "docker exec clab-dhcp-configuration-client3 ping -c 2 -W 2 10.1.1.1"

echo ""

# Test 7: Pool Range Verification
echo "7. DHCP Pool Range Verification"
echo "-------------------------------------------"

run_test "Client1 IP in pool range (100-200)" \
    "docker exec clab-dhcp-configuration-client1 sh -c 'OCTET=\$(ip addr show eth1 | grep \"inet 10.1.1.\" | awk \"{print \\\$2}\" | cut -d. -f4 | cut -d/ -f1); [ \"\$OCTET\" -ge 100 ] && [ \"\$OCTET\" -le 200 ]'"

run_test "Client2 IP in pool range (100-200)" \
    "docker exec clab-dhcp-configuration-client2 sh -c 'OCTET=\$(ip addr show eth1 | grep \"inet 10.1.1.\" | awk \"{print \\\$2}\" | cut -d. -f4 | cut -d/ -f1); [ \"\$OCTET\" -ge 100 ] && [ \"\$OCTET\" -le 200 ]'"

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

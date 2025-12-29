#!/bin/bash

set -e

echo "========================================"
echo "iptables Firewall Basics Lab Validation"
echo "========================================"
echo ""

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

echo "1. Container Status"
echo "-------------------------------------------"
run_test "Firewall container running" \
    "docker exec clab-iptables-firewall-basics-firewall ip addr show eth1"
run_test "Webserver container running" \
    "docker exec clab-iptables-firewall-basics-webserver ip addr show eth1"
run_test "Client container running" \
    "docker exec clab-iptables-firewall-basics-client ip addr show eth1"

echo ""
echo "2. IP Configuration"
echo "-------------------------------------------"
run_test "Firewall eth1 has 10.1.1.1" \
    "docker exec clab-iptables-firewall-basics-firewall ip addr show eth1 | grep '10.1.1.1'"
run_test "Firewall eth2 has 10.2.2.1" \
    "docker exec clab-iptables-firewall-basics-firewall ip addr show eth2 | grep '10.2.2.1'"
run_test "Client has 10.1.1.10" \
    "docker exec clab-iptables-firewall-basics-client ip addr show eth1 | grep '10.1.1.10'"
run_test "Webserver has 10.2.2.10" \
    "docker exec clab-iptables-firewall-basics-webserver ip addr show eth1 | grep '10.2.2.10'"

echo ""
echo "3. Routing & Forwarding"
echo "-------------------------------------------"
run_test "Firewall IP forwarding enabled" \
    "docker exec clab-iptables-firewall-basics-firewall sysctl net.ipv4.ip_forward | grep '= 1'"
run_test "Client default route to firewall" \
    "docker exec clab-iptables-firewall-basics-client ip route show | grep 'default via 10.1.1.1'"
run_test "Webserver default route to firewall" \
    "docker exec clab-iptables-firewall-basics-webserver ip route show | grep 'default via 10.2.2.1'"

echo ""
echo "4. Firewall Rules"
echo "-------------------------------------------"
run_test "FORWARD policy is DROP" \
    "docker exec clab-iptables-firewall-basics-firewall iptables -L FORWARD -n | grep 'policy DROP'"
run_test "Allow HTTP rule exists" \
    "docker exec clab-iptables-firewall-basics-firewall iptables -L FORWARD -n | grep 'tcp dpt:80'"
run_test "Allow ESTABLISHED,RELATED rule exists" \
    "docker exec clab-iptables-firewall-basics-firewall iptables -L FORWARD -n | grep 'state RELATED,ESTABLISHED'"

echo ""
echo "5. Webserver Services"
echo "-------------------------------------------"
run_test "Nginx running on webserver" \
    "docker exec clab-iptables-firewall-basics-webserver sh -c 'ps | grep nginx | grep -v grep'"
run_test "Nginx listening on port 80" \
    "docker exec clab-iptables-firewall-basics-webserver ss -tuln | grep ':80'"

echo ""
echo "6. Connectivity Tests"
echo "-------------------------------------------"
run_test "Client can ping firewall" \
    "docker exec clab-iptables-firewall-basics-client ping -c 2 -W 2 10.1.1.1"
run_test "Client can ping webserver through firewall" \
    "docker exec clab-iptables-firewall-basics-client ping -c 2 -W 2 10.2.2.10"
run_test "Client can access HTTP on webserver" \
    "docker exec clab-iptables-firewall-basics-client curl -s --max-time 5 http://10.2.2.10 | grep -i 'welcome\\|html'"

echo ""
echo "7. Firewall Protection Tests"
echo "-------------------------------------------"
run_test "Firewall blocks non-HTTP traffic (timeout expected)" \
    "! docker exec clab-iptables-firewall-basics-client sh -c 'timeout 2 telnet 10.2.2.10 23 2>/dev/null'"

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

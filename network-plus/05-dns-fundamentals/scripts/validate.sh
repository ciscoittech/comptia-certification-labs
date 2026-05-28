#!/bin/bash

# DNS Fundamentals Lab - Validation Script

set -e

echo "========================================"
echo "DNS Fundamentals Lab Validation"
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

run_test "DNS server container running" \
    "docker exec clab-dns-fundamentals-dns-server ip addr show eth1"

run_test "Web server container running" \
    "docker exec clab-dns-fundamentals-web-server ip addr show eth1"

run_test "Client container running" \
    "docker exec clab-dns-fundamentals-client ip addr show eth1"

echo ""

# Test 2: IP Address Configuration
echo "2. IP Address Configuration"
echo "-------------------------------------------"

run_test "DNS server has 10.2.1.1 on eth1" \
    "docker exec clab-dns-fundamentals-dns-server ip addr show eth1 | grep '10.2.1.1'"

run_test "Web server has 10.2.1.10 on eth1" \
    "docker exec clab-dns-fundamentals-web-server ip addr show eth1 | grep '10.2.1.10'"

run_test "Client has 10.2.1.50 on eth1" \
    "docker exec clab-dns-fundamentals-client ip addr show eth1 | grep '10.2.1.50'"

echo ""

# Test 3: DNS Server Configuration
echo "3. DNS Server Configuration"
echo "-------------------------------------------"

run_test "dnsmasq process is running" \
    "docker exec clab-dns-fundamentals-dns-server sh -c 'ps aux | grep -v grep | grep dnsmasq'"

run_test "web.lab.local A record configured" \
    "docker exec clab-dns-fundamentals-dns-server grep 'web.lab.local' /etc/dnsmasq.conf"

run_test "db.lab.local A record configured" \
    "docker exec clab-dns-fundamentals-dns-server grep 'db.lab.local' /etc/dnsmasq.conf"

run_test "mail.lab.local A record configured" \
    "docker exec clab-dns-fundamentals-dns-server grep 'mail.lab.local' /etc/dnsmasq.conf"

run_test "PTR record for 10.2.1.10 configured" \
    "docker exec clab-dns-fundamentals-dns-server grep 'ptr-record' /etc/dnsmasq.conf"

echo ""

# Test 4: Client DNS Configuration
echo "4. Client DNS Configuration"
echo "-------------------------------------------"

run_test "Client resolv.conf points to DNS server" \
    "docker exec clab-dns-fundamentals-client grep '10.2.1.1' /etc/resolv.conf"

run_test "Client has default route via DNS server" \
    "docker exec clab-dns-fundamentals-client ip route show | grep 'default via 10.2.1.1'"

echo ""

# Test 5: Forward DNS Lookups
echo "5. Forward DNS Lookups (A Records)"
echo "-------------------------------------------"

run_test "web.lab.local resolves to 10.2.1.10" \
    "docker exec clab-dns-fundamentals-client dig @10.2.1.1 web.lab.local +short | grep '10.2.1.10'"

run_test "db.lab.local resolves to 10.2.1.20" \
    "docker exec clab-dns-fundamentals-client dig @10.2.1.1 db.lab.local +short | grep '10.2.1.20'"

run_test "mail.lab.local resolves to 10.2.1.30" \
    "docker exec clab-dns-fundamentals-client dig @10.2.1.1 mail.lab.local +short | grep '10.2.1.30'"

run_test "nslookup resolves web.lab.local" \
    "docker exec clab-dns-fundamentals-client nslookup web.lab.local 10.2.1.1 | grep '10.2.1.10'"

echo ""

# Test 6: Reverse DNS Lookup
echo "6. Reverse DNS Lookup (PTR Record)"
echo "-------------------------------------------"

run_test "Reverse lookup 10.2.1.10 returns web.lab.local" \
    "docker exec clab-dns-fundamentals-client dig @10.2.1.1 -x 10.2.1.10 +short | grep 'web.lab.local'"

echo ""

# Test 7: NXDOMAIN Response
echo "7. NXDOMAIN (Non-Existent Domain)"
echo "-------------------------------------------"

run_test "Nonexistent domain returns NXDOMAIN status" \
    "docker exec clab-dns-fundamentals-client dig @10.2.1.1 nonexistent.lab.local | grep 'NXDOMAIN'"

run_test "Nonexistent domain returns empty answer section" \
    "docker exec clab-dns-fundamentals-client sh -c 'test -z \"\$(dig @10.2.1.1 nonexistent.lab.local +short)\"'"

echo ""

# Test 8: DNS Query Logging
echo "8. DNS Query Logging"
echo "-------------------------------------------"

# Trigger a query first to ensure log exists
docker exec clab-dns-fundamentals-client dig @10.2.1.1 web.lab.local +short > /dev/null 2>&1

run_test "DNS query log exists on server" \
    "docker exec clab-dns-fundamentals-dns-server test -f /var/log/dnsmasq.log"

run_test "DNS query log has entries" \
    "docker exec clab-dns-fundamentals-dns-server sh -c 'test \$(wc -c < /var/log/dnsmasq.log) -gt 0'"

echo ""

# Test 9: Connectivity
echo "9. Connectivity Tests"
echo "-------------------------------------------"

run_test "Client can ping DNS server" \
    "docker exec clab-dns-fundamentals-client ping -c 2 -W 2 10.2.1.1"

run_test "Client can ping web server by IP" \
    "docker exec clab-dns-fundamentals-client ping -c 2 -W 2 10.2.1.10"

run_test "Web server can ping DNS server" \
    "docker exec clab-dns-fundamentals-web-server ping -c 2 -W 2 10.2.1.1"

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

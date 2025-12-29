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
echo "systemd Service Management Lab Validation"
echo "========================================"
echo ""

echo "Note: systemd requires special container setup."
echo "This lab validates tools are installed for practice."
echo ""

echo "1. Container Status"
echo "-------------------------------------------"
run_test "Server1 running" \
    "docker exec clab-systemd-service-management-server1 ip addr show eth1"
run_test "Server2 running" \
    "docker exec clab-systemd-service-management-server2 ip addr show eth1"

echo ""
echo "2. IP Configuration"
echo "-------------------------------------------"
run_test "Server1 has 192.168.1.10" \
    "docker exec clab-systemd-service-management-server1 ip addr show eth1 | grep '192.168.1.10'"
run_test "Server2 has 192.168.1.20" \
    "docker exec clab-systemd-service-management-server2 ip addr show eth1 | grep '192.168.1.20'"

echo ""
echo "3. Services Installed"
echo "-------------------------------------------"
run_test "Server1 has nginx installed" \
    "docker exec clab-systemd-service-management-server1 which nginx"
run_test "Server2 has apache2 installed" \
    "docker exec clab-systemd-service-management-server2 which apache2"

echo ""
echo "4. systemd Tools Available"
echo "-------------------------------------------"
run_test "Server1 has systemctl" \
    "docker exec clab-systemd-service-management-server1 which systemctl"
run_test "Server1 has journalctl" \
    "docker exec clab-systemd-service-management-server1 which journalctl"

echo ""
echo "5. Connectivity"
echo "-------------------------------------------"
run_test "Server1 can ping server2" \
    "docker exec clab-systemd-service-management-server1 ping -c 2 -W 2 192.168.1.20"
run_test "Server2 can ping server1" \
    "docker exec clab-systemd-service-management-server2 ping -c 2 -W 2 192.168.1.10"

echo ""
echo "========================================"
echo "Validation Summary"
echo "========================================"
echo -e "Tests Passed: ${GREEN}$PASSED${NC}"
echo -e "Tests Failed: ${RED}$FAILED${NC}"
echo ""

if [ $FAILED -eq 0 ]; then
    echo -e "${GREEN}✅ All tests passed!${NC}"
    echo ""
    echo "Note: To practice systemd commands, run manually inside containers."
    echo "Some systemd features require privileged containers."
    exit 0
else
    echo -e "${RED}❌ Some tests failed.${NC}"
    exit 1
fi

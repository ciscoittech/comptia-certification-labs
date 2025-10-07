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
        ((PASSED++))
    else
        echo -e "${RED}❌ FAIL${NC}"
        ((FAILED++))
    fi
}

echo "========================================"
echo "SSH Key Authentication Lab Validation"
echo "========================================"
echo ""

echo "1. Container Status"
echo "-------------------------------------------"
run_test "SSH server running" \
    "docker exec clab-ssh-key-authentication-ssh-server ip addr show eth1"
run_test "SSH client running" \
    "docker exec clab-ssh-key-authentication-ssh-client ip addr show eth1"

echo ""
echo "2. IP Configuration"
echo "-------------------------------------------"
run_test "Server has 192.168.1.10" \
    "docker exec clab-ssh-key-authentication-ssh-server ip addr show eth1 | grep '192.168.1.10'"
run_test "Client has 192.168.1.20" \
    "docker exec clab-ssh-key-authentication-ssh-client ip addr show eth1 | grep '192.168.1.20'"

echo ""
echo "3. SSH Services"
echo "-------------------------------------------"
run_test "SSH daemon running on server" \
    "docker exec clab-ssh-key-authentication-ssh-server sh -c 'ps | grep sshd | grep -v grep'"
run_test "SSH port 22 listening" \
    "docker exec clab-ssh-key-authentication-ssh-server netstat -tuln | grep ':22'"

echo ""
echo "4. SSH Tools Available"
echo "-------------------------------------------"
run_test "Client has ssh-keygen" \
    "docker exec clab-ssh-key-authentication-ssh-client which ssh-keygen"
run_test "Client has ssh" \
    "docker exec clab-ssh-key-authentication-ssh-client which ssh"

echo ""
echo "5. Connectivity"
echo "-------------------------------------------"
run_test "Client can ping server" \
    "docker exec clab-ssh-key-authentication-ssh-client ping -c 2 -W 2 192.168.1.10"

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

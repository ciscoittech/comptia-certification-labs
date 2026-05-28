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
echo "VPN Fundamentals Lab Validation"
echo "========================================"
echo ""

echo "1. Container Status (4 nodes)"
echo "-------------------------------------------"
run_test "site-a-gw running" \
    "docker exec clab-vpn-fundamentals-site-a-gw ip addr show eth1"
run_test "site-b-gw running" \
    "docker exec clab-vpn-fundamentals-site-b-gw ip addr show eth1"
run_test "host-a running" \
    "docker exec clab-vpn-fundamentals-host-a ip addr show eth1"
run_test "host-b running" \
    "docker exec clab-vpn-fundamentals-host-b ip addr show eth1"

echo ""
echo "2. IP Configuration"
echo "-------------------------------------------"
run_test "site-a-gw LAN IP (10.1.1.1)" \
    "docker exec clab-vpn-fundamentals-site-a-gw ip addr show eth1 | grep '10.1.1.1'"
run_test "site-a-gw WAN IP (172.16.0.1)" \
    "docker exec clab-vpn-fundamentals-site-a-gw ip addr show eth2 | grep '172.16.0.1'"
run_test "site-b-gw LAN IP (10.2.2.1)" \
    "docker exec clab-vpn-fundamentals-site-b-gw ip addr show eth1 | grep '10.2.2.1'"
run_test "site-b-gw WAN IP (172.16.0.2)" \
    "docker exec clab-vpn-fundamentals-site-b-gw ip addr show eth2 | grep '172.16.0.2'"
run_test "host-a IP (10.1.1.10)" \
    "docker exec clab-vpn-fundamentals-host-a ip addr show eth1 | grep '10.1.1.10'"
run_test "host-b IP (10.2.2.10)" \
    "docker exec clab-vpn-fundamentals-host-b ip addr show eth1 | grep '10.2.2.10'"

echo ""
echo "3. WireGuard Tools"
echo "-------------------------------------------"
run_test "wg command on site-a-gw" \
    "docker exec clab-vpn-fundamentals-site-a-gw which wg"
run_test "wg-quick command on site-a-gw" \
    "docker exec clab-vpn-fundamentals-site-a-gw which wg-quick"
run_test "wg command on site-b-gw" \
    "docker exec clab-vpn-fundamentals-site-b-gw which wg"

echo ""
echo "4. WAN Underlay Connectivity"
echo "-------------------------------------------"
run_test "site-a-gw can ping site-b-gw over WAN" \
    "docker exec clab-vpn-fundamentals-site-a-gw ping -c 2 -W 3 172.16.0.2"
run_test "host-a can ping site-a-gw (local)" \
    "docker exec clab-vpn-fundamentals-host-a ping -c 2 -W 3 10.1.1.1"
run_test "host-b can ping site-b-gw (local)" \
    "docker exec clab-vpn-fundamentals-host-b ping -c 2 -W 3 10.2.2.1"

echo ""
echo "5. IP Forwarding"
echo "-------------------------------------------"
run_test "IP forwarding enabled on site-a-gw" \
    "docker exec clab-vpn-fundamentals-site-a-gw sysctl net.ipv4.ip_forward | grep '= 1'"
run_test "IP forwarding enabled on site-b-gw" \
    "docker exec clab-vpn-fundamentals-site-b-gw sysctl net.ipv4.ip_forward | grep '= 1'"

echo ""
echo "6. WireGuard Key Generation (run after Exercise 2)"
echo "-------------------------------------------"
run_test "Site A private key exists" \
    "docker exec clab-vpn-fundamentals-site-a-gw test -s /etc/wireguard/privatekey-a"
run_test "Site A public key exists" \
    "docker exec clab-vpn-fundamentals-site-a-gw test -s /etc/wireguard/publickey-a"
run_test "Site B private key exists" \
    "docker exec clab-vpn-fundamentals-site-b-gw test -s /etc/wireguard/privatekey-b"
run_test "Site B public key exists" \
    "docker exec clab-vpn-fundamentals-site-b-gw test -s /etc/wireguard/publickey-b"

echo ""
echo "7. WireGuard Config Files (run after Exercises 3-4)"
echo "-------------------------------------------"
run_test "wg0.conf exists on site-a-gw" \
    "docker exec clab-vpn-fundamentals-site-a-gw test -f /etc/wireguard/wg0.conf"
run_test "wg0.conf contains peer on site-a-gw" \
    "docker exec clab-vpn-fundamentals-site-a-gw grep -q '\[Peer\]' /etc/wireguard/wg0.conf"
run_test "wg0.conf exists on site-b-gw" \
    "docker exec clab-vpn-fundamentals-site-b-gw test -f /etc/wireguard/wg0.conf"
run_test "wg0.conf contains peer on site-b-gw" \
    "docker exec clab-vpn-fundamentals-site-b-gw grep -q '\[Peer\]' /etc/wireguard/wg0.conf"

echo ""
echo "8. WireGuard Tunnel (run after Exercise 5)"
echo "-------------------------------------------"
run_test "wg0 interface exists on site-a-gw" \
    "docker exec clab-vpn-fundamentals-site-a-gw ip link show wg0"
run_test "wg0 interface exists on site-b-gw" \
    "docker exec clab-vpn-fundamentals-site-b-gw ip link show wg0"
run_test "wg0 has tunnel IP on site-a-gw (10.99.0.1)" \
    "docker exec clab-vpn-fundamentals-site-a-gw ip addr show wg0 | grep '10.99.0.1'"
run_test "wg0 has tunnel IP on site-b-gw (10.99.0.2)" \
    "docker exec clab-vpn-fundamentals-site-b-gw ip addr show wg0 | grep '10.99.0.2'"

echo ""
echo "9. WireGuard Handshake (run after Exercise 5)"
echo "-------------------------------------------"
run_test "WireGuard handshake completed on site-a-gw" \
    "docker exec clab-vpn-fundamentals-site-a-gw wg show wg0 | grep -i 'latest handshake'"
run_test "WireGuard shows peer on site-b-gw" \
    "docker exec clab-vpn-fundamentals-site-b-gw wg show wg0 | grep -i 'peer'"

echo ""
echo "10. End-to-End VPN Connectivity (run after Exercise 6)"
echo "-------------------------------------------"
run_test "host-a pings host-b through tunnel" \
    "docker exec clab-vpn-fundamentals-host-a ping -c 3 -W 5 10.2.2.10"
run_test "Tunnel gateway-to-gateway (10.99.0.1 to 10.99.0.2)" \
    "docker exec clab-vpn-fundamentals-site-a-gw ping -c 3 -W 5 10.99.0.2"

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
    echo -e "${RED}❌ Some tests failed. Tests in sections 6-10 require completing the exercises first.${NC}"
    exit 1
fi

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
echo "IDS/IPS Fundamentals Lab Validation"
echo "========================================"
echo ""

echo "1. Container Status (3 nodes)"
echo "-------------------------------------------"
run_test "sensor running" \
    "docker exec clab-ids-ips-fundamentals-sensor ip addr show eth1"
run_test "web-server running" \
    "docker exec clab-ids-ips-fundamentals-web-server ip addr show eth1"
run_test "attacker running" \
    "docker exec clab-ids-ips-fundamentals-attacker ip addr show eth1"

echo ""
echo "2. IP Configuration"
echo "-------------------------------------------"
run_test "sensor eth1 (10.3.1.1)" \
    "docker exec clab-ids-ips-fundamentals-sensor ip addr show eth1 | grep '10.3.1.1'"
run_test "sensor eth2 (10.3.2.1)" \
    "docker exec clab-ids-ips-fundamentals-sensor ip addr show eth2 | grep '10.3.2.1'"
run_test "web-server IP (10.3.2.10)" \
    "docker exec clab-ids-ips-fundamentals-web-server ip addr show eth1 | grep '10.3.2.10'"
run_test "attacker IP (10.3.1.10)" \
    "docker exec clab-ids-ips-fundamentals-attacker ip addr show eth1 | grep '10.3.1.10'"

echo ""
echo "3. Sensor Configuration"
echo "-------------------------------------------"
run_test "IP forwarding enabled on sensor" \
    "docker exec clab-ids-ips-fundamentals-sensor sysctl net.ipv4.ip_forward | grep '= 1'"
run_test "Log directory exists on sensor" \
    "docker exec clab-ids-ips-fundamentals-sensor test -d /var/log/ids"
run_test "Rules directory exists on sensor" \
    "docker exec clab-ids-ips-fundamentals-sensor test -d /etc/ids/rules"

echo ""
echo "4. Web Server"
echo "-------------------------------------------"
run_test "nginx running on web-server" \
    "docker exec clab-ids-ips-fundamentals-web-server sh -c 'ps | grep nginx | grep -v grep'"
run_test "Web server responds to HTTP" \
    "docker exec clab-ids-ips-fundamentals-attacker curl -s --max-time 5 http://10.3.2.10 | grep -i 'secure'"

echo ""
echo "5. Connectivity Through Sensor"
echo "-------------------------------------------"
run_test "Attacker can ping sensor (eth1)" \
    "docker exec clab-ids-ips-fundamentals-attacker ping -c 2 -W 3 10.3.1.1"
run_test "Attacker can reach web-server through sensor" \
    "docker exec clab-ids-ips-fundamentals-attacker ping -c 2 -W 3 10.3.2.10"
run_test "Web-server can ping sensor (eth2)" \
    "docker exec clab-ids-ips-fundamentals-web-server ping -c 2 -W 3 10.3.2.1"

echo ""
echo "6. Detection Tools"
echo "-------------------------------------------"
run_test "tcpdump available on sensor" \
    "docker exec clab-ids-ips-fundamentals-sensor which tcpdump"
run_test "python3 available on sensor" \
    "docker exec clab-ids-ips-fundamentals-sensor which python3"
run_test "nmap available on attacker" \
    "docker exec clab-ids-ips-fundamentals-attacker which nmap"
run_test "curl available on attacker" \
    "docker exec clab-ids-ips-fundamentals-attacker which curl"

echo ""
echo "7. Packet Capture (run after Exercise 2-4)"
echo "-------------------------------------------"
run_test "Capture file exists on sensor" \
    "docker exec clab-ids-ips-fundamentals-sensor test -f /var/log/ids/capture.pcap"
run_test "Capture file is non-empty" \
    "docker exec clab-ids-ips-fundamentals-sensor test -s /var/log/ids/capture.pcap"
run_test "tcpdump can read capture file" \
    "docker exec clab-ids-ips-fundamentals-sensor tcpdump -r /var/log/ids/capture.pcap -c 1 -q"

echo ""
echo "8. Nmap Scan Evidence (run after Exercise 4)"
echo "-------------------------------------------"
run_test "Capture contains TCP SYN packets" \
    "docker exec clab-ids-ips-fundamentals-sensor tcpdump -r /var/log/ids/capture.pcap -n 'tcp[tcpflags] & tcp-syn != 0' -c 1 -q"
run_test "Capture has traffic from attacker IP" \
    "docker exec clab-ids-ips-fundamentals-sensor tcpdump -r /var/log/ids/capture.pcap -n src 10.3.1.10 -c 1 -q"

echo ""
echo "9. Detection Script (run after Exercise 6)"
echo "-------------------------------------------"
run_test "Detection script exists on sensor" \
    "docker exec clab-ids-ips-fundamentals-sensor test -f /etc/ids/rules/portscan_detect.py"
run_test "Detection script is valid Python" \
    "docker exec clab-ids-ips-fundamentals-sensor python3 -m py_compile /etc/ids/rules/portscan_detect.py"
run_test "Detection script runs without error" \
    "docker exec clab-ids-ips-fundamentals-sensor python3 /etc/ids/rules/portscan_detect.py /var/log/ids/capture.pcap"

echo ""
echo "10. Detection Script Finds the Scan (run after Exercise 7)"
echo "-------------------------------------------"
run_test "Detection script alerts on port scan" \
    "docker exec clab-ids-ips-fundamentals-sensor python3 /etc/ids/rules/portscan_detect.py /var/log/ids/capture.pcap | grep -i 'ALERT\|detected'"

echo ""
echo "11. IPS Blocking Capability (run after Exercise 8)"
echo "-------------------------------------------"
run_test "iptables available on sensor" \
    "docker exec clab-ids-ips-fundamentals-sensor which iptables"
run_test "Sensor FORWARD chain accessible" \
    "docker exec clab-ids-ips-fundamentals-sensor iptables -L FORWARD -n"

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
    echo -e "${RED}❌ Some tests failed. Tests in sections 7-10 require completing the exercises first.${NC}"
    exit 1
fi

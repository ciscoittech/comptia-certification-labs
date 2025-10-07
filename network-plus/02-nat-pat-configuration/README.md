# NAT/PAT Configuration Lab

## 🎯 Learning Objectives

Master Network Address Translation (NAT) and Port Address Translation (PAT) - essential technologies for IPv4 address conservation and network security.

**CompTIA Network+ N10-009 Coverage:**
- ✅ Domain 2: Network Implementation (20% of exam)
  - NAT/PAT concepts and configuration
  - Private vs. public IP addressing
  - Address translation troubleshooting
  - Packet flow through NAT devices

**What You'll Learn:**
1. Configure NAT/PAT using iptables MASQUERADE
2. Understand the difference between NAT and PAT
3. Verify address translation with packet captures
4. Troubleshoot NAT connectivity issues
5. Observe NAT translation tables in real-time

**Lab Duration:** 25 minutes

**Difficulty:** Beginner

---

## 📋 Prerequisites

- Understanding of private IP address ranges (RFC 1918)
- Basic knowledge of public vs. private IP addressing
- Familiarity with iptables concepts
- Docker and Containerlab installed (or use GitHub Codespaces)

---

## 🏗️ Topology Overview

```
Internal Network          Router (NAT)          External Network
(Private IPs)                                   (Public IPs)

10.1.1.10/24  ------>  [Router] ------->  203.0.113.10/24
(Client)           10.1.1.1  203.0.113.1    (External Server)
                    eth1        eth2
```

**Network Design:**
- **Internal Network:** 10.1.1.0/24 (Private - RFC 1918)
- **External Network:** 203.0.113.0/24 (Simulated Public - RFC 5737 TEST-NET-3)
- **Router:** Performs NAT/PAT between networks
- **Translation:** 10.1.1.10 → 203.0.113.1 (using PAT)

---

## 🚀 Quick Start

### Deploy the Lab

```bash
cd network-plus/02-nat-pat-configuration
containerlab deploy -t topology.clab.yml
```

Wait 15 seconds for containers to initialize (HTTP server startup).

### Verify Deployment

```bash
containerlab inspect -t topology.clab.yml
```

You should see 3 containers: router, internal-client, external-server

---

## 🔬 Lab Exercises

### Exercise 1: Verify Network Configuration

**Check internal client configuration:**

```bash
docker exec -it clab-nat-pat-configuration-internal-client sh

# Show IP address (should be 10.1.1.10)
ip addr show eth1

# Check default route (should point to 10.1.1.1)
ip route show

# Test connectivity to router
ping -c 2 10.1.1.1

# Exit
exit
```

**Check external server:**

```bash
docker exec -it clab-nat-pat-configuration-external-server sh

# Show IP address (should be 203.0.113.10)
ip addr show eth1

# Verify HTTP server is running
netstat -tuln | grep :80 || ps | grep http.server

# Exit
exit
```

**Key Concepts:**
- Private IP ranges: 10.0.0.0/8, 172.16.0.0/12, 192.168.0.0/16
- Public IP ranges: Everything else (except reserved ranges)
- RFC 5737: Test address ranges (192.0.2.0/24, 198.51.100.0/24, 203.0.113.0/24)

---

### Exercise 2: Test Connectivity Through NAT

**From internal client, access external server:**

```bash
# Test ping (ICMP through NAT)
docker exec clab-nat-pat-configuration-internal-client ping -c 4 203.0.113.10

# Test HTTP (TCP through NAT with PAT)
docker exec clab-nat-pat-configuration-internal-client curl -s http://203.0.113.10
```

**Expected Results:**
- ✅ Ping succeeds (internal client can reach external server)
- ✅ HTTP request succeeds (shows directory listing from Python HTTP server)
- 🔍 Internal IP (10.1.1.10) is translated to router's external IP (203.0.113.1)

**Key Concept:**
- **NAT (Network Address Translation):** Translates IP addresses
- **PAT (Port Address Translation):** Also called NAT overload - translates IP + port combinations
- **MASQUERADE:** Dynamic PAT where external IP may change (typical for home routers)

---

### Exercise 3: Examine NAT Translation Table

**View active NAT connections:**

```bash
docker exec clab-nat-pat-configuration-router sh

# Show NAT connection tracking table
conntrack -L 2>/dev/null || cat /proc/net/nf_conntrack | head -20

# Alternative: Use iptables to show NAT statistics
iptables -t nat -L POSTROUTING -v -n

# Exit
exit
```

**While viewing connections, generate traffic:**

```bash
# In another terminal, generate HTTP request
docker exec clab-nat-pat-configuration-internal-client curl http://203.0.113.10

# Check the NAT table again (shows the translation)
docker exec clab-nat-pat-configuration-router cat /proc/net/nf_conntrack | grep 203.0.113.10
```

**Understanding the Output:**
```
tcp      6 117 ESTABLISHED src=10.1.1.10 dst=203.0.113.10 sport=45678 dport=80
                          src=203.0.113.10 dst=203.0.113.1 sport=80 dport=45678
```

**Translation Breakdown:**
- **Original:** 10.1.1.10:45678 → 203.0.113.10:80
- **Translated:** 203.0.113.1:45678 → 203.0.113.10:80
- **Return Path:** 203.0.113.10:80 → 203.0.113.1:45678 (then de-NATed back to 10.1.1.10:45678)

---

### Exercise 4: Packet Capture - See NAT in Action

**Capture packets on router's external interface:**

```bash
# Start packet capture on external interface (eth2)
docker exec -d clab-nat-pat-configuration-router \
    tcpdump -i eth2 -n 'host 203.0.113.10' -w /tmp/nat-capture.pcap

# Wait 2 seconds
sleep 2

# Generate traffic from internal client
docker exec clab-nat-pat-configuration-internal-client ping -c 3 203.0.113.10

# Wait for capture
sleep 2

# Stop tcpdump (kill process)
docker exec clab-nat-pat-configuration-router pkill tcpdump

# View captured packets
docker exec clab-nat-pat-configuration-router tcpdump -r /tmp/nat-capture.pcap -n
```

**Expected Output:**
```
15:30:45.123456 IP 203.0.113.1 > 203.0.113.10: ICMP echo request
15:30:45.124567 IP 203.0.113.10 > 203.0.113.1: ICMP echo reply
```

**Key Observation:**
- ❌ You will NOT see 10.1.1.10 in the external capture
- ✅ You WILL see 203.0.113.1 (router's external IP)
- 🔍 This proves NAT is translating the source IP address

---

### Exercise 5: Compare Internal vs. External Packet Capture

**Capture on BOTH interfaces simultaneously:**

```bash
# Capture internal interface (eth1) - should see 10.1.1.10
docker exec -d clab-nat-pat-configuration-router \
    tcpdump -i eth1 -n -c 5 'icmp' > /tmp/internal.txt 2>&1

# Capture external interface (eth2) - should see 203.0.113.1
docker exec -d clab-nat-pat-configuration-router \
    tcpdump -i eth2 -n -c 5 'icmp' > /tmp/external.txt 2>&1

# Wait 2 seconds for tcpdump to start
sleep 2

# Generate ICMP traffic
docker exec clab-nat-pat-configuration-internal-client ping -c 3 203.0.113.10

# Wait for captures to complete
sleep 3

# Compare the two captures
echo "=== INTERNAL INTERFACE (eth1) - Before NAT ==="
docker exec clab-nat-pat-configuration-router cat /tmp/internal.txt | grep ICMP

echo ""
echo "=== EXTERNAL INTERFACE (eth2) - After NAT ==="
docker exec clab-nat-pat-configuration-router cat /tmp/external.txt | grep ICMP
```

**Expected Results:**
```
INTERNAL: 10.1.1.10 > 203.0.113.10 (original source IP)
EXTERNAL: 203.0.113.1 > 203.0.113.10 (translated source IP)
```

**This demonstrates NAT happens BETWEEN the two interfaces!**

---

### Exercise 6: Examine iptables NAT Rules

**View NAT configuration:**

```bash
docker exec clab-nat-pat-configuration-router sh

# Show NAT table rules
iptables -t nat -L -v -n

# Show FORWARD chain rules (allow traffic through router)
iptables -L FORWARD -v -n

# Exit
exit
```

**Expected NAT Rules:**
```
Chain POSTROUTING (policy ACCEPT)
target     prot opt source               destination
MASQUERADE  all  --  0.0.0.0/0            0.0.0.0/0
```

**Key Concepts:**
- **POSTROUTING:** NAT happens AFTER routing decision (on outbound)
- **MASQUERADE:** Automatically uses the outbound interface's IP address
- **FORWARD chain:** Controls traffic passing THROUGH the router (not TO the router)

---

### Exercise 7: Break and Fix NAT

**Remove NAT rule and observe failure:**

```bash
# Remove MASQUERADE rule
docker exec clab-nat-pat-configuration-router iptables -t nat -F POSTROUTING

# Try to ping from internal client (should FAIL)
docker exec clab-nat-pat-configuration-internal-client ping -c 2 203.0.113.10

# Expected: No response (external server sees 10.1.1.10 but doesn't have route back)
```

**Why does it fail?**
- External server receives packet from 10.1.1.10 (private IP)
- External server tries to reply to 10.1.1.10
- External server has no route to 10.1.1.0/24 (private network)
- Reply packets are dropped

**Re-add NAT and fix connectivity:**

```bash
# Restore MASQUERADE rule
docker exec clab-nat-pat-configuration-router \
    iptables -t nat -A POSTROUTING -o eth2 -j MASQUERADE

# Test connectivity (should work now)
docker exec clab-nat-pat-configuration-internal-client ping -c 2 203.0.113.10
```

**Expected:** Success! NAT is working again.

---

## 🧪 Validation Tests

Run the automated validation script:

```bash
cd scripts
./validate.sh
```

**Expected Results (20 tests):**
- ✅ All 3 containers running
- ✅ IP addresses correctly configured
- ✅ IP forwarding enabled on router
- ✅ NAT rules present in iptables
- ✅ Internal client can ping router
- ✅ Internal client can ping external server through NAT
- ✅ HTTP connectivity through NAT works
- ✅ NAT translation table shows active connections

---

## 📚 Key Concepts Review

### NAT vs. PAT

**NAT (Network Address Translation):**
- Translates IP addresses only
- 1:1 mapping (one private IP → one public IP)
- Example: Static NAT for servers

**PAT (Port Address Translation):**
- Translates IP address + port number
- Many:1 mapping (many private IPs → one public IP)
- Also called "NAT Overload" or "NAPT"
- What home routers and this lab use

### Types of NAT

1. **Static NAT:** Fixed mapping (10.1.1.5 always becomes 203.0.113.5)
2. **Dynamic NAT:** Pool of public IPs, assigned dynamically
3. **PAT/NAPT:** Multiple devices share one public IP (most common)

### MASQUERADE vs. SNAT

**MASQUERADE:**
- Automatically uses outbound interface's IP
- Good for dynamic IPs (DHCP, PPPoE)
- Slightly slower (checks IP every packet)
- Used in this lab

**SNAT (Source NAT):**
- Hardcoded to specific IP address
- Good for static public IPs
- Slightly faster
- Example: `iptables -t nat -A POSTROUTING -o eth2 -j SNAT --to-source 203.0.113.1`

### Private IP Ranges (RFC 1918)

- **Class A:** 10.0.0.0/8 (10.0.0.0 - 10.255.255.255)
- **Class B:** 172.16.0.0/12 (172.16.0.0 - 172.31.255.255)
- **Class C:** 192.168.0.0/16 (192.168.0.0 - 192.168.255.255)

These IPs are NOT routed on the public internet - NAT is required!

---

## 🔧 Troubleshooting

### Issue: Internal client cannot reach external server

**Step 1: Verify IP forwarding is enabled**
```bash
docker exec clab-nat-pat-configuration-router sysctl net.ipv4.ip_forward
# Expected: net.ipv4.ip_forward = 1
```

**Step 2: Check NAT rules exist**
```bash
docker exec clab-nat-pat-configuration-router iptables -t nat -L POSTROUTING -n
# Expected: MASQUERADE rule present
```

**Step 3: Check FORWARD chain allows traffic**
```bash
docker exec clab-nat-pat-configuration-router iptables -L FORWARD -n
# Expected: ACCEPT rules for both directions
```

**Step 4: Test connectivity to router first**
```bash
docker exec clab-nat-pat-configuration-internal-client ping 10.1.1.1
```

### Issue: Ping works but HTTP doesn't

**Check external server HTTP service:**
```bash
docker exec clab-nat-pat-configuration-external-server netstat -tuln | grep :80
```

**If not running, restart HTTP server:**
```bash
docker exec -d clab-nat-pat-configuration-external-server \
    python3 -m http.server 80
```

### Issue: Cannot see NAT translations

**Install conntrack tools:**
```bash
docker exec clab-nat-pat-configuration-router apk add conntrack-tools
docker exec clab-nat-pat-configuration-router conntrack -L
```

### Issue: Packets dropped by iptables

**Check iptables counters:**
```bash
docker exec clab-nat-pat-configuration-router iptables -L -v -n
docker exec clab-nat-pat-configuration-router iptables -t nat -L -v -n
```

Look for non-zero packet counts on DROP rules.

---

## 🧹 Cleanup

```bash
containerlab destroy -t topology.clab.yml --cleanup
```

---

## 📖 Additional Resources

**Network+ N10-009 Exam Resources:**
- CompTIA Network+ Objectives (Domain 2: NAT/PAT)
- RFC 1918: Address Allocation for Private Internets
- RFC 3022: Traditional IP Network Address Translator (NAT)

**Practice Questions:**
1. What is the primary purpose of NAT/PAT?
2. How does PAT differ from traditional NAT?
3. What are the three RFC 1918 private IP address ranges?
4. Why is MASQUERADE slower than SNAT?
5. What iptables table and chain is used for NAT?

**Hands-On Challenges:**
- Configure static NAT (1:1 mapping) instead of PAT
- Add a second internal client and observe PAT translations
- Configure port forwarding (DNAT) to allow external access to internal server
- Set up NAT loopback (hairpin NAT) for internal clients accessing public IP
- Implement NAT with connection limits using iptables connlimit module

---

## 📝 Lab Notes

**What Makes This Lab Special:**
- Uses **real iptables NAT** (not simulated)
- Demonstrates **actual packet translation** with tcpdump
- Shows **connection tracking** in real-time
- **Zero hardware required** - runs in containers

**Real-World Applications:**
- Home and office routers (SOHO devices)
- Enterprise edge routers (IPv4 address conservation)
- Cloud VPCs (AWS NAT Gateway, Azure NAT)
- Kubernetes egress traffic (kube-proxy NAT)

**Common Misconceptions:**
- ❌ "NAT provides security" - It provides obscurity, not security
- ❌ "All routers do NAT" - Only edge routers between private/public networks
- ❌ "NAT and PAT are the same" - PAT is a type of NAT that includes ports
- ❌ "Private IPs never leave the network" - They do, but are translated at the boundary

---

**Lab Version:** 1.0
**Last Updated:** 2025-10-07
**Estimated Completion Time:** 25 minutes
**Difficulty:** Beginner

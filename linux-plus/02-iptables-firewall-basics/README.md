# iptables Firewall Basics Lab

## 🎯 Learning Objectives

Master Linux firewall configuration using iptables - essential for securing Linux systems and networks.

**CompTIA Linux+ XK0-005 Coverage:**
- ✅ Domain 2: Security (21% of exam)
  - Configure iptables firewall rules
  - Understand chains, tables, and policies
  - Implement stateful packet filtering
  - Troubleshoot firewall rules

**What You'll Learn:**
1. Configure iptables rules for packet filtering
2. Understand INPUT, FORWARD, and OUTPUT chains
3. Implement stateful firewall rules (ESTABLISHED, RELATED)
4. Allow specific services (HTTP) while blocking others
5. Troubleshoot firewall connectivity issues

**Lab Duration:** 30 minutes
**Difficulty:** Intermediate

---

## 🏗️ Topology Overview

```
Client (10.1.1.10) --- [Firewall] --- Webserver (10.2.2.10)
                    10.1.1.1  10.2.2.1        (nginx)
```

**Network Design:**
- **Client Network:** 10.1.1.0/24 (untrusted)
- **Server Network:** 10.2.2.0/24 (protected)
- **Firewall:** Routes and filters traffic between networks
- **Rules:** Allow HTTP (80), block other ports

---

## 🚀 Quick Start

```bash
cd linux-plus/02-iptables-firewall-basics
containerlab deploy -t topology.clab.yml
```

Wait 15 seconds for containers and nginx to initialize.

---

## 🔬 Lab Exercises

### Exercise 1: Verify Firewall Rules

```bash
docker exec clab-iptables-firewall-basics-firewall iptables -L -v -n
```

**Key Concepts:**
- **-L:** List rules
- **-v:** Verbose (show packet/byte counts)
- **-n:** Numeric (don't resolve hostnames)

### Exercise 2: Test Allowed Traffic (HTTP)

```bash
# Test HTTP (should work)
docker exec clab-iptables-firewall-basics-client curl http://10.2.2.10

# Test ping (should work)
docker exec clab-iptables-firewall-basics-client ping -c 2 10.2.2.10
```

**Expected:** Both succeed!

### Exercise 3: Test Blocked Traffic (SSH)

```bash
# Try to connect to SSH port 22 (should timeout/fail)
docker exec clab-iptables-firewall-basics-client sh -c 'timeout 3 telnet 10.2.2.10 22 || echo "Blocked by firewall"'
```

**Expected:** Connection blocked!

### Exercise 4: View iptables Tables

```bash
# View filter table (default)
docker exec clab-iptables-firewall-basics-firewall iptables -t filter -L -v -n

# View NAT table
docker exec clab-iptables-firewall-basics-firewall iptables -t nat -L -v -n

# View mangle table
docker exec clab-iptables-firewall-basics-firewall iptables -t mangle -L -v -n
```

### Exercise 5: Add Rule to Allow SSH

```bash
docker exec clab-iptables-firewall-basics-firewall sh

# Add rule to allow SSH (port 22)
iptables -I FORWARD -i eth1 -o eth2 -p tcp --dport 22 -j ACCEPT

# Verify rule added (should be at top)
iptables -L FORWARD -v -n --line-numbers

exit
```

### Exercise 6: Delete Firewall Rule

```bash
docker exec clab-iptables-firewall-basics-firewall sh

# List rules with line numbers
iptables -L FORWARD -n --line-numbers

# Delete rule #1 (SSH rule we just added)
iptables -D FORWARD 1

# Verify rule deleted
iptables -L FORWARD -n --line-numbers

exit
```

### Exercise 7: Block ICMP (Ping)

```bash
# Remove allow-icmp rule
docker exec clab-iptables-firewall-basics-firewall \
    iptables -D FORWARD -i eth1 -o eth2 -p icmp -j ACCEPT

# Test ping (should FAIL now)
docker exec clab-iptables-firewall-basics-client ping -c 2 10.2.2.10

# Re-add allow-icmp rule
docker exec clab-iptables-firewall-basics-firewall \
    iptables -A FORWARD -i eth1 -o eth2 -p icmp -j ACCEPT

# Test ping (should work again)
docker exec clab-iptables-firewall-basics-client ping -c 2 10.2.2.10
```

### Exercise 8: Save and Restore Rules

```bash
# Save current rules to file
docker exec clab-iptables-firewall-basics-firewall iptables-save > /tmp/firewall-rules.txt

# View saved rules
cat /tmp/firewall-rules.txt

# Restore rules (example)
# iptables-restore < /tmp/firewall-rules.txt
```

### Exercise 9: Use nmap to Scan Webserver

```bash
# Scan webserver from client
docker exec clab-iptables-firewall-basics-client nmap -p 1-100 10.2.2.10

# Expected: Only port 80 open (HTTP)
```

### Exercise 10: Monitor Firewall in Real-Time

```bash
# Watch packet counters in real-time
docker exec clab-iptables-firewall-basics-firewall sh -c 'watch -n 1 "iptables -L FORWARD -v -n"'

# In another terminal, generate traffic
docker exec clab-iptables-firewall-basics-client curl http://10.2.2.10
```

---

## 🧪 Validation Tests

```bash
cd scripts
./validate.sh
```

**Expected Results (20 tests):**
- ✅ All containers running
- ✅ Firewall has IP forwarding enabled
- ✅ Firewall FORWARD policy is DROP
- ✅ HTTP traffic allowed (port 80)
- ✅ Established/related connections allowed
- ✅ Client can access webserver HTTP
- ✅ Nginx running on webserver

---

## 📚 Key Concepts Review

### iptables Chains

- **INPUT:** Packets destined TO the firewall itself
- **OUTPUT:** Packets originating FROM the firewall
- **FORWARD:** Packets passing THROUGH the firewall (router)
- **PREROUTING:** Before routing decision (NAT)
- **POSTROUTING:** After routing decision (NAT)

### iptables Tables

- **filter:** Default table (INPUT, FORWARD, OUTPUT chains)
- **nat:** Network Address Translation
- **mangle:** Packet alteration (TOS, TTL, etc.)
- **raw:** Connection tracking exemptions

### Common Targets

- **ACCEPT:** Allow packet
- **DROP:** Silently drop packet
- **REJECT:** Drop and send ICMP error
- **LOG:** Log packet and continue
- **MASQUERADE:** Dynamic NAT (PAT)

### Stateful Firewall

```bash
-m state --state ESTABLISHED,RELATED -j ACCEPT
```

- **ESTABLISHED:** Part of existing connection
- **RELATED:** Related to existing connection (FTP data, ICMP errors)
- **NEW:** First packet of new connection
- **INVALID:** Malformed or untrackable packet

---

## 🔧 Troubleshooting

### Issue: Client cannot reach webserver

**Step 1: Check IP forwarding**
```bash
docker exec clab-iptables-firewall-basics-firewall sysctl net.ipv4.ip_forward
```

**Step 2: Check FORWARD chain policy**
```bash
docker exec clab-iptables-firewall-basics-firewall iptables -L FORWARD -n
```

**Step 3: Check rule order (first match wins)**
```bash
docker exec clab-iptables-firewall-basics-firewall iptables -L FORWARD -n --line-numbers
```

**Step 4: Check packet counters**
```bash
docker exec clab-iptables-firewall-basics-firewall iptables -L FORWARD -v -n
```

### Common Mistakes

1. **Wrong chain:** Use FORWARD for router, not INPUT/OUTPUT
2. **Wrong order:** Rules are processed top-to-bottom
3. **No return traffic:** Forgot ESTABLISHED,RELATED rule
4. **IP forwarding disabled:** Must enable for routing

---

## 🧹 Cleanup

```bash
containerlab destroy -t topology.clab.yml --cleanup
```

---

**Lab Version:** 1.0  
**Last Updated:** 2025-10-07  
**Estimated Completion Time:** 30 minutes  
**Difficulty:** Intermediate

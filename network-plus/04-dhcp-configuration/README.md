# DHCP Configuration Lab

## 🎯 Learning Objectives

Master DHCP configuration and the DORA process — a core Network+ topic tested on every exam sitting.

**CompTIA Network+ N10-009 Coverage:**
- ✅ Domain 2: Network Implementation (20% of exam)
  - 2.2 — DHCP concepts and configuration
  - DORA process (Discover, Offer, Request, Acknowledge)
  - DHCP pools, reservations, and lease management
  - DHCP options (default gateway, DNS server)

**What You'll Learn:**
1. Understand the DHCP DORA process step by step
2. Configure a DHCP server with an IP address pool
3. Create DHCP reservations for specific MAC addresses
4. Verify DHCP options (gateway, DNS) delivered to clients
5. Inspect lease files and understand lease expiration
6. Troubleshoot common DHCP failure scenarios

**Lab Duration:** 30 minutes

**Difficulty:** Intermediate

---

## 📋 Prerequisites

- Basic understanding of IP addressing and subnetting
- Familiarity with MAC addresses
- Docker and Containerlab installed (or use GitHub Codespaces)

---

## 🏗️ Topology Overview

```
                    [DHCP Server]
                    10.1.1.1/24
                   /      |      \
          eth1   /   eth2 |   eth3 \
                /         |         \
        [client1]    [client2]    [client3]
       DHCP pool     DHCP pool    DHCP pool
     10.1.1.100-200 10.1.1.100-200 10.1.1.100-200
```

**Network Topology:**
- **1 DHCP Server:** dnsmasq running on 10.1.1.1
- **3 Clients:** client1, client2, client3 — all obtain IPs via DHCP
- **DHCP Pool:** 10.1.1.100 – 10.1.1.200 (101 addresses)
- **Reservation:** 10.1.1.50 for MAC AA:BB:CC:DD:EE:01
- **DHCP Options:** Router = 10.1.1.1, DNS = 8.8.8.8

---

## 🚀 Quick Start

### Deploy the Lab

```bash
cd network-plus/04-dhcp-configuration
containerlab deploy -t topology.clab.yml
```

Wait 15-20 seconds for containers to initialize and DHCP exchanges to complete.

### Verify Deployment

```bash
containerlab inspect -t topology.clab.yml
```

You should see 4 containers: dhcp-server, client1, client2, client3

---

## 🔬 Lab Exercises

### Exercise 1: Verify the DHCP Server

**Check the DHCP server is running and listening:**

```bash
docker exec -it clab-dhcp-configuration-dhcp-server sh

# Check dnsmasq is running
ps aux | grep dnsmasq

# Verify dnsmasq configuration
cat /etc/dnsmasq.conf

# Check the server's IP address on eth1
ip addr show eth1

# Exit
exit
```

**Key Concepts:**
- dnsmasq is a lightweight DHCP and DNS server
- `dhcp-range` defines the pool start, end, netmask, and lease time
- `dhcp-option=option:router` sets the default gateway sent to clients
- `dhcp-option=option:dns-server` sets the DNS server sent to clients

---

### Exercise 2: Trigger a DHCP Request on a Client

**Watch the DHCP DORA process live:**

```bash
docker exec -it clab-dhcp-configuration-client1 sh

# Release any existing lease and request a new one
udhcpc -i eth1 -v

# Expected output shows the DORA steps:
# sending discover
# sending request
# lease of 10.1.1.1xx obtained

# Check the assigned IP
ip addr show eth1

# Exit
exit
```

**The DORA Process:**
1. **Discover** — Client broadcasts "I need an IP address"
2. **Offer** — Server responds "I can give you 10.1.1.1xx"
3. **Request** — Client broadcasts "I accept 10.1.1.1xx from this server"
4. **Acknowledge** — Server confirms "10.1.1.1xx is yours for 12 hours"

**View the DORA exchange from the server side:**
```bash
docker exec clab-dhcp-configuration-dhcp-server cat /var/log/dnsmasq.log
```

---

### Exercise 3: View the DHCP Lease File

**Inspect active leases on the server:**

```bash
docker exec -it clab-dhcp-configuration-dhcp-server sh

# List the lease database
cat /var/lib/misc/dnsmasq.leases

# Output format: <expiry epoch> <MAC> <IP> <hostname> <client-id>
# Example:
# 1720000000 aa:bb:cc:dd:ee:02 10.1.1.101 client1 *

exit
```

**Key Fields in the Lease File:**
- **Expiry time** — Unix timestamp when the lease expires
- **MAC address** — Client hardware address (unique identifier)
- **Assigned IP** — The IP address given to this client
- **Hostname** — Client-reported hostname (if provided)

---

### Exercise 4: Verify DHCP Options Delivered to Clients

**Check that clients received the correct gateway and DNS:**

```bash
# Check default route (gateway option) on client1
docker exec clab-dhcp-configuration-client1 ip route show

# Expected:
# default via 10.1.1.1 dev eth1   ← gateway from DHCP option

# Check DNS configuration
docker exec clab-dhcp-configuration-client1 cat /etc/resolv.conf

# Expected:
# nameserver 8.8.8.8   ← DNS from DHCP option
```

**Verify all three clients received gateway:**
```bash
docker exec clab-dhcp-configuration-client1 ip route show | grep default
docker exec clab-dhcp-configuration-client2 ip route show | grep default
docker exec clab-dhcp-configuration-client3 ip route show | grep default
```

**Why DHCP Options Matter:**
- Without a gateway option, clients cannot reach other networks
- Without a DNS option, clients cannot resolve hostnames
- DHCP eliminates the need to manually configure these on every device

---

### Exercise 5: Understand DHCP Reservations

**A DHCP reservation assigns a fixed IP to a specific MAC address:**

```bash
# Check the reservation in the server config
docker exec clab-dhcp-configuration-dhcp-server grep "dhcp-host" /etc/dnsmasq.conf

# Output:
# dhcp-host=AA:BB:CC:DD:EE:01,10.1.1.50,reserved-host

# This means any client with MAC AA:BB:CC:DD:EE:01
# will ALWAYS receive 10.1.1.50 — even after lease expiry
```

**Simulate a reservation request:**
```bash
docker exec -it clab-dhcp-configuration-client1 sh

# Request DHCP with a spoofed client-id matching the reservation MAC
# (In real networks, the NIC hardware MAC triggers the reservation)
udhcpc -i eth1 -C -x hostname:reserved-host -v

exit
```

**Reservation vs. Static IP:**
- Reservation: IP assigned by DHCP, but always the same for this MAC
- Static IP: Manually configured on the device, no DHCP involved
- Reservations are easier to manage centrally (all in one DHCP config)

---

### Exercise 6: Check Pool Utilization

**See how many IPs are in use from the pool:**

```bash
docker exec clab-dhcp-configuration-dhcp-server sh

# Count active leases
wc -l < /var/lib/misc/dnsmasq.leases

# Show all active leases
cat /var/lib/misc/dnsmasq.leases

# Pool has 101 addresses (10.1.1.100 to 10.1.1.200)
# Currently 3 clients are using addresses from the pool
echo "Pool: 10.1.1.100-200 (101 addresses)"
echo "Active leases: $(wc -l < /var/lib/misc/dnsmasq.leases)"

exit
```

**Pool Exhaustion Scenario:**
If all 101 addresses are in use:
1. New DHCP Discover is broadcast
2. Server has no available addresses
3. Server does NOT send an Offer
4. Client falls back to APIPA (169.254.x.x) after timeout
5. Result: Client cannot communicate on the network

---

### Exercise 7: Connectivity Between DHCP Clients

**Verify clients can communicate using their dynamically assigned IPs:**

```bash
# Get IP of client2
CLIENT2_IP=$(docker exec clab-dhcp-configuration-client2 ip addr show eth1 | grep 'inet ' | awk '{print $2}' | cut -d/ -f1)
echo "Client2 IP: $CLIENT2_IP"

# Ping client2 from client1 (but they're on different switch segments)
# DHCP server is the gateway between segments
docker exec clab-dhcp-configuration-client1 ping -c 3 10.1.1.1

# Ping the DHCP server from each client
docker exec clab-dhcp-configuration-client2 ping -c 2 -W 2 10.1.1.1
docker exec clab-dhcp-configuration-client3 ping -c 2 -W 2 10.1.1.1
```

---

### Exercise 8: DHCP Renewal Process

**Simulate a lease renewal:**

```bash
docker exec -it clab-dhcp-configuration-client2 sh

# Manually trigger a lease renewal (normally happens at 50% of lease time)
udhcpc -i eth1 -n -q

# The client sends a unicast Request directly to the server
# (not a broadcast Discover — it already knows its IP and the server)
# Server responds with an Acknowledge, extending the lease

# Verify the IP is the same (renewal keeps the same address)
ip addr show eth1

exit
```

**Lease Lifecycle:**
- **T1 (50% of lease):** Client unicasts a renewal request to the server
- **T2 (87.5% of lease):** Client broadcasts a rebind request to any DHCP server
- **Expiry:** IP is released, client must restart the DORA process

---

## 🧪 Validation Tests

Run the automated validation script:

```bash
cd scripts
./validate.sh
```

**Expected Results:**
- ✅ DHCP server container running
- ✅ All client containers running
- ✅ DHCP server listening on port 67
- ✅ Clients have IPs in the 10.1.1.0/24 range
- ✅ Clients have IPs from the pool (100-200)
- ✅ Clients received default gateway via DHCP
- ✅ Clients received DNS server via DHCP
- ✅ Lease file exists and has active entries
- ✅ Clients can reach the DHCP server

---

## 📚 Key Concepts Review

### DORA Process
- **Discover:** Client broadcasts on 255.255.255.255 (UDP port 67), source 0.0.0.0
- **Offer:** Server unicasts or broadcasts an available IP with options
- **Request:** Client broadcasts its chosen IP (confirms with selected server, tells others)
- **Acknowledge:** Server confirms the lease; client configures its interface

### DHCP Lease
- **Lease time:** How long the IP assignment is valid (12 hours in this lab)
- **Renewal:** Automatic re-request at 50% of lease time (T1)
- **Rebind:** Broadcast re-request at 87.5% of lease time if renewal failed (T2)
- **Expiry:** IP returned to pool if not renewed

### DHCP Options (Common Exam Topics)
| Option Code | Option Name | Purpose |
|-------------|-------------|---------|
| 1 | Subnet Mask | Network mask for the assigned IP |
| 3 | Router | Default gateway address |
| 6 | DNS Server | Name server address |
| 15 | Domain Name | DNS search domain |
| 51 | Lease Time | How long the address is valid |

### DHCP Reservation vs. Static IP
| | DHCP Reservation | Static IP |
|--|-----------------|-----------|
| **Configured on** | DHCP server | Device itself |
| **Address always same?** | Yes (by MAC) | Yes |
| **Centrally managed?** | Yes | No |
| **Use case** | Printers, servers needing predictable IPs | Legacy devices, no DHCP support |

---

## 🔧 Troubleshooting

### Issue: Client has 169.254.x.x address (APIPA)

APIPA means the client didn't receive a DHCP offer.

**Step 1: Verify DHCP server is running**
```bash
docker exec clab-dhcp-configuration-dhcp-server ps aux | grep dnsmasq
```

**Step 2: Check the pool isn't exhausted**
```bash
docker exec clab-dhcp-configuration-dhcp-server wc -l < /var/lib/misc/dnsmasq.leases
```

**Step 3: Verify network connectivity to server**
```bash
docker exec clab-dhcp-configuration-dhcp-server ip addr show
```

**Step 4: Check dnsmasq logs**
```bash
docker exec clab-dhcp-configuration-dhcp-server cat /var/log/dnsmasq.log
```

### Issue: Client received wrong gateway

**Check the dnsmasq configuration:**
```bash
docker exec clab-dhcp-configuration-dhcp-server cat /etc/dnsmasq.conf | grep router
```

**Force a new lease on the client:**
```bash
docker exec clab-dhcp-configuration-client1 udhcpc -i eth1 -n -q
```

### Issue: DHCP server not starting

**Restart dnsmasq manually:**
```bash
docker exec clab-dhcp-configuration-dhcp-server dnsmasq --no-daemon &
```

---

## 🤖 Try with Damira AI

Stuck on this lab? [Damira AI](https://damiraai.com) can help you understand the concepts. Try these prompts (free, no credit card):

- "My DHCP clients are getting 169.254.x.x addresses. Here's my dnsmasq config: [paste]"
- "What's the difference between a DHCP reservation and a static IP assignment?"
- "Walk me through each step of the DHCP DORA process"
- "How do I configure DHCP on a Cisco router using the ip dhcp pool command?"

> Full certification study plans at [PingToPass](https://pingtopass.com)

---

## 📝 Practice Exam Questions

Test your understanding after completing this lab:

**1. A network engineer notices that several workstations have IP addresses starting with 169.254. What is the most likely cause?**

A) The DHCP server is configured with the wrong subnet mask
B) The DHCP server is unreachable or the pool is exhausted
C) The default gateway is misconfigured
D) DNS resolution is failing

<details><summary>Answer</summary>B — 169.254.x.x is an Automatic Private IP Addressing (APIPA) address. It is self-assigned by the client when no DHCP server responds. This happens when the DHCP server is down, unreachable (Layer 2 issue), or the pool has no available addresses.</details>

**2. In the DHCP DORA process, which step does the client use to formally select a specific DHCP server when multiple servers respond?**

A) Discover
B) Offer
C) Request
D) Acknowledge

<details><summary>Answer</summary>C — The Request message is broadcast by the client to formally select one server's offer and implicitly decline all others. Because it's a broadcast, all servers see the Request and those not selected release their reserved address back to the pool.</details>

**3. A DHCP reservation ensures that a specific host always receives the same IP address. What is used to identify that host?**

A) IP address
B) Hostname
C) MAC address
D) DNS name

<details><summary>Answer</summary>C — DHCP reservations are MAC address-based. The DHCP server matches the client's hardware (MAC) address in the Discover or Request packet against the reservation table and assigns the pre-configured IP.</details>

**4. Which DHCP option code delivers the default gateway address to clients?**

A) Option 1
B) Option 3
C) Option 6
D) Option 51

<details><summary>Answer</summary>B — Option 3 (Router) carries the default gateway address. Option 1 is Subnet Mask, Option 6 is DNS Server, and Option 51 is Lease Time.</details>

**5. A client's DHCP lease is set to 8 hours. When will the client first attempt to renew the lease?**

A) After 8 hours (at expiry)
B) After 7 hours (T2, 87.5%)
C) After 4 hours (T1, 50%)
D) After 2 hours (T0, 25%)

<details><summary>Answer</summary>C — The first renewal attempt (T1) occurs at 50% of the lease time, which is 4 hours for an 8-hour lease. The client unicasts a renewal directly to the DHCP server. T2 (rebind, broadcast) occurs at 87.5% — 7 hours in this case.</details>

---

## 🧹 Cleanup

```bash
containerlab destroy -t topology.clab.yml --cleanup
```

---

## 📖 Additional Resources

**Network+ N10-009 Exam Resources:**
- CompTIA Network+ Objectives (Domain 2: Network Implementation, Objective 2.2)
- RFC 2131: Dynamic Host Configuration Protocol

**Hands-On Challenges:**
- Configure a second DHCP scope for a 10.1.2.0/24 network
- Set a very short lease time (60 seconds) and watch automatic renewals
- Configure a DHCP relay agent scenario using a third subnet
- Test pool exhaustion by deploying 110+ clients against a 101-address pool

---

**Lab Version:** 1.0
**Last Updated:** 2026-05-27
**Estimated Completion Time:** 30 minutes
**Difficulty:** Intermediate

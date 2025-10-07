# Network Interface Configuration Lab

## 🎯 Learning Objectives

Master Linux network interface configuration using modern `iproute2` commands - essential skills for Linux system administration.

**CompTIA Linux+ XK0-005 Coverage:**
- ✅ Domain 1: System Management (32% of exam)
  - Configure network interfaces
  - Use ip command suite (addr, link, route)
  - Troubleshoot network connectivity
  - Understand network interface states

**What You'll Learn:**
1. Configure network interfaces using `ip addr` command
2. Manage interface states with `ip link` command
3. View and modify routing tables with `ip route` command
4. Understand interface naming conventions (eth0, eth1, etc.)
5. Troubleshoot connectivity issues at Layer 2 and Layer 3

**Lab Duration:** 20 minutes

**Difficulty:** Beginner

---

## 📋 Prerequisites

- Basic understanding of IP addressing and subnetting
- Familiarity with Linux command line
- Docker and Containerlab installed (or use GitHub Codespaces)

---

## 🏗️ Topology Overview

```
host1 (192.168.1.10/24) --------- host2 (192.168.1.20/24)
         eth1                            eth1
```

**Network Design:**
- **Network:** 192.168.1.0/24 (single subnet)
- **Two hosts:** Direct connection
- **Purpose:** Learn interface configuration commands

---

## 🚀 Quick Start

### Deploy the Lab

```bash
cd linux-plus/01-network-interface-config
containerlab deploy -t topology.clab.yml
```

Wait 10 seconds for containers to initialize.

### Verify Deployment

```bash
containerlab inspect -t topology.clab.yml
```

You should see 2 containers: host1, host2

---

## 🔬 Lab Exercises

### Exercise 1: View Network Interfaces

**Access host1 and examine interfaces:**

```bash
docker exec -it clab-network-interface-config-host1 sh

# Show all network interfaces
ip link show

# Show only eth1 interface
ip link show eth1

# Show brief summary
ip -br link show

# Exit
exit
```

**Expected Output:**
```
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN
2: eth0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue
3: eth1: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue
```

**Key Concepts:**
- **lo:** Loopback interface (127.0.0.1)
- **eth0:** Management interface (containerlab)
- **eth1:** Data interface (our lab network)
- **UP:** Interface is administratively up
- **LOWER_UP:** Physical layer is up (cable connected)

---

### Exercise 2: View IP Addresses

**Show IP address configuration:**

```bash
docker exec clab-network-interface-config-host1 ip addr show

# Show only eth1
docker exec clab-network-interface-config-host1 ip addr show eth1

# Brief format
docker exec clab-network-interface-config-host1 ip -br addr show
```

**Expected Output:**
```
3: eth1: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UP
    inet 192.168.1.10/24 scope global eth1
       valid_lft forever preferred_lft forever
```

**Understanding the Output:**
- **inet:** IPv4 address
- **192.168.1.10/24:** IP address with CIDR notation
- **scope global:** Globally routable (not link-local)
- **valid_lft forever:** Address never expires

---

### Exercise 3: Test Basic Connectivity

**Ping from host1 to host2:**

```bash
docker exec clab-network-interface-config-host1 ping -c 4 192.168.1.20
```

**Expected:** Success! Direct Layer 2 connectivity.

**Check ARP table (Layer 2):**

```bash
docker exec clab-network-interface-config-host1 ip neigh show
```

**Expected Output:**
```
192.168.1.20 dev eth1 lladdr 02:42:ac:14:14:02 REACHABLE
```

**Key Concepts:**
- **ARP:** Maps IP addresses to MAC addresses
- **lladdr:** Link-layer address (MAC address)
- **REACHABLE:** ARP entry is valid

---

### Exercise 4: Remove and Re-add IP Address

**Remove IP address from host1:**

```bash
docker exec clab-network-interface-config-host1 sh

# Remove IP address
ip addr del 192.168.1.10/24 dev eth1

# Verify it's gone
ip addr show eth1

# Try to ping host2 (should FAIL)
exit
docker exec clab-network-interface-config-host1 ping -c 2 192.168.1.20
```

**Expected:** Ping fails (network unreachable)

**Re-add IP address:**

```bash
docker exec clab-network-interface-config-host1 ip addr add 192.168.1.10/24 dev eth1

# Verify connectivity restored
docker exec clab-network-interface-config-host1 ping -c 2 192.168.1.20
```

**Expected:** Success!

---

### Exercise 5: Bring Interface Down/Up

**Disable eth1 interface:**

```bash
docker exec clab-network-interface-config-host1 sh

# Bring interface down
ip link set eth1 down

# Check status (should show "state DOWN")
ip link show eth1

# Try to ping (should FAIL)
exit
docker exec clab-network-interface-config-host1 ping -c 2 192.168.1.20
```

**Expected:** Ping fails (network unreachable)

**Re-enable interface:**

```bash
docker exec clab-network-interface-config-host1 ip link set eth1 up

# Verify connectivity
docker exec clab-network-interface-config-host1 ping -c 2 192.168.1.20
```

**Expected:** Success!

**Key Concept:**
- **Administrative state:** `ip link set <if> up/down` (Layer 1/2)
- **IP configuration:** `ip addr add/del` (Layer 3)
- Both must be correct for connectivity!

---

### Exercise 6: Change Interface MTU

**View current MTU:**

```bash
docker exec clab-network-interface-config-host1 ip link show eth1 | grep mtu
```

**Expected:** mtu 1500 (standard Ethernet)

**Change MTU to 1400:**

```bash
docker exec clab-network-interface-config-host1 ip link set eth1 mtu 1400

# Verify change
docker exec clab-network-interface-config-host1 ip link show eth1 | grep mtu

# Test connectivity (still works, but with smaller packets)
docker exec clab-network-interface-config-host1 ping -c 2 192.168.1.20
```

**Test large packet (should fragment or fail):**

```bash
# Ping with 1450-byte payload (should fail - exceeds MTU with headers)
docker exec clab-network-interface-config-host1 ping -c 2 -s 1450 -M do 192.168.1.20
```

**Expected:** Ping fails or shows fragmentation needed

**Restore default MTU:**

```bash
docker exec clab-network-interface-config-host1 ip link set eth1 mtu 1500
```

**Key Concepts:**
- **MTU (Maximum Transmission Unit):** Largest packet size
- **Standard Ethernet:** 1500 bytes
- **Jumbo Frames:** Up to 9000 bytes (data center networks)

---

### Exercise 7: Add Secondary IP Address

**Add second IP address to host1:**

```bash
docker exec clab-network-interface-config-host1 sh

# Add secondary IP
ip addr add 192.168.1.11/24 dev eth1

# Show all IPs on eth1
ip addr show eth1

# Exit
exit
```

**Expected:** Both 192.168.1.10 and 192.168.1.11 shown

**Test connectivity from host2 to both IPs:**

```bash
docker exec clab-network-interface-config-host2 ping -c 2 192.168.1.10
docker exec clab-network-interface-config-host2 ping -c 2 192.168.1.11
```

**Expected:** Both succeed!

**Key Concept:**
- **Virtual IPs:** Multiple IPs on one interface
- **Use cases:** Load balancing, high availability, multi-tenant systems

---

### Exercise 8: View Routing Table

**Show routing table:**

```bash
docker exec clab-network-interface-config-host1 ip route show

# Verbose format
docker exec clab-network-interface-config-host1 ip -4 route show
```

**Expected Output:**
```
192.168.1.0/24 dev eth1 proto kernel scope link src 192.168.1.10
```

**Understanding the Output:**
- **192.168.1.0/24:** Destination network
- **dev eth1:** Exit interface
- **proto kernel:** Route added by kernel (connected route)
- **src 192.168.1.10:** Source IP for outbound packets

---

### Exercise 9: Add Static Route

**Add route to 10.0.0.0/8 via host2:**

```bash
docker exec clab-network-interface-config-host1 sh

# Add static route
ip route add 10.0.0.0/8 via 192.168.1.20

# Verify route added
ip route show

# Exit
exit
```

**Expected Output includes:**
```
10.0.0.0/8 via 192.168.1.20 dev eth1
```

**Test route lookup:**

```bash
docker exec clab-network-interface-config-host1 ip route get 10.1.1.1
```

**Expected:**
```
10.1.1.1 via 192.168.1.20 dev eth1 src 192.168.1.10
```

**Key Concept:**
- **Static routes:** Manually configured routes
- **Next-hop:** Gateway IP address (192.168.1.20)
- **Route lookup:** `ip route get <IP>` shows selected route

---

### Exercise 10: Compare ip vs Deprecated Commands

**Old way (deprecated):**
```bash
# DON'T USE THESE - DEPRECATED!
ifconfig eth1
route -n
arp -an
```

**Modern way (use these):**
```bash
docker exec clab-network-interface-config-host1 ip addr show eth1
docker exec clab-network-interface-config-host1 ip route show
docker exec clab-network-interface-config-host1 ip neigh show
```

**Why `ip` command is better:**
- ✅ Single unified command suite
- ✅ More features (policy routing, VRFs, etc.)
- ✅ Better performance
- ✅ Actively maintained
- ✅ Required knowledge for modern Linux certifications

---

## 🧪 Validation Tests

Run the automated validation script:

```bash
cd scripts
./validate.sh
```

**Expected Results (18 tests):**
- ✅ Both hosts running
- ✅ IP addresses configured correctly
- ✅ Interfaces in UP state
- ✅ Connectivity between hosts
- ✅ ARP entries populated
- ✅ Routing tables correct

---

## 📚 Key Concepts Review

### iproute2 Command Suite

| Old Command | New Command | Purpose |
|------------|-------------|---------|
| `ifconfig` | `ip addr` | Show/configure IP addresses |
| `ifconfig eth1 up` | `ip link set eth1 up` | Bring interface up |
| `route -n` | `ip route` | Show routing table |
| `arp -an` | `ip neigh` | Show ARP table |
| `netstat -i` | `ip -s link` | Show interface statistics |

### Network Interface States

1. **DOWN:** Administratively disabled
2. **UP:** Administratively enabled
3. **LOWER_UP:** Physical layer up (cable connected)
4. **NO-CARRIER:** No link detected (cable unplugged)

### IP Address Scopes

- **global:** Normal routable address
- **link:** Link-local address (169.254.0.0/16)
- **host:** Loopback address (127.0.0.0/8)

---

## 🔧 Troubleshooting

### Issue: Cannot ping between hosts

**Step 1: Check IP addresses**
```bash
docker exec clab-network-interface-config-host1 ip addr show eth1
docker exec clab-network-interface-config-host2 ip addr show eth1
```

**Step 2: Check interface state**
```bash
docker exec clab-network-interface-config-host1 ip link show eth1
```
Look for "state UP" and "LOWER_UP"

**Step 3: Check routing table**
```bash
docker exec clab-network-interface-config-host1 ip route show
```

**Step 4: Test ARP resolution**
```bash
docker exec clab-network-interface-config-host1 ping -c 1 192.168.1.20
docker exec clab-network-interface-config-host1 ip neigh show
```

### Issue: Interface shows "NO-CARRIER"

**Possible causes:**
- Link is down (check with `ip link`)
- Virtual cable disconnected (containerlab issue)
- Interface needs to be brought up: `ip link set eth1 up`

### Issue: IP address not persisting

**Note:** In this lab, configurations are NOT persistent!
- Changes made with `ip` command are runtime only
- Container restart will reset to topology.clab.yml configuration
- In production: Use `/etc/network/interfaces` or NetworkManager

---

## 🧹 Cleanup

```bash
containerlab destroy -t topology.clab.yml --cleanup
```

---

## 📖 Additional Resources

**Linux+ XK0-005 Exam Resources:**
- CompTIA Linux+ Objectives (Domain 1: System Management)
- man ip(8) - iproute2 documentation
- Linux Foundation - Networking Guide

**Practice Questions:**
1. What command shows all network interfaces in brief format?
2. How do you add IP address 10.1.1.1/24 to interface eth0?
3. What is the difference between `ip link set up` and `ip addr add`?
4. How do you display the routing table?
5. Why should you use `ip` instead of `ifconfig`?

**Hands-On Challenges:**
- Add a third host to the topology
- Configure host1 as a router between two subnets
- Set up VLAN interfaces using `ip link add` (vlan subinterfaces)
- Configure link aggregation (bonding)
- Implement policy-based routing with `ip rule`

---

## 📝 Lab Notes

**What Makes This Lab Special:**
- Uses **modern iproute2** commands (not deprecated net-tools)
- Hands-on with **real Linux networking** (not simulated)
- **Production-ready commands** used in enterprise Linux
- **Zero hardware required** - runs in containers

**Real-World Applications:**
- Configuring network interfaces on Linux servers
- Troubleshooting connectivity issues
- Automating network configuration with scripts
- Managing cloud VMs (AWS, Azure, GCP)
- Container networking (Docker, Kubernetes)

---

**Lab Version:** 1.0
**Last Updated:** 2025-10-07
**Estimated Completion Time:** 20 minutes
**Difficulty:** Beginner

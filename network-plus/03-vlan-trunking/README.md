# VLAN Configuration & Trunking Lab

## 🎯 Learning Objectives

This lab teaches VLAN fundamentals, trunk configuration, and inter-VLAN routing concepts essential for **Network+**, **Linux+**, and **Security+** certifications.

**CompTIA Exam Coverage:**
- ✅ Network+ N10-009: Domain 2 (Switching technologies - VLANs, trunking)
- ✅ Network+ N10-009: Domain 4 (VLAN security)
- ✅ Linux+ XK0-005: Domain 1 (VLAN tagging with Linux)
- ✅ Security+ SY0-701: Domain 3 (Network segmentation)

**What You'll Learn:**
1. Create and configure VLANs using Linux VLAN subinterfaces
2. Configure trunk ports to carry multiple VLANs (802.1Q tagging)
3. Test VLAN isolation between departments
4. Configure inter-VLAN routing for cross-department communication
5. Understand security benefits of network segmentation

**Lab Duration:** 45 minutes

**Difficulty:** Beginner to Intermediate

---

## 📋 Prerequisites

- Basic understanding of IP addressing and subnetting
- Familiarity with Linux command line
- Docker and Containerlab installed (or use GitHub Codespaces)

---

## 🏗️ Topology Overview

```
                    ┌─────────────────┐
                    │   Switch 1      │
                    │  (Core Switch)  │
                    │  Inter-VLAN     │
                    │   Routing       │
                    └────┬────────┬───┘
                         │        │
                 Trunk   │        │  Access Ports
                (802.1Q) │        │  (VLAN 10, 20)
                         │        │
              ┌──────────┴──┐  ┌──┴─────────┐
              │  client3    │  │  client4   │
              │  VLAN 10    │  │  VLAN 20   │
              │ 10.10.10.11 │  │ 10.10.20.11│
              └─────────────┘  └────────────┘
                         │
                         │ Trunk
                         │
                    ┌────┴────────────┐
                    │   Switch 2      │
                    │ (Access Switch) │
                    └────┬────────┬───┘
                         │        │
                 Access  │        │  Access
                 VLAN 10 │        │  VLAN 20
                         │        │
              ┌──────────┴──┐  ┌──┴─────────┐
              │  client1    │  │  client2   │
              │  Engineering│  │   Sales    │
              │ 10.10.10.10 │  │ 10.10.20.10│
              └─────────────┘  └────────────┘
```

**Network Details:**
- **VLAN 10 (Engineering):** 10.10.10.0/24
- **VLAN 20 (Sales):** 10.10.20.0/24
- **VLAN 30 (Management):** 10.10.30.0/24
- **Trunk Protocol:** 802.1Q (IEEE standard)
- **Inter-VLAN Routing:** Enabled on sw1

---

## 🚀 Quick Start

### Deploy the Lab

```bash
cd vlan-trunking-basics
containerlab deploy -t topology.clab.yml
```

Wait 10-15 seconds for all containers to start and configurations to apply.

### Verify Deployment

```bash
containerlab inspect -t topology.clab.yml
```

You should see 6 containers running: sw1, sw2, client1, client2, client3, client4

---

## 🔬 Lab Exercises

### Exercise 1: Verify VLAN Configuration

**Access sw1 and check VLAN interfaces:**

```bash
docker exec -it clab-vlan-trunking-basics-sw1 sh

# Show VLAN interfaces
ip -br addr show

# Expected output:
# eth1.10      UP    10.10.10.1/24
# eth1.20      UP    10.10.20.1/24
# eth1.30      UP    10.10.30.1/24

# Show VLAN details
ip -d link show eth1.10
# Look for "vlan protocol 802.1Q id 10"
```

**Key Concepts:**
- **VLAN Subinterface Naming:** `eth1.10` = physical interface eth1, VLAN ID 10
- **802.1Q Tagging:** Industry standard for VLAN trunking
- **SVI (Switch Virtual Interface):** Layer 3 interface for routing between VLANs

### Exercise 2: Test VLAN Isolation

**Verify that VLANs are properly isolated:**

```bash
# From client1 (VLAN 10)
docker exec -it clab-vlan-trunking-basics-client1 sh

# Ping client3 (same VLAN 10) - Should work
ping -c 3 10.10.10.11

# Try to ping client2 (VLAN 20) - Should work via inter-VLAN routing
ping -c 3 10.10.20.10

# Check routing
ip route
# You should see: default via 10.10.10.1 dev eth1
```

**What's Happening:**
- client1 and client3 are in VLAN 10 and can communicate directly
- client2 is in VLAN 20, requires routing through sw1 gateway
- This demonstrates **network segmentation** (Security+ concept)

### Exercise 3: Verify Trunk Port Configuration

**Check trunk port between sw1 and sw2:**

```bash
docker exec -it clab-vlan-trunking-basics-sw1 sh

# Capture traffic on trunk interface
tcpdump -i eth1 -e -n -c 20

# In another terminal, generate traffic from client1
docker exec -it clab-vlan-trunking-basics-client1 ping -c 5 10.10.10.1
```

**What to Look For:**
- VLAN tags in packet headers (802.1Q)
- Multiple VLANs traversing the same physical link
- This is **trunking** - core Network+ concept

### Exercise 4: Test Inter-VLAN Routing

**Verify communication between different VLANs:**

```bash
# From client1 (VLAN 10) ping client2 (VLAN 20)
docker exec -it clab-vlan-trunking-basics-client1 ping -c 3 10.10.20.10

# Trace the path
docker exec -it clab-vlan-trunking-basics-client1 traceroute 10.10.20.10
# Should show: 10.10.10.1 (sw1 gateway) -> 10.10.20.10 (client2)
```

**Key Security Concept (Security+):**
- Inter-VLAN routing can be controlled with ACLs
- VLANs provide **microsegmentation** at Layer 2
- Default gateway (sw1) acts as enforcement point

### Exercise 5: VLAN Security Testing

**Demonstrate VLAN isolation benefits:**

```bash
# From client1, try to sniff traffic from VLAN 20
docker exec -it clab-vlan-trunking-basics-client1 sh

# Install tcpdump
apk add tcpdump

# Try to capture VLAN 20 traffic (should only see VLAN 10)
tcpdump -i eth1 -n

# In another terminal, generate VLAN 20 traffic
docker exec -it clab-vlan-trunking-basics-client2 ping -c 5 10.10.20.11

# Observe: client1 CANNOT see VLAN 20 traffic
# This demonstrates VLAN security isolation
```

---

## 🧪 Validation Tests

Run the automated validation script:

```bash
cd scripts
./validate.sh
```

**Expected Results:**
- ✅ All 6 containers running
- ✅ VLAN 10 devices can ping each other
- ✅ VLAN 20 devices can ping each other
- ✅ Inter-VLAN routing works (client1 → client2)
- ✅ VLAN isolation confirmed
- ✅ Trunk port carries multiple VLANs

---

## 📚 Key Concepts Review

### VLANs (Virtual LANs)
- **Purpose:** Logically segment a network at Layer 2
- **Benefits:** Security, performance, organization
- **Exam Relevance:** Network+ Domain 2, Security+ Domain 3

### Trunk Ports
- **Protocol:** 802.1Q (IEEE standard)
- **Function:** Carry multiple VLANs over single link
- **Frame Tagging:** Adds 4-byte VLAN tag to Ethernet frames
- **Exam Relevance:** Network+ Domain 2

### Inter-VLAN Routing
- **Methods:** Router-on-a-stick, Layer 3 switch (this lab)
- **Purpose:** Allow controlled communication between VLANs
- **Security:** Gateway becomes policy enforcement point
- **Exam Relevance:** Network+ Domain 2, Security+ Domain 3

### Linux VLAN Implementation
- **Tool:** `ip link` command (iproute2 package)
- **Naming:** `interface.vlan_id` (e.g., eth1.10)
- **Exam Relevance:** Linux+ Domain 1

### Network Segmentation (Security+)
- **Concept:** Divide network into isolated zones
- **Implementation:** VLANs, firewalls, ACLs
- **Benefit:** Limit blast radius of security incidents
- **Exam Relevance:** Security+ Domain 3

---

## 🔧 Troubleshooting

### Issue: Cannot ping between VLANs

**Check inter-VLAN routing on sw1:**
```bash
docker exec -it clab-vlan-trunking-basics-sw1 ip -br addr
# Verify all VLAN interfaces are UP

docker exec -it clab-vlan-trunking-basics-sw1 sysctl net.ipv4.ip_forward
# Should return: net.ipv4.ip_forward = 1
```

### Issue: VLAN interface not showing

**Recreate VLAN subinterface:**
```bash
docker exec -it clab-vlan-trunking-basics-sw1 sh

ip link add link eth1 name eth1.10 type vlan id 10
ip link set eth1.10 up
ip addr add 10.10.10.1/24 dev eth1.10
```

### Issue: Trunk not passing VLANs

**Verify trunk interface is up:**
```bash
docker exec -it clab-vlan-trunking-basics-sw1 ip link show eth1
# Should show: state UP

# Check for VLAN traffic
tcpdump -i eth1 -e -n
```

---

## 🧹 Cleanup

```bash
containerlab destroy -t topology.clab.yml --cleanup
```

---

## 📖 Additional Resources

**Network+ N10-009 Exam Resources:**
- CompTIA Network+ Objectives (Domain 2: Network Implementation)
- IEEE 802.1Q Standard Documentation

**Linux+ XK0-005 Exam Resources:**
- iproute2 Documentation
- Linux VLAN Configuration Guide

**Security+ SY0-701 Exam Resources:**
- Network Segmentation Best Practices
- NIST SP 800-41: Guidelines on Firewalls and Firewall Policy

**Hands-On Practice:**
- Experiment with VLAN 30 (Management) - already configured on sw1
- Add firewall rules between VLANs using iptables (Linux+ topic)
- Configure VLAN ACLs for granular security (Security+ topic)

---

## 📝 Lab Notes

**What Makes This Lab Special:**
- Uses **real Linux networking stack** (not simulated)
- Demonstrates **production network design patterns**
- Covers **3 CompTIA certifications** in one lab
- **Zero hardware required** - runs in containers

**Next Steps:**
- Add iptables firewall rules between VLANs
- Implement DHCP for dynamic addressing
- Configure VLAN QoS (Quality of Service)
- Set up VLAN trunking to additional switches

---

**Lab Version:** 1.0
**Last Updated:** 2025-10-06
**Estimated Completion Time:** 45 minutes
**Difficulty:** Beginner to Intermediate

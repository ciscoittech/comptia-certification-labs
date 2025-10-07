# Static Routing Basics Lab

## 🎯 Learning Objectives

Master static route configuration and verification - a foundation for all Network+ routing concepts.

**CompTIA Network+ N10-009 Coverage:**
- ✅ Domain 2: Network Implementation (20% of exam)
  - Routing technologies and concepts
  - Static routing configuration
  - Route selection and metrics
  - Default gateway configuration

**What You'll Learn:**
1. Configure static routes using the `ip route` command
2. Understand routing table structure and lookup process
3. Verify end-to-end connectivity across multiple routers
4. Troubleshoot routing issues with `traceroute` and `ip route show`
5. Understand the concept of next-hop IP addresses

**Lab Duration:** 30 minutes

**Difficulty:** Beginner

---

## 📋 Prerequisites

- Basic understanding of IP addressing and subnetting
- Familiarity with CIDR notation (/24, /30, etc.)
- Docker and Containerlab installed (or use GitHub Codespaces)

---

## 🏗️ Topology Overview

```
  PC1 (10.1.1.10/24)
      |
      | 10.1.1.0/24
      |
   [R1] (10.1.1.1)
      |
      | 10.1.2.0/24
      |
   [R2] (10.1.2.2, 10.2.2.2)
      |
      | 10.2.2.0/24
      |
   [R3] (10.2.2.3, 10.3.3.3)
      |
      | 10.3.3.0/24
      |
  PC2 (10.3.3.10/24)
```

**Network Topology:**
- **3 Routers:** R1, R2, R3 (linear topology)
- **2 PCs:** PC1 (left), PC2 (right)
- **4 Networks:**
  - 10.1.1.0/24 (PC1 ↔ R1)
  - 10.1.2.0/24 (R1 ↔ R2)
  - 10.2.2.0/24 (R2 ↔ R3)
  - 10.3.3.0/24 (R3 ↔ PC2)

---

## 🚀 Quick Start

### Deploy the Lab

```bash
cd network-plus/01-static-routing-basics
containerlab deploy -t topology.clab.yml
```

Wait 10-15 seconds for containers to initialize.

### Verify Deployment

```bash
containerlab inspect -t topology.clab.yml
```

You should see 5 containers: r1, r2, r3, pc1, pc2

---

## 🔬 Lab Exercises

### Exercise 1: Verify Router Interfaces

**Access R1 and check interface configuration:**

```bash
docker exec -it clab-static-routing-basics-r1 sh

# Show all IP addresses
ip addr show

# Expected output:
# eth1: 10.1.1.1/24 (connected to PC1)
# eth2: 10.1.2.1/24 (connected to R2)

# Show interface status
ip link show

# Exit
exit
```

**Key Concepts:**
- `ip addr show` - Display IP addresses assigned to interfaces
- `eth1`, `eth2` - Ethernet interface names
- `/24` - CIDR notation (255.255.255.0 netmask)

**Repeat for R2 and R3:**
```bash
docker exec -it clab-static-routing-basics-r2 ip addr show
docker exec -it clab-static-routing-basics-r3 ip addr show
```

---

### Exercise 2: Examine Routing Tables

**View R1's routing table:**

```bash
docker exec -it clab-static-routing-basics-r1 ip route show
```

**Expected output:**
```
10.1.1.0/24 dev eth1 proto kernel scope link src 10.1.1.1
10.1.2.0/24 dev eth2 proto kernel scope link src 10.1.2.1
10.2.2.0/24 via 10.1.2.2 dev eth2        # Static route to R2-R3 network
10.3.3.0/24 via 10.1.2.2 dev eth2        # Static route to PC2 network
```

**Understanding the Output:**
- `proto kernel` - Directly connected network (automatic)
- `via 10.1.2.2` - Next-hop IP address (R2's interface)
- `dev eth2` - Exit interface for this route

**View R2 and R3 routing tables:**
```bash
docker exec -it clab-static-routing-basics-r2 ip route show
docker exec -it clab-static-routing-basics-r3 ip route show
```

---

### Exercise 3: Test End-to-End Connectivity

**From PC1, ping PC2:**

```bash
docker exec -it clab-static-routing-basics-pc1 ping -c 4 10.3.3.10
```

**Expected:** Success! Packets traverse R1 → R2 → R3 → PC2

**Trace the path:**

```bash
docker exec -it clab-static-routing-basics-pc1 traceroute 10.3.3.10
```

**Expected output:**
```
1  10.1.1.1 (R1)
2  10.1.2.2 (R2)
3  10.2.2.3 (R3)
4  10.3.3.10 (PC2)
```

**Key Concepts:**
- `traceroute` - Shows each hop along the route
- Packets follow the routing table at each router
- Each router makes an independent forwarding decision

---

### Exercise 4: Routing Table Lookup Simulation

**Simulate routing decision on R1:**

1. PC1 sends packet to 10.3.3.10 (PC2)
2. R1 receives packet on eth1
3. R1 looks up 10.3.3.10 in routing table
4. Matches: `10.3.3.0/24 via 10.1.2.2 dev eth2`
5. R1 forwards packet to 10.1.2.2 (R2) out eth2

**Verify R1's decision:**
```bash
docker exec -it clab-static-routing-basics-r1 ip route get 10.3.3.10
```

**Expected output:**
```
10.3.3.10 via 10.1.2.2 dev eth2 src 10.1.2.1
```

**Try other destinations:**
```bash
docker exec -it clab-static-routing-basics-r1 ip route get 10.2.2.3  # R3
docker exec -it clab-static-routing-basics-r1 ip route get 10.1.1.10 # PC1 (direct)
```

---

### Exercise 5: Remove and Add Static Routes

**Remove static route on R1:**

```bash
docker exec -it clab-static-routing-basics-r1 sh

# Remove route to PC2 network
ip route del 10.3.3.0/24

# Verify it's gone
ip route show

# Try to ping PC2 from PC1 (should FAIL)
exit
docker exec -it clab-static-routing-basics-pc1 ping -c 2 10.3.3.10
```

**Expected:** Ping fails (Network unreachable)

**Re-add the static route:**

```bash
docker exec -it clab-static-routing-basics-r1 ip route add 10.3.3.0/24 via 10.1.2.2

# Verify ping works again
docker exec -it clab-static-routing-basics-pc1 ping -c 2 10.3.3.10
```

**Expected:** Ping succeeds!

---

### Exercise 6: Default Route Configuration

**View PC1's routing table:**

```bash
docker exec -it clab-static-routing-basics-pc1 ip route show
```

**Expected output:**
```
default via 10.1.1.1 dev eth1        # Default route (0.0.0.0/0)
10.1.1.0/24 dev eth1 proto kernel    # Directly connected
```

**Key Concept:**
- `default` route (0.0.0.0/0) - Matches any destination not in the table
- PCs typically have only a default route pointing to their gateway
- Routers need specific routes for reachability

---

## 🧪 Validation Tests

Run the automated validation script:

```bash
cd scripts
./validate.sh
```

**Expected Results:**
- ✅ All 5 containers running
- ✅ PC1 can ping R1 (default gateway)
- ✅ PC2 can ping R3 (default gateway)
- ✅ PC1 can ping PC2 (end-to-end connectivity)
- ✅ Traceroute shows 4 hops (PC1 → R1 → R2 → R3 → PC2)
- ✅ All routers have IP forwarding enabled

---

## 📚 Key Concepts Review

### Static Routing
- **Definition:** Manually configured routes that don't change
- **Use Case:** Small networks, default routes, backup routes
- **Advantage:** Simple, predictable, low overhead
- **Disadvantage:** Doesn't adapt to topology changes

### Routing Table
- **Components:** Destination network, next-hop IP, exit interface, metric
- **Lookup:** Longest prefix match (most specific route wins)
- **Types of Routes:**
  - Connected (directly attached networks)
  - Static (manually configured)
  - Dynamic (learned via routing protocols)

### Next-Hop vs. Exit Interface
- **Next-hop IP:** IP address of the next router in the path
- **Exit interface:** Physical/logical interface to send packet out
- Both are required for successful packet forwarding

### Default Route
- **CIDR:** 0.0.0.0/0 (matches everything)
- **Purpose:** Catch-all for destinations not in routing table
- **Common:** Used on end-user devices and stub networks

---

## 🔧 Troubleshooting

### Issue: PC1 cannot ping PC2

**Step 1: Verify connectivity to default gateway**
```bash
docker exec clab-static-routing-basics-pc1 ping -c 2 10.1.1.1
```

**Step 2: Check routing table on R1**
```bash
docker exec clab-static-routing-basics-r1 ip route show | grep 10.3.3.0
```

**Step 3: Verify IP forwarding is enabled on all routers**
```bash
docker exec clab-static-routing-basics-r1 sysctl net.ipv4.ip_forward
docker exec clab-static-routing-basics-r2 sysctl net.ipv4.ip_forward
docker exec clab-static-routing-basics-r3 sysctl net.ipv4.ip_forward
```

**Step 4: Use traceroute to find where packets are dropped**
```bash
docker exec clab-static-routing-basics-pc1 traceroute 10.3.3.10
```

### Issue: Routing table entry missing

**Re-add static route:**
```bash
docker exec clab-static-routing-basics-r1 ip route add 10.3.3.0/24 via 10.1.2.2
```

### Issue: Wrong next-hop IP

**Remove incorrect route:**
```bash
docker exec clab-static-routing-basics-r1 ip route del 10.3.3.0/24
```

**Add correct route:**
```bash
docker exec clab-static-routing-basics-r1 ip route add 10.3.3.0/24 via 10.1.2.2
```

---

## 🧹 Cleanup

```bash
containerlab destroy -t topology.clab.yml --cleanup
```

---

## 📖 Additional Resources

**Network+ N10-009 Exam Resources:**
- CompTIA Network+ Objectives (Domain 2: Routing Technologies)
- RFC 1812: Requirements for IPv4 Routers

**Practice Questions:**
1. What command shows the routing table on a Linux router?
2. What is the purpose of a default route?
3. How does a router determine the best path when multiple routes exist?
4. What is the difference between a next-hop IP and an exit interface?
5. Why is IP forwarding required on routers?

**Hands-On Challenges:**
- Add a 4th router (R4) between R2 and R3
- Configure redundant paths and observe route selection
- Break connectivity and troubleshoot using `ip route` and `traceroute`
- Configure static routes with different metrics (administrative distance)

---

## 📝 Lab Notes

**What Makes This Lab Special:**
- Uses **real Linux networking** (not simulated)
- Teaches **production command syntax** (`ip route`, not deprecated `route`)
- Demonstrates **actual packet forwarding** at each hop
- **Zero hardware required** - runs in containers

**Real-World Applications:**
- Configuring edge routers in small offices
- Setting up default routes to ISPs
- Creating backup/failover routes
- Understanding dynamic routing protocols (OSPF, EIGRP)

---

**Lab Version:** 1.0
**Last Updated:** 2025-10-07
**Estimated Completion Time:** 30 minutes
**Difficulty:** Beginner

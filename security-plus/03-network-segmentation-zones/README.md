# Network Segmentation with Zones Lab

## 🎯 Learning Objectives

Master network segmentation and VLAN-based security zones.

**CompTIA Security+ SY0-701 Coverage:**
- ✅ Domain 3: Security Architecture (18% of exam)
  - Network segmentation
  - VLAN isolation
  - Microsegmentation
  - Zero-trust principles

**What You'll Learn:**
1. Implement VLAN-based network segmentation
2. Configure zone-based firewall rules
3. Isolate departments (HR, Engineering, Guest)
4. Implement least-privilege network access
5. Test zone isolation effectiveness

**Lab Duration:** 30 minutes
**Difficulty:** Advanced

---

## 🏗️ Topology Overview

```
[Firewall]
    |
    +--- VLAN 10 (10.10.0.0/24) --- HR Client
    +--- VLAN 20 (10.20.0.0/24) --- Engineering Client
    +--- VLAN 30 (10.30.0.0/24) --- Guest Client
    +--- Internet (203.0.113.0/24) --- Internet Server
```

**Security Policy:**
- HR and Engineering can reach internet
- Guest can reach internet (HTTP/HTTPS only)
- HR cannot communicate with Engineering
- Guest cannot communicate with HR or Engineering
- All inter-VLAN traffic blocked by default

---

## 🚀 Quick Start

```bash
cd security-plus/03-network-segmentation-zones
containerlab deploy -t topology.clab.yml
```

---

## 🔬 Lab Exercises

### Exercise 1: Test HR to Internet (Allowed)

```bash
docker exec clab-network-segmentation-zones-hr-client curl -s http://203.0.113.10
```

**Expected:** Success!

### Exercise 2: Test Guest to Internet (HTTP Only)

```bash
docker exec clab-network-segmentation-zones-guest-client curl -s http://203.0.113.10
```

**Expected:** Success! (HTTP allowed)

### Exercise 3: Test HR to Engineering (Blocked)

```bash
docker exec clab-network-segmentation-zones-hr-client ping -c 2 10.20.0.10 || echo "Blocked - Correct!"
```

**Expected:** Blocked! HR cannot reach Engineering.

### Exercise 4: Test Guest to Internal (Blocked)

```bash
docker exec clab-network-segmentation-zones-guest-client ping -c 2 10.10.0.10 || echo "Blocked - Correct!"
```

**Expected:** Blocked! Guest cannot reach internal networks.

---

## 📚 Key Concepts Review

### Network Segmentation Benefits

1. **Containment:** Breach in one zone doesn't affect others
2. **Compliance:** PCI-DSS, HIPAA require segmentation
3. **Performance:** Reduces broadcast domains
4. **Access Control:** Enforce least-privilege

### Microsegmentation

- **Traditional:** One VLAN per department
- **Microsegmentation:** One VLAN per workload/application
- **Zero Trust:** Never trust, always verify

---

**Lab Version:** 1.0  
**Last Updated:** 2025-10-07  
**Estimated Completion Time:** 30 minutes  
**Difficulty:** Advanced

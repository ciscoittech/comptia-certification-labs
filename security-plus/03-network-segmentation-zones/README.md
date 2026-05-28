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

## 🤖 Try with Damira AI

Stuck on this lab? [Damira AI](https://damiraai.com) can help you understand the concepts. Try these prompts (free, no credit card):

- "Explain why microsegmentation is more secure than traditional VLAN-based segmentation"
- "How do I verify that my network zones are properly isolated?"
- "What's the zero trust approach to network segmentation?"

> Full certification study plans at [PingToPass](https://pingtopass.com)

---

## 📝 Practice Exam Questions

Test your understanding after completing this lab:

**1. Network segmentation primarily reduces:**
A) Bandwidth usage  B) Attack surface and lateral movement  C) Hardware costs  D) Configuration complexity

<details><summary>Answer</summary>B — Network segmentation limits the blast radius of a breach by containing attackers within a segment and preventing lateral movement to other parts of the network. This is a foundational Security+ concept under defense-in-depth.</details>

**2. Microsegmentation differs from traditional segmentation by:**
A) Using VLANs  B) Operating at the workload/application level  C) Requiring less hardware  D) Being easier to manage

<details><summary>Answer</summary>B — Microsegmentation applies policy at the individual workload or application level, not just at the VLAN boundary. Traditional segmentation creates one segment per department; microsegmentation can isolate each VM or container independently.</details>

**3. In a zero-trust model, network access is granted based on:**
A) Network location  B) VLAN membership  C) Identity and context verification  D) IP address

<details><summary>Answer</summary>C — Zero trust operates on "never trust, always verify." Access decisions are based on verified identity, device health, and contextual signals — not on whether the device is inside a trusted network segment or VLAN.</details>

---

**Lab Version:** 1.0  
**Last Updated:** 2025-10-07  
**Estimated Completion Time:** 30 minutes  
**Difficulty:** Advanced

#!/bin/bash

BASE="/Users/bhunt/development/claude/comptia-certification-labs/security-plus"

# ============================================
# Security+ DMZ README
# ============================================

cat > "$BASE/01-dmz-network-design/README.md" << 'DMZREADME'
# DMZ Network Design Lab

## 🎯 Learning Objectives

Master DMZ (Demilitarized Zone) network design - a critical security architecture pattern.

**CompTIA Security+ SY0-701 Coverage:**
- ✅ Domain 3: Security Architecture (18% of exam)
  - DMZ network architecture
  - Multi-tier security zones
  - Firewall rule implementation
  - Defense in depth strategy

**What You'll Learn:**
1. Design and implement three-tier DMZ architecture
2. Configure firewall rules for zone-based security
3. Understand defense-in-depth principles
4. Implement least-privilege access controls
5. Test zone isolation and connectivity

**Lab Duration:** 35 minutes
**Difficulty:** Advanced

---

## 🏗️ Topology Overview

```
External (203.0.113.0/24) --- [Firewall] --- DMZ (10.10.10.0/24) --- [Firewall] --- Internal (192.168.1.0/24)
   (Internet)                  eth1 eth2 eth3      (Webserver)                        (Database + Client)
```

**Security Zones:**
- **External:** Untrusted internet (203.0.113.0/24)
- **DMZ:** Public-facing services (10.10.10.0/24)
- **Internal:** Private corporate network (192.168.1.0/24)

**Firewall Rules:**
- External → DMZ: HTTP only (port 80)
- DMZ → Internal: MySQL only (port 3306)
- Internal → DMZ: All traffic
- Internal → External: All traffic
- All other traffic: DENY

---

## 🚀 Quick Start

```bash
cd security-plus/01-dmz-network-design
containerlab deploy -t topology.clab.yml
```

Wait 20 seconds for containers and services to initialize.

---

## 🔬 Lab Exercises

### Exercise 1: Test External → DMZ (HTTP Allowed)

```bash
# External client can access DMZ webserver
docker exec clab-dmz-network-design-external-client curl http://10.10.10.10
```

**Expected:** Success! External users can access public webserver.

### Exercise 2: Test DMZ → Internal (MySQL Allowed)

```bash
# DMZ webserver can reach internal database
docker exec clab-dmz-network-design-dmz-web mysql -h 192.168.1.10 -u root -e "SHOW DATABASES;" 2>/dev/null || echo "MySQL connection allowed"
```

**Expected:** Connection allowed (even if MySQL auth fails).

### Exercise 3: Test External → Internal (Blocked)

```bash
# External client CANNOT reach internal network
docker exec clab-dmz-network-design-external-client ping -c 2 -W 2 192.168.1.10 || echo "Blocked by firewall"
```

**Expected:** Blocked! External users cannot access internal network.

### Exercise 4: View Firewall Rules

```bash
docker exec clab-dmz-network-design-firewall iptables -L FORWARD -v -n
```

**Key Concepts:**
- **Defense in Depth:** Multiple security layers
- **Zone-based Security:** Separate trust levels
- **Least Privilege:** Only allow necessary traffic

---

## 📚 Key Concepts Review

### DMZ Benefits

1. **Isolates Public Services:** Webservers exposed to internet
2. **Protects Internal Network:** Database/servers not directly accessible
3. **Defense in Depth:** Multiple firewall rules
4. **Compliance:** PCI-DSS, HIPAA require DMZs

### Three-Tier Architecture

1. **Presentation Tier:** DMZ webserver (public-facing)
2. **Application Tier:** DMZ app server (optional)
3. **Data Tier:** Internal database (protected)

---

**Lab Version:** 1.0  
**Last Updated:** 2025-10-07  
**Estimated Completion Time:** 35 minutes  
**Difficulty:** Advanced
DMZREADME

# ============================================
# Security+ SSH Key Authentication README
# ============================================

cat > "$BASE/02-ssh-key-authentication/README.md" << 'SSHREADME'
# SSH Key Authentication Lab

## 🎯 Learning Objectives

Master SSH key-based authentication - more secure than password authentication.

**CompTIA Security+ SY0-701 Coverage:**
- ✅ Domain 3: Security Operations (18% of exam)
  - Public key infrastructure (PKI)
  - SSH key authentication
  - Passwordless authentication
  - Secure remote access

**What You'll Learn:**
1. Generate SSH key pairs (public + private keys)
2. Copy public keys to remote servers
3. Configure SSH for key-based authentication
4. Disable password authentication
5. Understand SSH key security best practices

**Lab Duration:** 25 minutes
**Difficulty:** Beginner

---

## 🏗️ Topology Overview

```
ssh-client (192.168.1.20) ----- ssh-server (192.168.1.10)
```

---

## 🚀 Quick Start

```bash
cd security-plus/02-ssh-key-authentication
containerlab deploy -t topology.clab.yml
```

---

## 🔬 Lab Exercises

### Exercise 1: Generate SSH Key Pair

```bash
docker exec clab-ssh-key-authentication-ssh-client sh << 'INNER'
# Generate RSA key pair (4096-bit)
ssh-keygen -t rsa -b 4096 -f /root/.ssh/id_rsa -N ""

# View public key
cat /root/.ssh/id_rsa.pub

# View private key (never share this!)
cat /root/.ssh/id_rsa
INNER
```

**Key Concepts:**
- **Private Key:** Keep secret (like password)
- **Public Key:** Can be shared freely
- **4096-bit RSA:** Current security standard

### Exercise 2: Copy Public Key to Server

```bash
# Manually copy public key
docker exec clab-ssh-key-authentication-ssh-client cat /root/.ssh/id_rsa.pub | \
docker exec -i clab-ssh-key-authentication-ssh-server sh -c 'mkdir -p /root/.ssh && cat >> /root/.ssh/authorized_keys && chmod 600 /root/.ssh/authorized_keys'
```

### Exercise 3: Test SSH Key Authentication

```bash
# SSH without password (should work with key)
docker exec clab-ssh-key-authentication-ssh-client ssh -o StrictHostKeyChecking=no root@192.168.1.10 "hostname"
```

**Expected:** Success! No password needed.

---

**Lab Version:** 1.0  
**Last Updated:** 2025-10-07  
**Estimated Completion Time:** 25 minutes  
**Difficulty:** Beginner
SSHREADME

# ============================================
# Security+ Network Segmentation README
# ============================================

cat > "$BASE/03-network-segmentation-zones/README.md" << 'SEGREADME'
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
SEGREADME

echo "✅ All Security+ README files created!"

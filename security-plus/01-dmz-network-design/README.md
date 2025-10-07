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

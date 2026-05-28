# DNS Fundamentals Lab

## 🎯 Learning Objectives

Master DNS resolution, record types, and troubleshooting tools — fundamental Network+ knowledge tested across multiple exam domains.

**CompTIA Network+ N10-009 Coverage:**
- ✅ Domain 2: Network Implementation (20% of exam)
  - 2.3 — DNS concepts and record types
  - Forward and reverse DNS lookups
  - DNS hierarchy and resolution process
  - DNS troubleshooting tools (dig, nslookup, host)

**What You'll Learn:**
1. Understand how DNS translates hostnames to IP addresses
2. Query DNS using `dig` and `nslookup`
3. Distinguish between forward and reverse DNS lookups
4. Interpret DNS query output (flags, TTL, ANSWER section)
5. Test for NXDOMAIN (non-existent domain) responses
6. Troubleshoot DNS resolution failures

**Lab Duration:** 30 minutes

**Difficulty:** Beginner

---

## 📋 Prerequisites

- Basic understanding of IP addressing
- Familiarity with client-server communication
- Docker and Containerlab installed (or use GitHub Codespaces)

---

## 🏗️ Topology Overview

```
    [DNS Server]              [Web Server]
    10.2.1.1/24               10.2.1.10/24
         |                         |
    eth1 |                    eth1 |
         +-------- [switch] -------+
                       |
                  eth1 |
               [Client]
              10.2.1.50/24
         nameserver: 10.2.1.1
```

**Network Topology:**
- **DNS Server:** dnsmasq on 10.2.1.1 — authoritative for lab.local zone
- **Web Server:** 10.2.1.10 — resolves as `web.lab.local`
- **Client:** 10.2.1.50 — configured to use 10.2.1.1 as DNS server

**DNS Records Configured:**
| Hostname | Record Type | Value |
|----------|-------------|-------|
| web.lab.local | A | 10.2.1.10 |
| db.lab.local | A | 10.2.1.20 |
| mail.lab.local | A | 10.2.1.30 |
| 10.2.1.10 | PTR | web.lab.local |

---

## 🚀 Quick Start

### Deploy the Lab

```bash
cd network-plus/05-dns-fundamentals
containerlab deploy -t topology.clab.yml
```

Wait 15 seconds for containers to initialize.

### Verify Deployment

```bash
containerlab inspect -t topology.clab.yml
```

You should see 3 containers: dns-server, web-server, client

---

## 🔬 Lab Exercises

### Exercise 1: Verify the DNS Server

**Check dnsmasq is running and inspect the zone configuration:**

```bash
docker exec -it clab-dns-fundamentals-dns-server sh

# Verify the process is running
ps aux | grep dnsmasq

# Inspect the zone records
cat /etc/dnsmasq.conf

# Check what IP the server is listening on
ip addr show eth1

exit
```

**Key Concepts:**
- `address=/web.lab.local/10.2.1.10` — static A record for forward lookup
- `ptr-record=10.2.1.10.in-addr.arpa,web.lab.local` — static PTR record for reverse lookup
- `server=8.8.8.8` — upstream resolver for names not in local zone
- `listen-address=10.2.1.1` — only accept queries on this interface

---

### Exercise 2: Basic DNS Query with dig

**From the client, query the DNS server for `web.lab.local`:**

```bash
docker exec -it clab-dns-fundamentals-client sh

# Forward DNS lookup using dig
dig @10.2.1.1 web.lab.local

exit
```

**Reading the dig Output:**

```
; <<>> DiG 9.x.x <<>> @10.2.1.1 web.lab.local
; (1 server found)
;; QUESTION SECTION:
;web.lab.local.          IN  A

;; ANSWER SECTION:
web.lab.local.    0  IN  A  10.2.1.10

;; Query time: 1 msec
;; SERVER: 10.2.1.1#53(10.2.1.1)
```

**Key Fields:**
- **QUESTION SECTION:** What you asked for (`web.lab.local`, type `A`)
- **ANSWER SECTION:** The result (`10.2.1.10`)
- **TTL (0):** Time-to-live — how long resolvers can cache this answer
- **IN:** Internet class (always IN for standard queries)
- **A:** Address record type (IPv4)
- **SERVER:** Which DNS server answered the query

---

### Exercise 3: Query Multiple Records

**Query all configured A records:**

```bash
docker exec -it clab-dns-fundamentals-client sh

# Query each hostname
dig @10.2.1.1 web.lab.local A
dig @10.2.1.1 db.lab.local A
dig @10.2.1.1 mail.lab.local A

# Short output format (just the answer)
dig @10.2.1.1 web.lab.local +short
dig @10.2.1.1 db.lab.local +short
dig @10.2.1.1 mail.lab.local +short

exit
```

**Expected `+short` output:**
```
10.2.1.10
10.2.1.20
10.2.1.30
```

**Why Multiple Records Matter:**
- A single domain can have multiple A records (load balancing)
- Round-robin DNS distributes traffic across multiple servers
- Network+ tests your ability to read and interpret these responses

---

### Exercise 4: Use nslookup

**nslookup is an older but still exam-relevant DNS tool:**

```bash
docker exec -it clab-dns-fundamentals-client sh

# Interactive nslookup session
nslookup web.lab.local 10.2.1.1

# Non-interactive query
nslookup db.lab.local 10.2.1.1

exit
```

**Reading nslookup Output:**

```
Server:     10.2.1.1
Address:    10.2.1.1#53

Name:   web.lab.local
Address: 10.2.1.10
```

**Key Fields:**
- **Server / Address:** The DNS server that answered the query
- **Name:** The hostname that was resolved
- **Address:** The resolved IP address

**dig vs nslookup:**
- `dig` — Modern, verbose, shows full DNS packet details. Preferred by network engineers.
- `nslookup` — Older, simpler output. Still common on Windows and in exam questions.
- Both are tested on Network+ N10-009.

---

### Exercise 5: Forward DNS Lookup (A Record)

**Verify forward lookup resolution path:**

```bash
# Forward lookup: hostname → IP
docker exec clab-dns-fundamentals-client dig @10.2.1.1 web.lab.local A +short

# This should return: 10.2.1.10

# Also test using the configured resolv.conf (no @server needed)
docker exec clab-dns-fundamentals-client nslookup web.lab.local
```

**How Forward Lookup Works:**
1. Client asks DNS server: "What is the IP for `web.lab.local`?"
2. DNS server checks its local records
3. Finds: `address=/web.lab.local/10.2.1.10`
4. Returns: A record with value 10.2.1.10
5. Client caches the result for TTL seconds, then contacts 10.2.1.10

---

### Exercise 6: Reverse DNS Lookup (PTR Record)

**Reverse lookup maps an IP address back to a hostname:**

```bash
docker exec -it clab-dns-fundamentals-client sh

# Reverse lookup: IP → hostname
dig @10.2.1.1 -x 10.2.1.10

# Short format
dig @10.2.1.1 -x 10.2.1.10 +short

exit
```

**Expected output:**
```
web.lab.local.
```

**How Reverse Lookup Works:**
- DNS reverses the IP octets and appends `.in-addr.arpa`
- `10.2.1.10` becomes the query `10.1.2.10.in-addr.arpa`
- The PTR record maps this back to `web.lab.local`

**Why Reverse DNS Matters:**
- Email spam filtering (mail servers verify PTR records)
- Security logs (hostnames in logs are easier to read than IPs)
- Network troubleshooting (`traceroute` uses PTR for hop names)

---

### Exercise 7: Test NXDOMAIN (Non-Existent Domain)

**NXDOMAIN is the DNS response when a name doesn't exist:**

```bash
docker exec -it clab-dns-fundamentals-client sh

# Query for a hostname that does not exist
dig @10.2.1.1 nonexistent.lab.local

# Look for the status in the output:
# ;; ->>HEADER<<- opcode: QUERY, status: NXDOMAIN

# nslookup version
nslookup nonexistent.lab.local 10.2.1.1

exit
```

**Expected dig output snippet:**
```
;; ->>HEADER<<- opcode: QUERY, status: NXDOMAIN, id: XXXX
;; flags: qr aa rd ra; QUERY: 1, ANSWER: 0, AUTHORITY: 0
```

**DNS Response Codes (RCODE):**
| Code | Name | Meaning |
|------|------|---------|
| 0 | NOERROR | Query successful |
| 1 | FORMERR | Format error in query |
| 2 | SERVFAIL | Server failed to complete the request |
| 3 | NXDOMAIN | Name does not exist |
| 5 | REFUSED | Server refused the query (policy) |

---

### Exercise 8: View DNS Query Logs on the Server

**Inspect what queries the DNS server has processed:**

```bash
docker exec -it clab-dns-fundamentals-dns-server sh

# View DNS query log
cat /var/log/dnsmasq.log

# Each line shows: timestamp, query type, name, from client IP
# Example:
# dnsmasq[1]: query[A] web.lab.local from 10.2.1.50
# dnsmasq[1]: config web.lab.local is 10.2.1.10

exit
```

**What the Log Reveals:**
- Which clients are making queries (source IP)
- What names they're querying (could reveal application behavior)
- Whether queries hit the local config or upstream resolver
- Queries answered from cache vs. authoritative data

---

## 🧪 Validation Tests

Run the automated validation script:

```bash
cd scripts
./validate.sh
```

**Expected Results:**
- ✅ DNS server container running
- ✅ Web server container running
- ✅ Client container running
- ✅ DNS server listening on port 53
- ✅ Forward lookup: web.lab.local → 10.2.1.10
- ✅ Forward lookup: db.lab.local → 10.2.1.20
- ✅ Forward lookup: mail.lab.local → 10.2.1.30
- ✅ Reverse lookup: 10.2.1.10 → web.lab.local
- ✅ NXDOMAIN returned for nonexistent.lab.local
- ✅ Client resolv.conf points to DNS server
- ✅ Client can ping web-server by IP
- ✅ DNS query log exists on server

---

## 📚 Key Concepts Review

### DNS Hierarchy
```
. (root)
└── local.
    └── lab.local.
        ├── web.lab.local.   → 10.2.1.10
        ├── db.lab.local.    → 10.2.1.20
        └── mail.lab.local.  → 10.2.1.30
```

### Common DNS Record Types
| Type | Purpose | Example |
|------|---------|---------|
| **A** | IPv4 address | web.lab.local → 10.2.1.10 |
| **AAAA** | IPv6 address | web.lab.local → 2001:db8::1 |
| **CNAME** | Alias (canonical name) | www → web.lab.local |
| **MX** | Mail exchange | lab.local → mail.lab.local (priority 10) |
| **NS** | Name server | lab.local → ns1.lab.local |
| **PTR** | Reverse lookup | 10.2.1.10 → web.lab.local |
| **SOA** | Start of Authority | Zone metadata + serial number |
| **TXT** | Text record | SPF, DKIM, domain verification |

### DNS Resolution Process
1. **Client** checks local cache
2. **Client** checks `/etc/hosts`
3. **Client** sends query to configured **recursive resolver** (10.2.1.1 in this lab)
4. **Resolver** checks its cache
5. **Resolver** queries root servers (if needed)
6. **Root servers** direct to TLD servers (.local, .com, etc.)
7. **TLD servers** direct to authoritative nameservers
8. **Authoritative server** returns the answer
9. **Resolver** caches the answer and returns it to the client

### DNS Tools Reference
```bash
# dig — detailed query output
dig @<server> <name> <type>
dig @10.2.1.1 web.lab.local A
dig @10.2.1.1 -x 10.2.1.10     # reverse lookup

# nslookup — simpler output
nslookup <name> <server>
nslookup web.lab.local 10.2.1.1

# host — compact one-line output
host web.lab.local 10.2.1.1
```

---

## 🔧 Troubleshooting

### Issue: Client cannot resolve names

**Step 1: Check resolv.conf**
```bash
docker exec clab-dns-fundamentals-client cat /etc/resolv.conf
# Should contain: nameserver 10.2.1.1
```

**Step 2: Test connectivity to DNS server**
```bash
docker exec clab-dns-fundamentals-client ping -c 2 10.2.1.1
```

**Step 3: Query DNS server directly**
```bash
docker exec clab-dns-fundamentals-client dig @10.2.1.1 web.lab.local
```

**Step 4: Verify dnsmasq is running on server**
```bash
docker exec clab-dns-fundamentals-dns-server ps aux | grep dnsmasq
```

### Issue: dig returns SERVFAIL

**Check dnsmasq configuration syntax:**
```bash
docker exec clab-dns-fundamentals-dns-server dnsmasq --test
```

**Check the dnsmasq log for errors:**
```bash
docker exec clab-dns-fundamentals-dns-server cat /var/log/dnsmasq.log
```

### Issue: Reverse lookup fails

**Verify PTR records in config:**
```bash
docker exec clab-dns-fundamentals-dns-server grep ptr-record /etc/dnsmasq.conf
```

**Test the PTR query directly:**
```bash
docker exec clab-dns-fundamentals-client dig @10.2.1.1 -x 10.2.1.10 +short
```

---

## 🤖 Try with Damira AI

Stuck on this lab? [Damira AI](https://damiraai.com) can help you understand the concepts. Try these prompts (free, no credit card):

- "My dig query returns SERVFAIL instead of an answer. Here's the output: [paste]"
- "What's the difference between an A record and a CNAME record?"
- "Walk me through how DNS resolution works step by step"
- "How do I troubleshoot DNS on a Cisco router using debug ip dns?"

> Full certification study plans at [PingToPass](https://pingtopass.com)

---

## 📝 Practice Exam Questions

Test your understanding after completing this lab:

**1. Which DNS record type maps a hostname to an IPv4 address?**

A) PTR
B) CNAME
C) A
D) MX

<details><summary>Answer</summary>C — The A (Address) record maps a hostname to an IPv4 address. PTR is the reverse mapping (IP → hostname). CNAME creates an alias. MX specifies mail servers.</details>

**2. A network technician runs `nslookup mail.corp.com` and receives a "Non-existent domain" response. What DNS response code was returned?**

A) NOERROR
B) SERVFAIL
C) REFUSED
D) NXDOMAIN

<details><summary>Answer</summary>D — NXDOMAIN (Non-Existent Domain) is returned when the queried name does not exist in DNS. It is DNS response code 3. SERVFAIL means the server failed to complete the query. REFUSED means the server rejected the query by policy.</details>

**3. Which file on a Linux client specifies which DNS servers to use for resolution?**

A) /etc/hosts
B) /etc/resolv.conf
C) /etc/nsswitch.conf
D) /etc/named.conf

<details><summary>Answer</summary>B — /etc/resolv.conf contains the `nameserver` entries pointing to DNS resolvers. /etc/hosts provides static hostname-to-IP mappings checked before DNS. /etc/nsswitch.conf controls the order of resolution methods. /etc/named.conf is the BIND server configuration file.</details>

**4. What is the purpose of a PTR record in DNS?**

A) Delegates authority for a subdomain to another nameserver
B) Maps a hostname to an IPv6 address
C) Maps an IP address back to a hostname (reverse lookup)
D) Creates an alias from one hostname to another

<details><summary>Answer</summary>C — A PTR (Pointer) record enables reverse DNS lookup — mapping an IP address to a hostname. PTR records are stored in the special `in-addr.arpa` domain. They are used by email servers for spam filtering and by network tools for displaying hostnames in logs and traceroutes.</details>

**5. A dig query to a DNS server for `db.corp.com` returns an answer with TTL of 300. What does this mean?**

A) The record will expire in 300 milliseconds
B) Only 300 clients can query this record
C) The record can be cached by resolvers for 300 seconds
D) The query was processed in 300 microseconds

<details><summary>Answer</summary>C — TTL (Time to Live) specifies how long DNS resolvers and clients may cache the record, in seconds. A TTL of 300 means the record can be cached for 5 minutes. After expiry, resolvers must query the authoritative server again for a fresh answer.</details>

---

## 🧹 Cleanup

```bash
containerlab destroy -t topology.clab.yml --cleanup
```

---

## 📖 Additional Resources

**Network+ N10-009 Exam Resources:**
- CompTIA Network+ Objectives (Domain 2: Network Implementation, Objective 2.3)
- RFC 1034/1035: Domain Name System specifications

**Hands-On Challenges:**
- Add a CNAME record (`www.lab.local` → `web.lab.local`) and query it
- Configure a second DNS server and test failover from the client
- Add an MX record and query it with `dig @10.2.1.1 lab.local MX`
- Test DNS over TCP: `dig @10.2.1.1 web.lab.local +tcp`
- Simulate DNS cache poisoning by returning a wrong A record

---

**Lab Version:** 1.0
**Last Updated:** 2026-05-27
**Estimated Completion Time:** 30 minutes
**Difficulty:** Beginner

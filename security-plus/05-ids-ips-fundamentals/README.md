# IDS/IPS Fundamentals Lab

## 🎯 Learning Objectives

Master intrusion detection concepts through hands-on packet capture, analysis, and rule writing — a core Security+ topic.

**CompTIA Security+ SY0-701 Coverage:**
- ✅ Domain 4: Security Operations (28% of exam)
  - 4.4 Security monitoring
  - Intrusion detection and prevention systems
  - Signature-based vs anomaly-based detection
  - Alert analysis and tuning
  - IDS vs IPS differences

**What You'll Learn:**
1. Understand IDS sensor placement in the network
2. Capture and analyze traffic with tcpdump
3. Distinguish normal vs suspicious traffic patterns
4. Write a simple port-scan detection rule in Python
5. Test detection logic against captured traffic
6. Convert passive IDS detection into active IPS blocking

**Lab Duration:** 35 minutes
**Difficulty:** Intermediate

---

## 🏗️ Topology Overview

```
Attacker (10.3.1.10)
       |
  [eth1 — sensor — eth2]    <-- IDS/IPS sensor inline between segments
  (10.3.1.1)    (10.3.2.1)
                   |
          Web Server (10.3.2.10)
```

**Segments:**
- **Attack segment:** 10.3.1.0/24 (attacker → sensor eth1)
- **Server segment:** 10.3.2.0/24 (sensor eth2 → web server)
- **Sensor:** Inline router with forwarding enabled — sees all traffic between segments

This topology simulates a **Network IDS (NIDS)** positioned inline between an untrusted segment and a protected server. The sensor can passively inspect (IDS) or actively block (IPS).

---

## 🚀 Quick Start

```bash
cd security-plus/05-ids-ips-fundamentals
containerlab deploy -t topology.clab.yml
```

Wait 20 seconds for containers and services to initialize.

---

## 🔬 Lab Exercises

### Exercise 1: Verify Topology

Before detecting anything, confirm the network is working end-to-end.

```bash
# Attacker can reach web server through the sensor
docker exec clab-ids-ips-fundamentals-attacker curl -s http://10.3.2.10

# Attacker can ping the sensor
docker exec clab-ids-ips-fundamentals-attacker ping -c 2 10.3.1.1

# Sensor can see both interfaces
docker exec clab-ids-ips-fundamentals-sensor ip addr show eth1
docker exec clab-ids-ips-fundamentals-sensor ip addr show eth2
```

**Expected:** curl returns "Secure Web Server", pings succeed.

**Key Concept:** The sensor sits inline — traffic physically passes through it. This placement lets it inspect every packet without requiring port mirroring (which would only give a copy of traffic).

### Exercise 2: Start Packet Capture on the Sensor

The sensor uses `tcpdump` to capture all traffic coming from the attacker segment.

```bash
# Start a background packet capture on eth1 (attacker-facing interface)
docker exec -d clab-ids-ips-fundamentals-sensor \
    tcpdump -i eth1 -w /var/log/ids/capture.pcap -q

echo "Capture started — tcpdump running in background on sensor eth1"
```

**Verify the capture process started:**
```bash
docker exec clab-ids-ips-fundamentals-sensor sh -c 'ps | grep tcpdump | grep -v grep'
```

**Key Concept:** Real NIDS platforms (Suricata, Snort, Zeek) do the same thing — they listen on a network interface and inspect every packet. tcpdump gives us the raw packet capture capability that IDS engines build on.

### Exercise 3: Generate Normal Traffic

Produce legitimate HTTP requests so we have baseline traffic in the capture.

```bash
# Normal HTTP requests — what a real user would generate
docker exec clab-ids-ips-fundamentals-attacker sh -c '
  for i in 1 2 3 4 5; do
    curl -s http://10.3.2.10 > /dev/null
    echo "Request $i sent"
    sleep 1
  done
'
```

**Key Concept:** IDS systems need a baseline of normal traffic. Without it, every alert is noise. Anomaly-based detection learns what "normal" looks like (volume, protocols, port usage) and alerts on deviations.

### Exercise 4: Generate Suspicious Traffic — Port Scan

Now generate the kind of traffic a real attacker would produce before an attack: a port scan.

```bash
# SYN scan against the web server (classic attacker reconnaissance)
docker exec clab-ids-ips-fundamentals-attacker nmap -sS 10.3.2.10

# More aggressive scan (all ports, OS detection)
docker exec clab-ids-ips-fundamentals-attacker nmap -sS -p 1-1000 10.3.2.10
```

**What nmap -sS does:**
- Sends TCP SYN packets to hundreds of ports rapidly
- Does NOT complete the 3-way handshake (SYN → SYN-ACK → RST)
- Normal connections only open 1-2 ports; a scan opens many in seconds
- This rapid SYN pattern is the signature IDS systems look for

### Exercise 5: Analyze Captured Packets

Stop the capture and examine what was recorded.

```bash
# Stop tcpdump
docker exec clab-ids-ips-fundamentals-sensor sh -c 'pkill tcpdump; sleep 1; echo "Capture stopped"'

# List the capture file
docker exec clab-ids-ips-fundamentals-sensor ls -lh /var/log/ids/capture.pcap

# Show all captured traffic (summary)
docker exec clab-ids-ips-fundamentals-sensor \
    tcpdump -r /var/log/ids/capture.pcap -n

# Show only SYN packets (no ACK flag set) — the hallmark of a port scan
docker exec clab-ids-ips-fundamentals-sensor \
    tcpdump -r /var/log/ids/capture.pcap -n 'tcp[tcpflags] & tcp-syn != 0 and tcp[tcpflags] & tcp-ack == 0'
```

**What to look for:**
- Normal HTTP traffic: SYN to port 80, then SYN-ACK, ACK (3-way handshake), then GET request
- Port scan: Rapid SYN packets to many different destination ports from the same source

**Count unique destination ports in the capture:**
```bash
docker exec clab-ids-ips-fundamentals-sensor \
    tcpdump -r /var/log/ids/capture.pcap -n 'tcp' 2>/dev/null | \
    awk '{print $5}' | cut -d. -f5 | sort -u | wc -l
```

### Exercise 6: Write a Simple Detection Rule

Write a Python script that reads the capture and alerts when it detects a port scan (many SYN packets to different ports from the same source in a short window).

```bash
# Write the detection script to the sensor
docker exec clab-ids-ips-fundamentals-sensor sh -c "cat > /etc/ids/rules/portscan_detect.py << 'PYEOF'
#!/usr/bin/env python3
\"\"\"
Simple port scan detector.
Reads a pcap file and alerts if any source IP sends SYN packets
to more than THRESHOLD unique destination ports.
\"\"\"
import subprocess
import sys
from collections import defaultdict

THRESHOLD = 10  # alert if a source hits more than 10 unique ports

def parse_pcap(pcap_file):
    \"\"\"Use tcpdump to extract SYN packets from the capture.\"\"\"
    cmd = [
        'tcpdump', '-r', pcap_file, '-n',
        'tcp[tcpflags] & tcp-syn != 0 and tcp[tcpflags] & tcp-ack == 0'
    ]
    result = subprocess.run(cmd, capture_output=True, text=True)
    return result.stdout.splitlines()

def extract_src_dst(line):
    \"\"\"Parse 'IP src.port > dst.port' from a tcpdump line.\"\"\"
    try:
        parts = line.split()
        # Format: timestamp IP src.port > dst.port: Flags
        src_full = parts[2]
        dst_full = parts[4].rstrip(':')
        # Last field after last dot is port
        src_ip = '.'.join(src_full.split('.')[:-1])
        dst_port = int(dst_full.split('.')[-1])
        return src_ip, dst_port
    except (IndexError, ValueError):
        return None, None

def detect_port_scan(pcap_file):
    print(f'Analyzing capture: {pcap_file}')
    print(f'Alert threshold: {THRESHOLD} unique destination ports')
    print('-' * 50)

    lines = parse_pcap(pcap_file)
    syn_map = defaultdict(set)  # src_ip -> set of destination ports

    for line in lines:
        src_ip, dst_port = extract_src_dst(line)
        if src_ip and dst_port:
            syn_map[src_ip].add(dst_port)

    alerts = 0
    for src_ip, ports in syn_map.items():
        port_count = len(ports)
        status = 'ALERT' if port_count > THRESHOLD else 'OK'
        print(f'[{status}] {src_ip} sent SYN to {port_count} unique ports')
        if port_count > THRESHOLD:
            print(f'        Ports scanned: {sorted(ports)[:20]}...')
            alerts += 1

    print('-' * 50)
    if alerts:
        print(f'RESULT: {alerts} port scan(s) detected!')
    else:
        print('RESULT: No port scans detected.')

if __name__ == '__main__':
    pcap = sys.argv[1] if len(sys.argv) > 1 else '/var/log/ids/capture.pcap'
    detect_port_scan(pcap)
PYEOF"
```

### Exercise 7: Run the Detection Rule Against the Capture

```bash
# Run the detector
docker exec clab-ids-ips-fundamentals-sensor \
    python3 /etc/ids/rules/portscan_detect.py /var/log/ids/capture.pcap
```

**Expected output:**
```
[OK]    10.3.1.10 sent SYN to 5 unique ports        <- normal HTTP traffic
[ALERT] 10.3.1.10 sent SYN to 983 unique ports      <- the nmap scan
RESULT: 1 port scan(s) detected!
```

**Key Concepts:**
- This is **signature-based detection** — we have a specific rule (threshold on unique ports)
- **False positives:** A legitimate load balancer health-checking many ports would also trigger
- **False negatives:** A slow scan (1 port per hour) would not trigger this threshold
- Real IDS platforms (Suricata) use thousands of community-maintained rules like this

### Exercise 8: IDS vs IPS — Add a Blocking Rule

An IDS only **alerts**. An IPS **blocks**. Convert the sensor from IDS to IPS by adding an iptables rule after detection.

```bash
# First, confirm the attacker can currently reach the web server
docker exec clab-ids-ips-fundamentals-attacker curl -s --max-time 3 http://10.3.2.10

# Now add an IPS block rule on the sensor — drop all traffic from the attacker
docker exec clab-ids-ips-fundamentals-sensor \
    iptables -I FORWARD -s 10.3.1.10 -j DROP

echo "IPS rule added — attacker traffic is now blocked"

# Verify the attacker is blocked
docker exec clab-ids-ips-fundamentals-attacker curl -s --max-time 3 http://10.3.2.10 || echo "Blocked by IPS — expected"

# Check the IPS rule
docker exec clab-ids-ips-fundamentals-sensor iptables -L FORWARD -v -n
```

**Remove the block to continue experimenting:**
```bash
docker exec clab-ids-ips-fundamentals-sensor iptables -D FORWARD -s 10.3.1.10 -j DROP
```

**IDS vs IPS Summary:**
| | IDS (Intrusion Detection) | IPS (Intrusion Prevention) |
|---|---|---|
| Action | Alerts/logs | Blocks traffic |
| Placement | Out-of-band (tap/mirror) or inline | Must be inline |
| Risk | None — passive | Can block legitimate traffic (false positives) |
| Latency | Low | Adds forwarding delay |
| Use case | Monitoring, forensics | Active defense |

---

## 📚 Key Concepts Review

### Signature-Based vs Anomaly-Based Detection

**Signature-based (pattern matching):**
- Matches traffic against known attack patterns
- Fast and accurate for known threats
- Misses zero-day attacks (no signature yet)
- Requires regular rule updates
- Example: Snort, Suricata rules

**Anomaly-based (behavioral):**
- Learns baseline normal behavior
- Alerts on statistical deviations
- Can catch unknown threats
- Higher false positive rate during learning
- Example: Machine learning-based UEBA

### False Positives vs False Negatives

| | Meaning | Business Impact |
|---|---|---|
| **False Positive (FP)** | Alert fired on benign traffic | Wasted analyst time, alert fatigue |
| **False Negative (FN)** | Real attack not detected | Security incident, data breach |
| **True Positive (TP)** | Real attack correctly flagged | Desired outcome |
| **True Negative (TN)** | Benign traffic correctly ignored | Desired outcome |

**Alert tuning** adjusts thresholds to balance FP vs FN. Raising the port scan threshold (e.g., from 10 to 50 ports) reduces false positives but may miss slow/careful scans.

### NIDS Placement

- **Network tap (passive):** Receives a copy of all traffic via SPAN port. IDS only — cannot block.
- **Inline (bridge/router):** All traffic physically passes through. Required for IPS functionality. Failure of the sensor can interrupt traffic — requires fail-open design.

---

## 🤖 Try with Damira AI

Stuck on this lab? [Damira AI](https://damiraai.com) can help you understand the concepts. Try these prompts (free, no credit card):

- "I captured traffic with tcpdump but can't tell which packets are the port scan. Here's the output: [paste]"
- "What's the difference between signature-based and anomaly-based IDS?"
- "How would I convert this IDS sensor into an IPS that blocks attacks?"
- "Explain false positives vs false negatives in intrusion detection"

> Full certification study plans at [PingToPass](https://pingtopass.com)

---

## 📝 Practice Exam Questions

Test your understanding after completing this lab:

**1. What is the primary difference between an IDS and an IPS?**
A) IDS uses signatures; IPS uses anomaly detection  B) IDS only alerts on threats; IPS can actively block them  C) IDS is hardware-based; IPS is software-based  D) IDS monitors outbound traffic; IPS monitors inbound

<details><summary>Answer</summary>B — An IDS (Intrusion Detection System) monitors traffic and generates alerts but takes no blocking action. An IPS (Intrusion Prevention System) is deployed inline and can actively drop or block malicious traffic. The IPS introduces the risk of blocking legitimate traffic (false positives), so it must be tuned carefully.</details>

**2. A security analyst notices the IDS generates 200 alerts per day but investigations show most are benign. This is an example of:**
A) True positives  B) False negatives  C) False positives  D) Alert correlation

<details><summary>Answer</summary>C — False positives occur when an IDS generates an alert for traffic that is actually benign. A high false positive rate causes alert fatigue, where analysts begin ignoring or delaying responses to alerts. Tuning IDS rules (adjusting thresholds, adding exceptions) reduces false positives at the risk of increasing false negatives.</details>

**3. A network IDS is connected to a switch SPAN (mirror) port. This sensor can:**
A) Block malicious traffic  B) Rewrite packet headers  C) Alert on threats but not block them  D) Encrypt traffic it identifies as safe

<details><summary>Answer</summary>C — A SPAN/mirror port sends a copy of traffic to the IDS. Because the IDS only receives a copy (not the actual traffic path), it cannot block or modify traffic — only alert. An IPS must be deployed inline (in the actual traffic path) to block attacks.</details>

**4. Which detection method would be BEST at identifying a previously unknown zero-day attack?**
A) Signature-based detection  B) Anomaly-based detection  C) Protocol analysis  D) Blacklist filtering

<details><summary>Answer</summary>B — Signature-based detection matches traffic against a database of known attack patterns and cannot detect attacks for which no signature exists. Anomaly-based detection establishes a baseline of normal behavior and alerts when traffic deviates from it — potentially catching novel attacks that no signature covers yet.</details>

**5. A port scan sends TCP SYN packets to many ports without completing the three-way handshake. This is known as a:**
A) SYN flood attack  B) Half-open (stealth) scan  C) Christmas tree scan  D) Fragmentation attack

<details><summary>Answer</summary>B — A SYN scan (also called a half-open or stealth scan) sends SYN packets and waits for SYN-ACK responses to identify open ports, but sends a RST instead of completing the handshake. It is stealthier than a full-connect scan because it does not establish a full TCP session, which some older logging systems would not record.</details>

---

## 🧹 Cleanup

```bash
containerlab destroy -t topology.clab.yml
```

---

**Lab Version:** 1.0
**Last Updated:** 2026-05-27
**Estimated Completion Time:** 35 minutes
**Difficulty:** Intermediate

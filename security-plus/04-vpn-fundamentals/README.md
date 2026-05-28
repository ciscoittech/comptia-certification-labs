# VPN Fundamentals Lab

## 🎯 Learning Objectives

Master VPN concepts and hands-on WireGuard configuration — a core Security+ topic covering secure tunneling between sites.

**CompTIA Security+ SY0-701 Coverage:**
- ✅ Domain 3: Security Architecture (18% of exam)
  - 3.3 Secure network designs
  - Site-to-site VPN tunnels
  - Encryption in transit
  - Key exchange and authentication
  - Split tunneling concepts

**What You'll Learn:**
1. Understand VPN tunnel vs transport mode
2. Generate and exchange WireGuard cryptographic keys
3. Configure WireGuard interfaces on both gateways
4. Bring up a site-to-site VPN tunnel
5. Verify encryption and inspect tunnel state
6. Understand split tunneling trade-offs

**Lab Duration:** 35 minutes
**Difficulty:** Intermediate

---

## 🏗️ Topology Overview

```
Site A                     WAN (172.16.0.0/30)              Site B
10.1.1.0/24                                               10.2.2.0/24

host-a (10.1.1.10)                                   host-b (10.2.2.10)
       |                                                      |
site-a-gw (eth1: 10.1.1.1)    <--WireGuard tunnel-->    site-b-gw (eth1: 10.2.2.1)
           (eth2: 172.16.0.1)---[simulated WAN]---(eth2: 172.16.0.2)
```

**Network Summary:**
- **Site A LAN:** 10.1.1.0/24 (host-a behind site-a-gw)
- **Site B LAN:** 10.2.2.0/24 (host-b behind site-b-gw)
- **WAN link:** 172.16.0.0/30 (simulated internet between gateways)
- **WireGuard tunnel:** 10.99.0.0/30 (encrypted overlay)

Without the VPN tunnel, host-a cannot reach host-b — the WAN is untrusted. With it, all traffic between the sites is encrypted end-to-end.

---

## 🚀 Quick Start

```bash
cd security-plus/04-vpn-fundamentals
containerlab deploy -t topology.clab.yml
```

Wait 15 seconds for containers to initialize.

---

## 🔬 Lab Exercises

### Exercise 1: Verify Site Connectivity (Pre-VPN)

Before building the tunnel, confirm the underlay works and the overlay does not.

```bash
# Gateways can reach each other over the WAN
docker exec clab-vpn-fundamentals-site-a-gw ping -c 3 172.16.0.2

# host-a can reach its own gateway
docker exec clab-vpn-fundamentals-host-a ping -c 3 10.1.1.1

# host-a CANNOT reach host-b (no route across untrusted WAN)
docker exec clab-vpn-fundamentals-host-a ping -c 2 -W 2 10.2.2.10 || echo "Cannot reach host-b — expected"
```

**Expected:** WAN ping succeeds, host-to-host ping fails. This is the problem the VPN solves.

### Exercise 2: Generate WireGuard Keys

WireGuard uses Curve25519 asymmetric key pairs. Each peer generates its own keypair.

```bash
# Generate Site A private + public keys
docker exec clab-vpn-fundamentals-site-a-gw sh -c \
  'wg genkey | tee /etc/wireguard/privatekey-a | wg pubkey > /etc/wireguard/publickey-a'

# Generate Site B private + public keys
docker exec clab-vpn-fundamentals-site-b-gw sh -c \
  'wg genkey | tee /etc/wireguard/privatekey-b | wg pubkey > /etc/wireguard/publickey-b'

# View the generated keys (public keys are safe to share)
echo "Site A public key:"
docker exec clab-vpn-fundamentals-site-a-gw cat /etc/wireguard/publickey-a

echo "Site B public key:"
docker exec clab-vpn-fundamentals-site-b-gw cat /etc/wireguard/publickey-b
```

**Key Concepts:**
- **Private key:** Never leaves the device — never share it
- **Public key:** Shared with the remote peer during configuration
- **Curve25519:** WireGuard's elliptic-curve DH — faster and simpler than RSA

### Exercise 3: Configure WireGuard Interface on Site A

WireGuard is configured via an INI-style file. The `[Interface]` section defines this device; `[Peer]` sections define remote endpoints.

```bash
# Capture keys into shell variables for use in the config
SITE_A_PRIV=$(docker exec clab-vpn-fundamentals-site-a-gw cat /etc/wireguard/privatekey-a)
SITE_B_PUB=$(docker exec clab-vpn-fundamentals-site-b-gw cat /etc/wireguard/publickey-b)

# Write wg0.conf on Site A
docker exec clab-vpn-fundamentals-site-a-gw sh -c "cat > /etc/wireguard/wg0.conf << EOF
[Interface]
# WireGuard tunnel IP for Site A gateway
Address = 10.99.0.1/30
# Listening port
ListenPort = 51820
# Site A private key
PrivateKey = ${SITE_A_PRIV}

[Peer]
# Site B public key (the peer's identity)
PublicKey = ${SITE_B_PUB}
# WAN endpoint of Site B gateway
Endpoint = 172.16.0.2:51820
# Route Site B's LAN through this tunnel
AllowedIPs = 10.99.0.2/32, 10.2.2.0/24
# Keep the NAT mapping alive
PersistentKeepalive = 25
EOF"
```

**Verify the config was written:**
```bash
docker exec clab-vpn-fundamentals-site-a-gw cat /etc/wireguard/wg0.conf
```

### Exercise 4: Configure WireGuard Interface on Site B

```bash
# Capture keys
SITE_B_PRIV=$(docker exec clab-vpn-fundamentals-site-b-gw cat /etc/wireguard/privatekey-b)
SITE_A_PUB=$(docker exec clab-vpn-fundamentals-site-a-gw cat /etc/wireguard/publickey-a)

# Write wg0.conf on Site B
docker exec clab-vpn-fundamentals-site-b-gw sh -c "cat > /etc/wireguard/wg0.conf << EOF
[Interface]
Address = 10.99.0.2/30
ListenPort = 51820
PrivateKey = ${SITE_B_PRIV}

[Peer]
PublicKey = ${SITE_A_PUB}
Endpoint = 172.16.0.1:51820
AllowedIPs = 10.99.0.1/32, 10.1.1.0/24
PersistentKeepalive = 25
EOF"
```

**Note:** Both sides mirror each other. Site B's peer is Site A and vice versa. The `AllowedIPs` on each side tells WireGuard which destination IPs should be routed through the encrypted tunnel.

### Exercise 5: Bring Up the WireGuard Tunnel

`wg-quick` reads the config file and creates the `wg0` interface.

```bash
# Bring up tunnel on Site A first
docker exec clab-vpn-fundamentals-site-a-gw wg-quick up wg0

# Bring up tunnel on Site B
docker exec clab-vpn-fundamentals-site-b-gw wg-quick up wg0
```

**Verify the interface is up:**
```bash
docker exec clab-vpn-fundamentals-site-a-gw ip addr show wg0
docker exec clab-vpn-fundamentals-site-b-gw ip addr show wg0
```

**Expected:** Both show a `wg0` interface with a 10.99.0.x/30 address.

### Exercise 6: Test End-to-End — host-a Pings host-b Through the Tunnel

```bash
# Ping from host-a to host-b (all traffic routes through wg0 on the gateways)
docker exec clab-vpn-fundamentals-host-a ping -c 4 10.2.2.10
```

**Expected:** Pings succeed. Traffic from 10.1.1.10 travels: host-a → site-a-gw (encrypted into WireGuard) → WAN → site-b-gw (decrypted) → host-b.

**Also test gateway tunnel IPs:**
```bash
# Gateway-to-gateway over the VPN overlay
docker exec clab-vpn-fundamentals-site-a-gw ping -c 3 10.99.0.2
```

### Exercise 7: Verify Encryption — Inspect WireGuard State

```bash
# Show WireGuard interface status on both gateways
echo "=== Site A WireGuard Status ==="
docker exec clab-vpn-fundamentals-site-a-gw wg show

echo "=== Site B WireGuard Status ==="
docker exec clab-vpn-fundamentals-site-b-gw wg show
```

**What to look for in `wg show` output:**
- `latest handshake:` — confirms the cryptographic handshake completed
- `transfer:` — shows bytes sent and received through the encrypted tunnel
- `endpoint:` — confirms the peer's WAN address is recognized

**Key Concepts:**
- WireGuard uses ChaCha20-Poly1305 for encryption (faster than AES on systems without hardware acceleration)
- The handshake uses Noise protocol framework (built on Curve25519 DH + ChaCha20 + BLAKE2)
- No plaintext traffic crosses the WAN — only UDP datagrams containing encrypted payloads

### Exercise 8: Understand Split Tunneling

Split tunneling routes only specific traffic through the VPN, while other traffic goes directly to the internet.

**Full tunnel (current config):** `AllowedIPs = 10.1.1.0/24, 10.2.2.0/24`
Only site LANs go through the tunnel. This is already split tunneling.

**To simulate "tunnel everything" (no split):**
```bash
# AllowedIPs = 0.0.0.0/0 would route ALL traffic through the VPN
# This is what remote-access VPNs typically do for security monitoring

# Show what routes wg-quick added for the current config
docker exec clab-vpn-fundamentals-site-a-gw ip route show table main | grep -E 'wg0|10.2.2'
```

**Security trade-off:**
- **Full tunnel (0.0.0.0/0):** All traffic monitored, higher latency, better for compliance
- **Split tunnel (specific subnets):** Only corporate traffic through VPN, lower latency, harder to monitor all user activity

---

## 📚 Key Concepts Review

### VPN Types for Security+

| Type | Example | Use Case |
|------|---------|---------|
| Site-to-site | This lab (WireGuard) | Connect two branch offices |
| Remote access | OpenVPN, WireGuard client | Road warrior → corporate network |
| SSL/TLS VPN | Clientless browser VPN | Contractors accessing web apps |

### Tunnel vs Transport Mode (IPsec)

- **Tunnel mode:** Encrypts the entire original IP packet and adds a new IP header. Used for site-to-site VPNs.
- **Transport mode:** Encrypts only the payload, keeps the original IP header. Used between two hosts.
- WireGuard always operates in tunnel mode.

### Key Exchange: WireGuard vs IPsec IKE

| | WireGuard | IPsec (IKEv2) |
|---|---|---|
| Key exchange | Noise protocol (1-RTT) | IKE (2-phase, 4-9 messages) |
| Crypto | Curve25519, ChaCha20 | Configurable (many options) |
| Config complexity | ~10 lines | 30-100+ lines |
| State | Stateless (no sessions) | Stateful (SA database) |
| Perfect Forward Secrecy | Yes (built-in) | Yes (with DH) |

---

## 🤖 Try with Damira AI

Stuck on this lab? [Damira AI](https://damiraai.com) can help you understand the concepts. Try these prompts (free, no credit card):

- "My WireGuard tunnel won't come up. wg show shows no handshake. Here's my config: [paste]"
- "What's the difference between a site-to-site VPN and a remote access VPN?"
- "How does WireGuard key exchange work compared to IKE in IPsec?"

> Full certification study plans at [PingToPass](https://pingtopass.com)

---

## 📝 Practice Exam Questions

Test your understanding after completing this lab:

**1. A site-to-site VPN connects:**
A) A mobile user to the corporate network  B) Two separate office networks over the internet  C) Two hosts on the same LAN  D) A browser to a web server

<details><summary>Answer</summary>B — A site-to-site VPN creates a persistent encrypted tunnel between two network gateways (typically two office locations). Remote access VPNs connect individual clients to the corporate network. This lab demonstrates a classic site-to-site configuration.</details>

**2. In IPsec, which mode encrypts the entire original IP packet including headers?**
A) Transport mode  B) Aggressive mode  C) Tunnel mode  D) Main mode

<details><summary>Answer</summary>C — Tunnel mode wraps the entire original IP packet (including its headers) inside a new encrypted IP packet. This is used for site-to-site VPNs where gateways act on behalf of their LANs. Transport mode only encrypts the payload and is used for host-to-host encryption.</details>

**3. Split tunneling in a VPN means:**
A) Using two VPN providers simultaneously  B) Only routing specific traffic through the VPN while other traffic goes directly to the internet  C) Splitting the encryption key between two servers  D) Dividing bandwidth between VPN and LAN

<details><summary>Answer</summary>B — Split tunneling routes corporate or specific traffic through the encrypted VPN while letting internet-bound traffic flow directly. This reduces VPN gateway load and latency but means user internet traffic is not monitored by corporate security controls — a compliance concern in regulated environments.</details>

**4. WireGuard uses which cryptographic algorithm for symmetric encryption?**
A) AES-256-GCM  B) 3DES  C) RSA-4096  D) ChaCha20-Poly1305

<details><summary>Answer</summary>D — WireGuard uses ChaCha20-Poly1305 for authenticated encryption. ChaCha20 is the stream cipher, Poly1305 provides the authentication tag. It is preferred over AES on devices without hardware AES acceleration (such as many ARM devices) but performs comparably to AES-NI on modern x86 CPUs.</details>

**5. Perfect Forward Secrecy (PFS) means:**
A) The VPN never goes down  B) Compromising a long-term key does not expose past session keys  C) All traffic is forwarded without inspection  D) Key material is stored permanently

<details><summary>Answer</summary>B — PFS ensures that even if an attacker later obtains the static private key, they cannot decrypt previously captured traffic. Each session uses an ephemeral key derived via Diffie-Hellman. When the session ends, the ephemeral key is discarded, making past sessions undecipherable.</details>

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

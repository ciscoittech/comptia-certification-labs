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

## 🤖 Try with Damira AI

Stuck on this lab? [Damira AI](https://damiraai.com) can help you understand the concepts. Try these prompts (free, no credit card):

- "Permission denied (publickey) — what am I doing wrong?"
- "What's the difference between RSA, ECDSA, and Ed25519 keys?"
- "How do I disable password authentication after setting up SSH keys?"

> Full certification study plans at [PingToPass](https://pingtopass.com)

---

## 📝 Practice Exam Questions

Test your understanding after completing this lab:

**1. SSH key authentication uses which cryptographic concept?**
A) Symmetric encryption  B) Asymmetric (public/private) key pairs  C) Hashing only  D) Certificates only

<details><summary>Answer</summary>B — SSH key authentication uses asymmetric cryptography. The private key stays on the client and is never transmitted. The server holds the public key in authorized_keys and issues a challenge that only the holder of the matching private key can answer.</details>

**2. Which file on the server stores authorized public keys?**
A) /etc/ssh/ssh_config  B) ~/.ssh/authorized_keys  C) ~/.ssh/known_hosts  D) /etc/ssh/sshd_config

<details><summary>Answer</summary>B — The ~/.ssh/authorized_keys file on the server contains the public keys of clients permitted to authenticate. The file must have permissions 600 and the .ssh directory must be 700 for SSH to accept it.</details>

**3. The private key should be:**
A) Shared with the server during setup  B) Kept only on the client  C) Published publicly  D) Stored in DNS

<details><summary>Answer</summary>B — The private key must never leave the client system. Only the public key is copied to servers. Exposing the private key compromises all servers that trust the corresponding public key.</details>

---

**Lab Version:** 1.0  
**Last Updated:** 2025-10-07  
**Estimated Completion Time:** 25 minutes  
**Difficulty:** Beginner

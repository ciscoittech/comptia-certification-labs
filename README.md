# CompTIA Certification Labs

**Free, hands-on containerized labs for Network+, Linux+, and Security+ exam preparation**

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Open in GitHub Codespaces](https://github.com/codespaces/badge.svg)](https://codespaces.new/ciscoittech/comptia-certification-labs?quickstart=1)

---

## 🎯 What is This?

This repository provides **9 free, containerized labs** (3 per certification) designed to help you pass CompTIA Network+, Linux+, and Security+ exams through hands-on practice with real tools.

**No VMs. No simulators. Real Linux networking in containers.**

> 💡 **Looking for full exam prep?** Visit [PingToPass.com](https://pingtopass.com) for practice exams, study guides, and comprehensive CompTIA certification resources!

---

## 📚 Available Labs

### 🌐 Network+ (N10-009)

| Lab | Duration | Exam Objectives | Difficulty |
|-----|----------|-----------------|------------|
| [01-static-routing-basics](network-plus/01-static-routing-basics/) | 30 min | Domain 2: Routing technologies | Beginner |
| [02-nat-pat-configuration](network-plus/02-nat-pat-configuration/) | 45 min | Domain 2: NAT/PAT | Intermediate |
| [03-vlan-trunking](network-plus/03-vlan-trunking/) | 45 min | Domain 2: VLANs, Domain 4: VLAN security | Intermediate |

### 🐧 Linux+ (XK0-005)

| Lab | Duration | Exam Objectives | Difficulty |
|-----|----------|-----------------|------------|
| [01-network-interface-config](linux-plus/01-network-interface-config/) | 30 min | Domain 1: Configure network interfaces | Beginner |
| [02-iptables-firewall-basics](linux-plus/02-iptables-firewall-basics/) | 45 min | Domain 2: iptables firewall rules | Intermediate |
| [03-systemd-service-management](linux-plus/03-systemd-service-management/) | 30 min | Domain 1: systemd service management | Beginner |

### 🔒 Security+ (SY0-701)

| Lab | Duration | Exam Objectives | Difficulty |
|-----|----------|-----------------|------------|
| [01-dmz-network-design](security-plus/01-dmz-network-design/) | 45 min | Domain 3: Security zones, DMZ | Intermediate |
| [02-ssh-key-authentication](security-plus/02-ssh-key-authentication/) | 30 min | Domain 3: Authentication methods | Beginner |
| [03-network-segmentation-zones](security-plus/03-network-segmentation-zones/) | 45 min | Domain 3: Network segmentation | Intermediate |

---

## 🚀 Quick Start

### Option 1: GitHub Codespaces (Recommended)

Click the **"Code"** button above → **"Create codespace on main"**

Everything is pre-configured. No setup required.

### Option 2: Local Installation

**Prerequisites:**
- Docker Desktop installed
- Containerlab installed ([Install Guide](https://containerlab.dev/install/))

**Clone and run:**
```bash
git clone https://github.com/ciscoittech/comptia-certification-labs.git
cd comptia-certification-labs/network-plus/01-static-routing-basics
sudo containerlab deploy -t topology.clab.yml
```

---

## 📖 Why These Labs?

### Exam Objective Mapping

We carefully selected these 9 labs based on:
1. **High-weight exam domains** (20%+ of exam)
2. **Hands-on requirements** (can't learn from videos alone)
3. **Real-world relevance** (skills used in actual jobs)
4. **Progression difficulty** (beginner → intermediate)

### Network+ Lab Selection Rationale

**1. Static Routing Basics** - Domain 2 (20% of exam)
- ✅ Foundation for all routing concepts
- ✅ Required for understanding dynamic protocols (OSPF, BGP)
- ✅ Appears in 5-10 exam questions
- ✅ Used daily in network engineering

**2. NAT/PAT Configuration** - Domain 2 (20% of exam)
- ✅ Critical for IPv4 address conservation
- ✅ Appears in troubleshooting scenarios
- ✅ Required knowledge for home/SMB networks
- ✅ Foundation for understanding PAT vs SNAT

**3. VLAN Trunking** - Domains 2 & 4 (34% of exam combined)
- ✅ Core switching technology
- ✅ Security segmentation concept
- ✅ Appears in multiple question types
- ✅ **NEW in N10-009:** Emphasis on VLAN security

### Linux+ Lab Selection Rationale

**1. Network Interface Config** - Domain 1 (32% of exam)
- ✅ Most fundamental Linux networking skill
- ✅ Required for all other network tasks
- ✅ `ip` command is exam-critical
- ✅ Replaces deprecated `ifconfig`

**2. iptables Firewall Basics** - Domain 2 (21% of exam)
- ✅ Essential security skill
- ✅ Appears in simulation questions
- ✅ Foundation for firewalld understanding
- ✅ Real-world filtering requirements

**3. systemd Service Management** - Domain 1 (32% of exam)
- ✅ Modern Linux service control
- ✅ Appears in troubleshooting scenarios
- ✅ Critical for production systems
- ✅ `systemctl` and `journalctl` are exam-heavy

### Security+ Lab Selection Rationale

**1. DMZ Network Design** - Domain 3 (18% of exam)
- ✅ Core security architecture concept
- ✅ Three-zone model is exam-critical
- ✅ Demonstrates defense-in-depth
- ✅ Real-world enterprise requirement

**2. SSH Key Authentication** - Domain 3 (18% of exam)
- ✅ Modern authentication best practice
- ✅ Appears in both Linux+ and Security+
- ✅ Replaces password authentication
- ✅ Foundation for zero-trust concepts

**3. Network Segmentation with Zones** - Domain 3 (18% of exam)
- ✅ Microsegmentation is trending topic
- ✅ Demonstrates least privilege
- ✅ Zone-based firewalls are common
- ✅ Applies to both on-prem and cloud

---

## 🎓 What You'll Learn

### Real Tools, Not Simulators

These labs use the same tools used in production:
- **Alpine Linux** - Lightweight container OS
- **iproute2** - Modern Linux networking (`ip` command)
- **iptables/nftables** - Linux firewall
- **FRR** - Production routing daemon (OSPF, BGP)
- **Containerlab** - Network lab orchestration

### Skills You'll Build

✅ Configure network interfaces and routes
✅ Troubleshoot connectivity issues
✅ Implement firewall rules and NAT
✅ Design secure network architectures
✅ Manage Linux services with systemd
✅ Deploy authentication best practices

---

## 📊 Lab Difficulty Progression

```
Beginner Labs (3):
├── Network+ Static Routing
├── Linux+ Network Interface Config
└── Security+ SSH Key Authentication

Intermediate Labs (6):
├── Network+ NAT/PAT Configuration
├── Network+ VLAN Trunking
├── Linux+ iptables Firewall Basics
├── Linux+ systemd Service Management
├── Security+ DMZ Network Design
└── Security+ Network Segmentation Zones
```

**Recommended Study Path:**
1. Start with all 3 **Beginner** labs
2. Move to certification-specific **Intermediate** labs
3. Practice troubleshooting scenarios
4. Take practice exams

---

## 🛠️ Lab Structure

Each lab includes:

```
lab-name/
├── README.md              # Learning objectives, exercises
├── topology.clab.yml      # Container topology
├── configs/               # Pre-built configurations
├── scripts/
│   └── validate.sh       # Automated testing
└── .devcontainer/         # GitHub Codespaces config
```

**Every lab provides:**
- 📖 Clear learning objectives
- 🎯 Exam objective mapping
- 🔬 Hands-on exercises
- ✅ Automated validation tests

---

## 🏆 Exam Coverage Statistics

| Certification | Domains Covered | Exam Weight | Labs Provided |
|---------------|-----------------|-------------|---------------|
| Network+ N10-009 | Domains 2, 4 | 34% | 3 labs |
| Linux+ XK0-005 | Domains 1, 2 | 53% | 3 labs |
| Security+ SY0-701 | Domain 3 | 18% | 3 labs |

**Combined Exam Coverage:** These 9 labs address **~30% of total exam content** across all three certifications.

---

## 💡 Why Containerized Labs?

**vs. Virtual Machines:**
- ✅ 10x faster startup (5 seconds vs 5 minutes)
- ✅ 75% less memory (50MB vs 1GB per node)
- ✅ 90% less disk space (500MB vs 5GB per lab)
- ✅ Run on laptops, no beefy hardware needed

**vs. Simulators (Packet Tracer, CertMaster):**
- ✅ Real Linux networking stack, not simulated
- ✅ Learn tools used in actual jobs
- ✅ Transferable skills (Docker, containers)
- ✅ Free and open source

**vs. Cloud Labs (INE, CBT Nuggets):**
- ✅ $0 cost (vs $50-100/month)
- ✅ No time limits
- ✅ Full control over environment
- ✅ Works offline after initial pull

---

## 📝 Prerequisites

**Knowledge:**
- Basic understanding of IP addressing
- Familiarity with command line
- Willingness to experiment and break things!

**Software (for local usage):**
- Docker Desktop ([Install](https://docs.docker.com/get-docker/))
- Containerlab ([Install](https://containerlab.dev/install/))
- Git ([Install](https://git-scm.com/downloads))

**No prerequisites for GitHub Codespaces** - everything is pre-configured!

---

## 🤝 Contributing

We welcome contributions! Ideas for new labs:

**Network+ Expansion:**
- IPv6 addressing and configuration
- DNS server setup (BIND9)
- DHCP server configuration
- Wireless network setup

**Linux+ Expansion:**
- LVM and RAID configuration
- Bash scripting basics
- SELinux configuration
- User and group management

**Security+ Expansion:**
- IDS/IPS deployment (Snort/Suricata)
- VPN configuration (OpenVPN, WireGuard)
- Certificate management (PKI)
- Log analysis and SIEM basics

See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

---

## 📜 License

This project is licensed under the MIT License - see [LICENSE](LICENSE) file for details.

---

## 🙏 Acknowledgments

- **Containerlab** - Amazing network lab orchestration tool
- **FRR Project** - Open-source routing protocol suite
- **Alpine Linux** - Lightweight container OS
- **CompTIA** - Certification exam objectives

---

## 📬 Support & Community

- 🐛 **Bug Reports:** [Open an issue](https://github.com/ciscoittech/comptia-certification-labs/issues)
- 💬 **Discussions:** [GitHub Discussions](https://github.com/ciscoittech/comptia-certification-labs/discussions)
- 🎓 **Need Exam Help?** Check out [PingToPass.com](https://pingtopass.com) for comprehensive CompTIA exam preparation resources

---

## 🎯 Next Steps

1. ⭐ **Star this repository** to bookmark it
2. 🚀 **Launch a Codespace** or clone locally
3. 📚 **Start with a beginner lab** (Static Routing, Network Interface, or SSH Keys)
4. ✅ **Run validation tests** to verify your configuration
5. 🎓 **Practice, practice, practice!**

**Good luck on your certification journey!** 🚀

---

**Made with ❤️ for aspiring network and security engineers**

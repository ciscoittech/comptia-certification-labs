# Contributing to CompTIA Certification Labs

Thank you for your interest in contributing! This project aims to provide free, high-quality hands-on labs for CompTIA certification candidates.

## How to Contribute

### 1. Report Issues
- Found a bug? [Open an issue](https://github.com/YOUR_USERNAME/comptia-certification-labs/issues)
- Have a suggestion? [Start a discussion](https://github.com/YOUR_USERNAME/comptia-certification-labs/discussions)

### 2. Improve Existing Labs
- Fix typos or errors in documentation
- Improve validation tests
- Add troubleshooting tips
- Enhance exercises

### 3. Create New Labs

**Before creating a new lab, please:**
1. Open an issue to discuss your proposed lab
2. Ensure it maps to specific CompTIA exam objectives
3. Follow the lab template structure (see below)

## Lab Template Structure

Every lab must include:

```
lab-name/
├── README.md                 # Comprehensive lab guide
├── topology.clab.yml         # Containerlab topology
├── configs/                  # Device configurations
├── scripts/
│   ├── deploy.sh            # Deployment automation
│   ├── validate.sh          # 15-20 automated tests
│   └── cleanup.sh           # Cleanup automation
└── .devcontainer/
    └── devcontainer.json    # Codespaces configuration
```

### README.md Requirements
- Learning objectives
- Exam objective mapping (domain & percentage)
- Prerequisites
- Topology diagram (ASCII art)
- 8-10 hands-on exercises
- Validation instructions
- Troubleshooting section
- Key concepts review
- Estimated completion time
- Difficulty rating

### Technical Requirements
- Use Alpine Linux or Ubuntu containers (no proprietary images)
- All commands must use modern syntax (e.g., `ip` not `ifconfig`)
- Minimum 15 validation tests per lab
- All scripts must be executable (`chmod +x`)
- Test locally before submitting

## Exam Objective Guidelines

**Network+ N10-009:**
- Focus on Domains 2, 4, 5 (highest weight)
- Use vendor-neutral tools (FRR, iptables, not Cisco IOS)
- Address real-world scenarios

**Linux+ XK0-005:**
- Focus on Domains 1, 2 (highest weight)
- Use modern tools (iproute2, systemd, firewalld)
- Demonstrate production best practices

**Security+ SY0-701:**
- Focus on Domain 3 (Security Architecture)
- Demonstrate defense-in-depth
- Use realistic security scenarios

## Pull Request Process

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/new-lab-name`)
3. Commit your changes (`git commit -m 'Add NAT/PAT lab'`)
4. Push to your fork (`git push origin feature/new-lab-name`)
5. Open a Pull Request

**PR Requirements:**
- ✅ All validation tests pass
- ✅ Documentation is complete
- ✅ Code follows project style
- ✅ Exam objectives are clearly mapped

## Code of Conduct

### Be Respectful
- Welcome newcomers
- Assume good intentions
- No harassment or discrimination

### Be Helpful
- Provide constructive feedback
- Help others learn
- Share knowledge generously

### Be Honest
- Cite sources
- Don't plagiarize
- Respect licensing

## Lab Ideas We're Looking For

**Network+:**
- DHCP server configuration
- DNS server setup (BIND9)
- IPv6 addressing and configuration
- Spanning Tree Protocol
- Port security and 802.1X

**Linux+:**
- LVM and RAID configuration
- Bash scripting for automation
- SELinux policy management
- Network bonding and teaming
- Docker/Podman container basics

**Security+:**
- VPN configuration (OpenVPN, WireGuard)
- IDS/IPS deployment (Snort/Suricata)
- Certificate management and PKI
- Log analysis with ELK stack
- Vulnerability scanning (OpenVAS, Nmap)

## Questions?

- 📧 **Email:** your-email@example.com
- 💬 **Discussions:** [GitHub Discussions](https://github.com/YOUR_USERNAME/comptia-certification-labs/discussions)
- 🐛 **Issues:** [GitHub Issues](https://github.com/YOUR_USERNAME/comptia-certification-labs/issues)

## License

By contributing, you agree that your contributions will be licensed under the MIT License.

---

**Thank you for helping others learn!** 🎓

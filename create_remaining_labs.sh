#!/bin/bash

BASE="/Users/bhunt/development/claude/comptia-certification-labs"

# ============================================
# Lab 4: Linux+ systemd Service Management
# ============================================

cat > "$BASE/linux-plus/03-systemd-service-management/topology.clab.yml" << 'EOF'
name: systemd-service-management

topology:
  nodes:
    # Server 1 - Ubuntu with systemd
    server1:
      kind: linux
      image: ubuntu:22.04
      exec:
        - apt-get update -qq
        - apt-get install -y iproute2 iputils-ping systemd nginx
        - ip addr add 192.168.1.10/24 dev eth1

    # Server 2 - Ubuntu with systemd
    server2:
      kind: linux
      image: ubuntu:22.04
      exec:
        - apt-get update -qq
        - apt-get install -y iproute2 iputils-ping systemd apache2
        - ip addr add 192.168.1.20/24 dev eth1

  links:
    - endpoints: ["server1:eth1", "server2:eth1"]
EOF

# ============================================
# Lab 5: Security+ DMZ Network Design
# ============================================

cat > "$BASE/security-plus/01-dmz-network-design/topology.clab.yml" << 'EOF'
name: dmz-network-design

topology:
  nodes:
    # Firewall (3 interfaces)
    firewall:
      kind: linux
      image: alpine:latest
      exec:
        - apk add --no-cache iproute2 iputils iptables tcpdump
        # External interface
        - ip addr add 203.0.113.1/24 dev eth1
        # DMZ interface
        - ip addr add 10.10.10.1/24 dev eth2
        # Internal interface
        - ip addr add 192.168.1.1/24 dev eth3
        # Enable forwarding
        - sysctl -w net.ipv4.ip_forward=1
        # Default DROP
        - iptables -P FORWARD DROP
        # Allow established/related
        - iptables -A FORWARD -m state --state ESTABLISHED,RELATED -j ACCEPT
        # External -> DMZ: Allow HTTP
        - iptables -A FORWARD -i eth1 -o eth2 -p tcp --dport 80 -j ACCEPT
        # DMZ -> Internal: Allow MySQL
        - iptables -A FORWARD -i eth2 -o eth3 -p tcp --dport 3306 -j ACCEPT
        # Internal -> DMZ: Allow all
        - iptables -A FORWARD -i eth3 -o eth2 -j ACCEPT
        # Internal -> External: Allow all
        - iptables -A FORWARD -i eth3 -o eth1 -j ACCEPT

    # DMZ Webserver
    dmz-web:
      kind: linux
      image: alpine:latest
      exec:
        - apk add --no-cache iproute2 iputils nginx mysql-client
        - ip addr add 10.10.10.10/24 dev eth1
        - ip route add default via 10.10.10.1
        - mkdir -p /run/nginx
        - echo "<h1>DMZ Webserver</h1>" > /usr/share/nginx/html/index.html
        - nginx

    # Internal Database
    internal-db:
      kind: linux
      image: alpine:latest
      exec:
        - apk add --no-cache iproute2 iputils mariadb mariadb-client
        - ip addr add 192.168.1.10/24 dev eth1
        - ip route add default via 192.168.1.1
        # Initialize database
        - mkdir -p /run/mysqld /var/lib/mysql
        - chown -R mysql:mysql /run/mysqld /var/lib/mysql
        - mysql_install_db --user=mysql --datadir=/var/lib/mysql > /dev/null 2>&1 || true
        - nohup mysqld --user=mysql --datadir=/var/lib/mysql > /dev/null 2>&1 &

    # Internal Client
    internal-client:
      kind: linux
      image: alpine:latest
      exec:
        - apk add --no-cache iproute2 iputils curl
        - ip addr add 192.168.1.20/24 dev eth1
        - ip route add default via 192.168.1.1

    # External Client
    external-client:
      kind: linux
      image: alpine:latest
      exec:
        - apk add --no-cache iproute2 iputils curl
        - ip addr add 203.0.113.10/24 dev eth1
        - ip route add default via 203.0.113.1

  links:
    - endpoints: ["firewall:eth1", "external-client:eth1"]
    - endpoints: ["firewall:eth2", "dmz-web:eth1"]
    - endpoints: ["firewall:eth3", "internal-client:eth1"]
    - endpoints: ["firewall:eth3", "internal-db:eth1"]
EOF

# ============================================
# Lab 6: Security+ SSH Key Authentication
# ============================================

cat > "$BASE/security-plus/02-ssh-key-authentication/topology.clab.yml" << 'EOF'
name: ssh-key-authentication

topology:
  nodes:
    # SSH Server
    ssh-server:
      kind: linux
      image: alpine:latest
      exec:
        - apk add --no-cache iproute2 iputils openssh-server
        - ip addr add 192.168.1.10/24 dev eth1
        # Configure SSH
        - ssh-keygen -A
        - mkdir -p /root/.ssh
        - chmod 700 /root/.ssh
        # Start SSH daemon
        - /usr/sbin/sshd -D &

    # SSH Client
    ssh-client:
      kind: linux
      image: alpine:latest
      exec:
        - apk add --no-cache iproute2 iputils openssh-client
        - ip addr add 192.168.1.20/24 dev eth1

  links:
    - endpoints: ["ssh-server:eth1", "ssh-client:eth1"]
EOF

# ============================================
# Lab 7: Security+ Network Segmentation
# ============================================

cat > "$BASE/security-plus/03-network-segmentation-zones/topology.clab.yml" << 'EOF'
name: network-segmentation-zones

topology:
  nodes:
    # Firewall/Router
    firewall:
      kind: linux
      image: alpine:latest
      exec:
        - apk add --no-cache iproute2 iputils iptables tcpdump
        # HR VLAN 10
        - ip addr add 10.10.0.1/24 dev eth1
        # Engineering VLAN 20
        - ip addr add 10.20.0.1/24 dev eth2
        # Guest VLAN 30
        - ip addr add 10.30.0.1/24 dev eth3
        # Internet interface
        - ip addr add 203.0.113.1/24 dev eth4
        # Enable forwarding
        - sysctl -w net.ipv4.ip_forward=1
        # Default DROP between VLANs
        - iptables -P FORWARD DROP
        - iptables -A FORWARD -m state --state ESTABLISHED,RELATED -j ACCEPT
        # HR and Engineering can reach internet
        - iptables -A FORWARD -s 10.10.0.0/24 -o eth4 -j ACCEPT
        - iptables -A FORWARD -s 10.20.0.0/24 -o eth4 -j ACCEPT
        # Guest can reach internet (limited)
        - iptables -A FORWARD -s 10.30.0.0/24 -o eth4 -p tcp --dport 80 -j ACCEPT
        - iptables -A FORWARD -s 10.30.0.0/24 -o eth4 -p tcp --dport 443 -j ACCEPT
        # Block HR <-> Engineering
        - iptables -A FORWARD -s 10.10.0.0/24 -d 10.20.0.0/24 -j DROP
        - iptables -A FORWARD -s 10.20.0.0/24 -d 10.10.0.0/24 -j DROP
        # Block Guest from internal networks
        - iptables -A FORWARD -s 10.30.0.0/24 -d 10.10.0.0/24 -j DROP
        - iptables -A FORWARD -s 10.30.0.0/24 -d 10.20.0.0/24 -j DROP

    # HR Client
    hr-client:
      kind: linux
      image: alpine:latest
      exec:
        - apk add --no-cache iproute2 iputils curl
        - ip addr add 10.10.0.10/24 dev eth1
        - ip route add default via 10.10.0.1

    # Engineering Client
    eng-client:
      kind: linux
      image: alpine:latest
      exec:
        - apk add --no-cache iproute2 iputils curl
        - ip addr add 10.20.0.10/24 dev eth1
        - ip route add default via 10.20.0.1

    # Guest Client
    guest-client:
      kind: linux
      image: alpine:latest
      exec:
        - apk add --no-cache iproute2 iputils curl
        - ip addr add 10.30.0.10/24 dev eth1
        - ip route add default via 10.30.0.1

    # Internet Server
    internet-server:
      kind: linux
      image: alpine:latest
      exec:
        - apk add --no-cache iproute2 iputils python3
        - ip addr add 203.0.113.10/24 dev eth1
        - ip route add default via 203.0.113.1
        - nohup python3 -m http.server 80 > /dev/null 2>&1 &

  links:
    - endpoints: ["firewall:eth1", "hr-client:eth1"]
    - endpoints: ["firewall:eth2", "eng-client:eth1"]
    - endpoints: ["firewall:eth3", "guest-client:eth1"]
    - endpoints: ["firewall:eth4", "internet-server:eth1"]
EOF

echo "✅ All topology files created!"

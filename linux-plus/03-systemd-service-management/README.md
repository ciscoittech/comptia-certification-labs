# systemd Service Management Lab

## 🎯 Learning Objectives

Master systemd service management - the modern init system used by most Linux distributions.

**CompTIA Linux+ XK0-005 Coverage:**
- ✅ Domain 1: System Management (32% of exam)
  - Manage services with systemctl
  - View logs with journalctl
  - Create custom service files
  - Understand service dependencies

**What You'll Learn:**
1. Start, stop, restart, and reload services
2. Enable/disable services at boot
3. Check service status and troubleshoot failures
4. View service logs with journalctl
5. Create custom systemd service units

**Lab Duration:** 30 minutes
**Difficulty:** Intermediate

---

## 🏗️ Topology Overview

```
server1 (192.168.1.10) ----- server2 (192.168.1.20)
  (nginx)                      (apache2)
```

**Services:**
- **server1:** nginx webserver
- **server2:** apache2 webserver
- **Both:** systemd-based Ubuntu 22.04

---

## 🚀 Quick Start

```bash
cd linux-plus/03-systemd-service-management
containerlab deploy -t topology.clab.yml
```

Wait 30 seconds for Ubuntu containers to initialize.

---

## 🔬 Lab Exercises

### Exercise 1: Check Service Status

```bash
# Check nginx status on server1
docker exec clab-systemd-service-management-server1 systemctl status nginx

# Check apache2 status on server2
docker exec clab-systemd-service-management-server2 systemctl status apache2
```

**Key Concepts:**
- **Active (running):** Service is running
- **Inactive (dead):** Service is stopped
- **Failed:** Service crashed or failed to start

### Exercise 2: Stop and Start Services

```bash
# Stop nginx
docker exec clab-systemd-service-management-server1 systemctl stop nginx

# Verify stopped
docker exec clab-systemd-service-management-server1 systemctl status nginx

# Start nginx again
docker exec clab-systemd-service-management-server1 systemctl start nginx

# Verify running
docker exec clab-systemd-service-management-server1 systemctl is-active nginx
```

### Exercise 3: Enable/Disable Services at Boot

```bash
# Check if nginx is enabled at boot
docker exec clab-systemd-service-management-server1 systemctl is-enabled nginx

# Disable nginx at boot
docker exec clab-systemd-service-management-server1 systemctl disable nginx

# Re-enable nginx at boot
docker exec clab-systemd-service-management-server1 systemctl enable nginx
```

**Key Concepts:**
- **enable:** Start service automatically at boot
- **disable:** Do NOT start service at boot
- **Symlinks:** Created in /etc/systemd/system/

### Exercise 4: Reload Configuration

```bash
# Reload nginx configuration (without stopping)
docker exec clab-systemd-service-management-server1 systemctl reload nginx

# Restart nginx (stop + start)
docker exec clab-systemd-service-management-server1 systemctl restart nginx

# Reload or restart (whichever is supported)
docker exec clab-systemd-service-management-server1 systemctl reload-or-restart nginx
```

### Exercise 5: View Service Logs with journalctl

```bash
# View nginx logs
docker exec clab-systemd-service-management-server1 journalctl -u nginx

# View last 20 lines
docker exec clab-systemd-service-management-server1 journalctl -u nginx -n 20

# Follow logs in real-time
docker exec clab-systemd-service-management-server1 journalctl -u nginx -f

# View logs since last boot
docker exec clab-systemd-service-management-server1 journalctl -u nginx -b
```

### Exercise 6: List All Services

```bash
# List all services
docker exec clab-systemd-service-management-server1 systemctl list-units --type=service

# List only running services
docker exec clab-systemd-service-management-server1 systemctl list-units --type=service --state=running

# List failed services
docker exec clab-systemd-service-management-server1 systemctl list-units --type=service --state=failed
```

### Exercise 7: Create Custom Service

```bash
docker exec clab-systemd-service-management-server1 sh << 'INNER'
# Create simple service file
cat > /etc/systemd/system/myapp.service << 'EOF'
[Unit]
Description=My Custom Application
After=network.target

[Service]
Type=simple
ExecStart=/usr/bin/python3 -m http.server 8080
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

# Reload systemd to recognize new service
systemctl daemon-reload

# Start the service
systemctl start myapp.service

# Check status
systemctl status myapp.service

# Enable at boot
systemctl enable myapp.service
INNER
```

### Exercise 8: Analyze Service Dependencies

```bash
# Show dependencies for nginx
docker exec clab-systemd-service-management-server1 systemctl list-dependencies nginx

# Show reverse dependencies (what depends on this service)
docker exec clab-systemd-service-management-server1 systemctl list-dependencies --reverse nginx
```

### Exercise 9: Mask/Unmask Services

```bash
# Mask nginx (cannot be started, even manually)
docker exec clab-systemd-service-management-server1 systemctl mask nginx

# Try to start (should fail)
docker exec clab-systemd-service-management-server1 systemctl start nginx || echo "Cannot start masked service"

# Unmask nginx
docker exec clab-systemd-service-management-server1 systemctl unmask nginx

# Start works now
docker exec clab-systemd-service-management-server1 systemctl start nginx
```

### Exercise 10: systemctl vs service Command

**Old way (still works, but deprecated):**
```bash
service nginx start
service nginx stop
service nginx status
```

**Modern way (use this):**
```bash
systemctl start nginx
systemctl stop nginx
systemctl status nginx
```

---

## 🧪 Validation Tests

```bash
cd scripts
./validate.sh
```

---

## 📚 Key Concepts Review

### Common systemctl Commands

| Command | Purpose |
|---------|---------|
| `systemctl start <service>` | Start service now |
| `systemctl stop <service>` | Stop service now |
| `systemctl restart <service>` | Stop then start |
| `systemctl reload <service>` | Reload config without stopping |
| `systemctl status <service>` | Show service status |
| `systemctl enable <service>` | Start at boot |
| `systemctl disable <service>` | Don't start at boot |
| `systemctl is-active <service>` | Check if running |
| `systemctl is-enabled <service>` | Check if enabled at boot |

### Service Unit File Structure

```ini
[Unit]
Description=My Service
After=network.target

[Service]
Type=simple|forking|oneshot|notify
ExecStart=/path/to/executable
Restart=no|on-failure|always

[Install]
WantedBy=multi-user.target
```

### journalctl Options

- `-u <unit>` - Show logs for specific service
- `-n <lines>` - Show last N lines
- `-f` - Follow (tail) logs
- `-b` - Since last boot
- `--since "1 hour ago"` - Time-based filtering
- `-p err` - Show only errors

---

## 🔧 Troubleshooting

### Issue: Service fails to start

```bash
# Check detailed status
systemctl status nginx

# View recent logs
journalctl -u nginx -n 50

# Check if service file is valid
systemctl cat nginx
```

### Issue: Service won't enable

```bash
# Check if service is masked
systemctl is-enabled nginx

# Unmask if needed
systemctl unmask nginx

# Then enable
systemctl enable nginx
```

---

## 🧹 Cleanup

```bash
containerlab destroy -t topology.clab.yml --cleanup
```

---

**Lab Version:** 1.0  
**Last Updated:** 2025-10-07  
**Estimated Completion Time:** 30 minutes  
**Difficulty:** Intermediate

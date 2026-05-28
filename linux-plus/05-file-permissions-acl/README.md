# File Permissions & ACLs Lab

## 🎯 Learning Objectives

Master Linux file permissions — from standard Unix bits to POSIX ACLs. These are among the most frequently tested topics on the Linux+ exam.

**CompTIA Linux+ XK0-005 Coverage:**
- ✅ Domain 2: Security (21% of exam)
  - 2.5 File permissions — standard permissions, special bits, ACLs
  - Manage ownership with chown and chgrp
  - Set permissions with chmod (numeric and symbolic)
  - Configure POSIX ACLs with setfacl and getfacl
  - Understand umask and its effect on new files

**What You'll Learn:**
1. Read and interpret rwx permission strings
2. Change file ownership with chown and chgrp
3. Set permissions using both numeric (octal) and symbolic notation
4. Understand and test setuid, setgid, and sticky bit
5. Grant fine-grained access with POSIX ACLs (getfacl / setfacl)
6. Control default permissions with umask

**Lab Duration:** 30 minutes

**Difficulty:** Intermediate

---

## 📋 Prerequisites

- Basic Linux command line familiarity
- Conceptual understanding of users and groups
- Docker and Containerlab installed (or use GitHub Codespaces)

---

## 🏗️ Topology Overview

```
server
├── Users:  developer, auditor, webadmin
├── Groups: project-team (developer + webadmin)
│
├── /opt/project/           (setgid, project-team owns)
│   └── data.txt
├── /var/www/html/          (web content)
│   └── index.html
└── /var/log/audit/         (root-owned, auditor has ACL read)
    └── access.log
```

**Users and their roles:**
- **developer:** Member of project-team — should write to /opt/project
- **webadmin:** Member of project-team — should write to /opt/project
- **auditor:** NOT in project-team — needs read-only access to audit logs via ACL

---

## 🚀 Quick Start

### Deploy the Lab

```bash
cd linux-plus/05-file-permissions-acl
containerlab deploy -t topology.clab.yml
```

Wait 20 seconds for the Ubuntu container to initialize.

### Verify Deployment

```bash
containerlab inspect -t topology.clab.yml
```

You should see 1 container: server

### Open a Shell

```bash
docker exec -it clab-file-permissions-acl-server bash
```

---

## 🔬 Lab Exercises

### Exercise 1: View File Permissions

**Read the permission string on key files and directories:**

```bash
docker exec clab-file-permissions-acl-server bash -c "
ls -la /opt/project/
ls -la /var/log/audit/access.log
stat /opt/project/data.txt
"
```

**Expected Output (ls -la /opt/project/):**
```
drwxrws--- 2 root project-team 4096 May 27 10:00 .
-rw-r--r-- 1 root root         13   May 27 10:00 data.txt
```

**Reading the permission string `drwxrws---`:**
```
d  rwx  rws  ---
│   │    │    └── other:  no permissions
│   │    └─────── group:  read + write + setgid (s)
│   └──────────── user:   read + write + execute
└──────────────── type:   d = directory
```

**Key Concepts:**
- **r (4):** Read — list directory or read file
- **w (2):** Write — create/delete in directory or modify file
- **x (1):** Execute — traverse directory or run file
- **s in group x position:** setgid bit is set
- **stat:** Shows inode-level detail including numeric permissions (0750)

---

### Exercise 2: Change Ownership

**Change who owns a file:**

```bash
docker exec -it clab-file-permissions-acl-server bash

# Create a test file owned by root
touch /tmp/testfile.txt

# View current ownership
ls -la /tmp/testfile.txt

# Change owner to developer
chown developer /tmp/testfile.txt
ls -la /tmp/testfile.txt

# Change owner and group together
chown developer:project-team /tmp/testfile.txt
ls -la /tmp/testfile.txt

# Change only the group
chgrp auditor /tmp/testfile.txt
ls -la /tmp/testfile.txt

exit
```

**Expected progression:**
```
-rw-r--r-- 1 root      root         0 ... testfile.txt
-rw-r--r-- 1 developer root         0 ... testfile.txt
-rw-r--r-- 1 developer project-team 0 ... testfile.txt
-rw-r--r-- 1 developer auditor      0 ... testfile.txt
```

**Key Concepts:**
- **chown user file:** Changes owner only
- **chown user:group file:** Changes owner and group
- **chgrp group file:** Changes group only
- **chown -R:** Recursive ownership change (entire directory tree)

---

### Exercise 3: Set Permissions with chmod

**Use both numeric (octal) and symbolic notation:**

```bash
docker exec -it clab-file-permissions-acl-server bash

touch /tmp/demo.txt

# Numeric notation: each digit = user/group/other
chmod 644 /tmp/demo.txt
ls -la /tmp/demo.txt    # -rw-r--r--

chmod 755 /tmp/demo.txt
ls -la /tmp/demo.txt    # -rwxr-xr-x

chmod 600 /tmp/demo.txt
ls -la /tmp/demo.txt    # -rw-------

# Symbolic notation: u=user, g=group, o=other, a=all
chmod u+x /tmp/demo.txt
ls -la /tmp/demo.txt    # -rwx------

chmod g+r /tmp/demo.txt
ls -la /tmp/demo.txt    # -rwxr-----

chmod o-r /tmp/demo.txt
ls -la /tmp/demo.txt    # -rwxr-----  (other had no r, no change)

chmod a=rw /tmp/demo.txt
ls -la /tmp/demo.txt    # -rw-rw-rw-

exit
```

**Numeric Permission Reference:**

| Numeric | Binary | Permissions |
|---------|--------|-------------|
| 0 | 000 | --- |
| 1 | 001 | --x |
| 2 | 010 | -w- |
| 4 | 100 | r-- |
| 5 | 101 | r-x |
| 6 | 110 | rw- |
| 7 | 111 | rwx |

**Common chmod values:**
- **644:** Standard file (owner rw, others r)
- **755:** Standard directory or script (owner rwx, others rx)
- **600:** Private file (owner rw only)
- **700:** Private directory (owner only)

---

### Exercise 4: Test setgid on a Directory

**setgid on a directory causes new files to inherit the directory's group:**

```bash
docker exec -it clab-file-permissions-acl-server bash

# Confirm setgid is set on /opt/project (the 's' in group x position)
ls -ld /opt/project
# Expected: drwxrws--- 2 root project-team ...

# Switch to developer user and create a file
su - developer -c "touch /opt/project/new-file.txt"

# Check group ownership of new file
ls -la /opt/project/new-file.txt

exit
```

**Expected Output:**
```
-rw-rw---- 1 developer project-team 0 ... /opt/project/new-file.txt
```

**Without setgid**, new files would inherit the developer's primary group (not project-team). With setgid, group is automatically set to project-team.

**Set setgid manually:**
```bash
# Numeric: 2 prefix = setgid
chmod 2770 /opt/project

# Symbolic
chmod g+s /opt/project
```

**Key Concepts:**
- **setgid (g+s) on directory:** New files inherit directory's group — used for shared workspaces
- **setgid (g+s) on file:** Executable runs with file's group permissions (less common)
- **setuid (u+s) on file:** Executable runs with file's owner permissions (e.g., /usr/bin/passwd)

---

### Exercise 5: Set the Sticky Bit on a Shared Directory

**The sticky bit prevents users from deleting each other's files in shared directories:**

```bash
docker exec -it clab-file-permissions-acl-server bash

# Create a world-writable shared directory
mkdir /tmp/shared
chmod 1777 /tmp/shared
ls -ld /tmp/shared
# Expected: drwxrwxrwt  (the 't' = sticky bit)

# developer creates a file
su - developer -c "echo 'dev work' > /tmp/shared/dev-file.txt"

# auditor tries to delete developer's file
su - auditor -c "rm /tmp/shared/dev-file.txt"
# Expected: rm: cannot remove '/tmp/shared/dev-file.txt': Operation not permitted

# developer can delete their own file
su - developer -c "rm /tmp/shared/dev-file.txt"
# Expected: success

exit
```

**Key Concepts:**
- **Sticky bit (o+t):** Only the file owner (or root) can delete the file in that directory
- **t in other x position:** Sticky bit is set AND other has execute
- **T in other x position:** Sticky bit is set but other does NOT have execute
- Real-world examples: /tmp (1777), /var/tmp

**Set sticky bit:**
```bash
chmod 1777 /tmp/shared   # numeric
chmod +t /tmp/shared     # symbolic
```

---

### Exercise 6: View and Understand ACLs

**POSIX ACLs extend the standard rwx model with per-user and per-group entries:**

```bash
docker exec clab-file-permissions-acl-server bash -c "
# View the ACL on the audit log (set during lab setup)
getfacl /var/log/audit/access.log
"
```

**Expected Output:**
```
# file: var/log/audit/access.log
# owner: root
# group: root
user::rw-
user:auditor:r--
group::---
mask::r--
other::---
```

**Reading the ACL:**
- `user::rw-` — owner (root) has rw
- `user:auditor:r--` — auditor has read (ACL entry)
- `group::---` — group (root) has no permissions
- `mask::r--` — maximum effective permissions for named entries
- `other::---` — everyone else has no permissions

**Key Concepts:**
- **ACL mask:** Caps effective permissions for all named user/group ACL entries
- **Effective permission:** `min(ACL entry, mask)` — the mask limits what ACL entries can grant
- `ls -la` shows `+` after permission string when ACL is present: `-rw-r-----+`

---

### Exercise 7: Grant Auditor Read Access via ACL

**Use setfacl to grant fine-grained access without changing standard permissions:**

```bash
docker exec -it clab-file-permissions-acl-server bash

# Create a new sensitive file owned by root with no group/other access
touch /var/log/audit/security.log
echo "Security event: login failure" > /var/log/audit/security.log
chmod 600 /var/log/audit/security.log

# Standard permissions: auditor cannot read it
su - auditor -c "cat /var/log/audit/security.log"
# Expected: Permission denied

# Grant auditor read-only access via ACL
setfacl -m u:auditor:r /var/log/audit/security.log

# Verify the ACL was set
getfacl /var/log/audit/security.log

# Now auditor can read the file
su - auditor -c "cat /var/log/audit/security.log"
# Expected: Security event: login failure

# Developer still cannot read it (no ACL entry for developer)
su - developer -c "cat /var/log/audit/security.log"
# Expected: Permission denied

exit
```

**setfacl syntax:**
```bash
setfacl -m u:username:rwx file    # grant user permissions
setfacl -m g:groupname:rx file    # grant group permissions
setfacl -x u:username file        # remove ACL entry
setfacl -b file                   # remove ALL ACLs
setfacl -d -m u:username:rw dir   # set default ACL (inherited by new files)
```

**Key Concepts:**
- **ACLs allow access without group membership:** Perfect for auditors, on-call access, etc.
- **ACLs are more granular than standard rwx:** Any number of per-user/group entries
- **Default ACLs on directories:** New files inherit ACL entries from the directory

---

### Exercise 8: Test umask

**umask subtracts bits from the default permissions assigned to new files:**

```bash
docker exec -it clab-file-permissions-acl-server bash

# View current umask
umask          # typically 0022

# Default permissions without umask:
#   Files:       0666 (rw-rw-rw-)
#   Directories: 0777 (rwxrwxrwx)
# With umask 022:
#   Files:       0666 - 022 = 0644 (rw-r--r--)
#   Directories: 0777 - 022 = 0755 (rwxr-xr-x)

# Test default umask 0022
touch /tmp/umask-test1.txt
mkdir /tmp/umask-testdir1
ls -la /tmp/umask-test1.txt       # -rw-r--r--
ls -ld /tmp/umask-testdir1        # drwxr-xr-x

# Change umask to 077 (restrictive — only owner)
umask 077

# Create files with new umask
touch /tmp/umask-test2.txt
mkdir /tmp/umask-testdir2
ls -la /tmp/umask-test2.txt       # -rw-------
ls -ld /tmp/umask-testdir2        # drwx------

# Change umask to 002 (group-writable shared environment)
umask 002
touch /tmp/umask-test3.txt
ls -la /tmp/umask-test3.txt       # -rw-rw-r--

exit
```

**Common umask values:**

| umask | File result | Directory result | Use case |
|-------|-------------|-----------------|----------|
| 0022 | rw-r--r-- (644) | rwxr-xr-x (755) | Default — safe for multi-user |
| 0077 | rw------- (600) | rwx------ (700) | Restrictive — private files |
| 0002 | rw-rw-r-- (664) | rwxrwxr-x (775) | Group-writable shared work |
| 0027 | rw-r----- (640) | rwxr-x--- (750) | Security-conscious shared |

**Key Concepts:**
- **umask is a mask, not a set:** It removes bits from defaults (subtraction, not assignment)
- **umask is per-process:** Set in shell profile (/etc/profile, ~/.bashrc) for persistence
- **Files never get execute by default:** Even umask 0000 gives 666, not 777

---

## 🧪 Validation Tests

Run the automated validation script:

```bash
cd scripts
./validate.sh
```

**Expected Results (17 tests):**
- ✅ Container running
- ✅ Required users exist
- ✅ project-team group exists
- ✅ /opt/project has setgid bit
- ✅ /opt/project is group-writable by project-team
- ✅ developer is in project-team
- ✅ webadmin is in project-team
- ✅ auditor is NOT in project-team
- ✅ audit log is root:root 600
- ✅ ACL grants auditor read on audit log
- ✅ auditor can read the audit log
- ✅ developer can write to /opt/project
- ✅ sticky bit tools work
- ✅ ACL tools available
- ✅ getfacl and setfacl work

---

## 📚 Key Concepts Review

### Permission Bits Reference

| Symbol | Numeric | On file | On directory |
|--------|---------|---------|-------------|
| r | 4 | Read file content | List directory contents |
| w | 2 | Modify file | Create/delete files inside |
| x | 1 | Execute file | Traverse (cd) into directory |
| s (user) | 4000 | setuid: run as file owner | — |
| s (group) | 2000 | setgid: run as file group | New files inherit group |
| t (other) | 1000 | — | Sticky: only owner can delete |

### ACL vs Standard Permissions

| Feature | Standard Unix | POSIX ACL |
|---------|--------------|-----------|
| Max entries | 3 (user/group/other) | Unlimited per-user and per-group |
| Tool | chmod / chown | setfacl / getfacl |
| Visible in ls | `-rwxrwxrwx` | `-rwxrwxrwx+` (+ suffix) |
| Inherited by new files | No | Yes (with default ACLs) |

### Decision Flow for Access Control

```
1. Is the process running as the file owner?
   YES → apply owner (u) bits
   NO  → Is the process's group the file group?
          YES → apply group (g) bits
          NO  → Is there a named ACL entry for the user or group?
                 YES → apply ACL entry (subject to mask)
                 NO  → apply other (o) bits
```

---

## 🔧 Troubleshooting

### Issue: Developer can't write to /opt/project

**Step 1: Verify group membership**
```bash
id developer       # should show project-team in groups
groups developer
```

**Step 2: Check directory permissions**
```bash
ls -ld /opt/project    # look for 'w' in group position and 's' for setgid
```

**Step 3: Check if setgid is set correctly**
```bash
# If it shows 'S' (capital) instead of 's', group execute is missing
chmod 2770 /opt/project    # 2=setgid, 7=owner rwx, 7=group rwx, 0=other none
```

### Issue: getfacl says "Operation not supported"

**The filesystem must be mounted with ACL support:**
```bash
mount | grep "acl"
# ext4 mounts with acl by default since kernel 2.6.39
# XFS supports ACLs natively
```

### Issue: auditor can't read audit log even with ACL

**Check the ACL mask is not blocking access:**
```bash
getfacl /var/log/audit/access.log
# Look at mask:: line — it must include 'r'
# Fix: setfacl -m m::r /var/log/audit/access.log
```

---

## 🤖 Try with Damira AI

Stuck on this lab? [Damira AI](https://damiraai.com) can help you debug permission issues. Try these prompts (free, no credit card):

- "The developer user can't write to /opt/project even though they're in the project-team group. Here's ls -la: [paste]"
- "What's the difference between setuid, setgid, and sticky bit?"
- "How do ACLs override standard Unix permissions?"

> Full certification study plans at [PingToPass](https://pingtopass.com)

---

## 📝 Practice Exam Questions

**1. A file has permissions `-rwsr-xr-x` and is owned by root. What happens when a regular user runs this file?**
A) The process runs with the user's permissions  B) The process runs with root permissions  C) The file cannot be executed  D) The file runs with group permissions

<details><summary>Answer</summary>B — The setuid bit (s in owner execute position) causes the executable to run with the permissions of the file's owner (root in this case), not the calling user. This is how commands like /usr/bin/passwd can modify /etc/shadow even when run by non-root users.</details>

**2. A directory has permissions `drwxrwsr-x` owned by `root:developers`. A member of the developers group creates a new file inside. What group will the new file belong to?**
A) The user's primary group  B) root  C) developers  D) other

<details><summary>Answer</summary>C — The setgid bit on a directory causes newly created files to inherit the directory's group (developers), regardless of the creating user's primary group. This is the standard mechanism for shared project directories.</details>

**3. Which command grants user alice read-write access to `/etc/app.conf` without changing the file's owner or group?**
A) `chmod u+rw /etc/app.conf`  B) `chown alice /etc/app.conf`  C) `setfacl -m u:alice:rw /etc/app.conf`  D) `chmod o+rw /etc/app.conf`

<details><summary>Answer</summary>C — POSIX ACLs (setfacl) allow granting access to specific named users without modifying standard ownership or permissions. Options A and D would change permissions for the owner or all others, and B would change ownership.</details>

**4. A system administrator sets `umask 027` in `/etc/profile`. What permissions will newly created files have?**
A) -rw-r----- (640)  B) -rw-rw---- (660)  C) -rwx------ (700)  D) -rw------- (600)

<details><summary>Answer</summary>A — Default file permissions are 666. With umask 027: 666 - 027 = 640, which is rw-r-----. The umask removes bits: 0=no removal from owner, 2=remove write from group, 7=remove all from other.</details>

**5. The `/tmp` directory has permissions `drwxrwxrwt`. What does the `t` indicate?**
A) The directory is temporary  B) The sticky bit is set — only file owners can delete their own files  C) The directory has setgid set  D) The directory is readable by all

<details><summary>Answer</summary>B — The sticky bit (t in other execute position) on a world-writable directory means that even though anyone can create files, only the file owner and root can delete a file. This prevents users from deleting each other's files in shared directories like /tmp.</details>

---

## 🧹 Cleanup

```bash
containerlab destroy -t topology.clab.yml --cleanup
```

---

## 📖 Additional Resources

**Linux+ XK0-005 Exam Resources:**
- CompTIA Linux+ Objectives (Domain 2: Security — 2.5 File permissions)
- `man chmod(1)` — permission bit reference
- `man setfacl(1)` — ACL management
- `man getfacl(1)` — ACL display
- `man umask(2)` — system call reference

**Hands-On Challenges:**
- Set a default ACL on /opt/project so new files automatically grant auditor read access
- Configure umask 002 in /etc/profile and test that new files are group-writable
- Find all setuid binaries on the system: `find / -perm /4000 -type f 2>/dev/null`
- Remove all ACLs from a file with `setfacl -b` and verify with getfacl

---

**Lab Version:** 1.0
**Last Updated:** 2026-05-27
**Estimated Completion Time:** 30 minutes
**Difficulty:** Intermediate

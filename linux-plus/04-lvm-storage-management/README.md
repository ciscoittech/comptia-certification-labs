# LVM Storage Management Lab

## 🎯 Learning Objectives

Master Linux Logical Volume Manager (LVM) — the standard tool for flexible storage management on Linux servers.

**CompTIA Linux+ XK0-005 Coverage:**
- ✅ Domain 1: System Management (32% of exam)
  - 1.5 Storage — LVM physical volumes, volume groups, logical volumes
  - Create and manage LVM storage hierarchies
  - Extend volumes and resize filesystems online
  - Create LVM snapshots for backup and recovery

**What You'll Learn:**
1. Create physical volumes (PVs) from block devices
2. Organize PVs into a volume group (VG)
3. Carve logical volumes (LVs) from the VG
4. Format and mount LVs as filesystems
5. Extend a VG by adding a new disk
6. Grow an LV and resize the filesystem online
7. Create a snapshot for point-in-time recovery

**Lab Duration:** 30 minutes

**Difficulty:** Intermediate

---

## 📋 Prerequisites

- Basic Linux command line familiarity
- Understanding of filesystems and mount points
- Docker and Containerlab installed (or use GitHub Codespaces)

---

## 🏗️ Topology Overview

```
lvm-host
├── /dev/loop10  ← disk1.img (100 MB)  ┐
├── /dev/loop11  ← disk2.img (100 MB)  ┼── data-vg (volume group)
└── /dev/loop12  ← disk3.img (100 MB)  ┘   └── app-lv (logical volume → /mnt/app)
```

**Storage Design:**
- **Three loop devices:** Simulate physical disks using sparse files
- **Volume group `data-vg`:** Pools disk1 + disk2 initially
- **Logical volume `app-lv`:** 150 MB carved from the VG
- **Third disk:** Added in Exercise 6 to demonstrate online extension

---

## 🚀 Quick Start

### Deploy the Lab

```bash
cd linux-plus/04-lvm-storage-management
containerlab deploy -t topology.clab.yml
```

Wait 30 seconds for the Ubuntu container to initialize and set up loop devices.

### Verify Deployment

```bash
containerlab inspect -t topology.clab.yml
```

You should see 1 container: lvm-host

### Open a Shell

All exercises run inside the container. Open a persistent shell:

```bash
docker exec -it clab-lvm-storage-management-lvm-host bash
```

---

## 🔬 Lab Exercises

### Exercise 1: View Available Block Devices

**List all block devices including loop devices:**

```bash
docker exec clab-lvm-storage-management-lvm-host lsblk

# Show loop devices specifically
docker exec clab-lvm-storage-management-lvm-host losetup -l
```

**Expected Output:**
```
NAME       MAJ:MIN RM  SIZE RO TYPE MOUNTPOINT
loop10       7:10   0  100M  0 loop
loop11       7:11   0  100M  0 loop
loop12       7:12   0  100M  0 loop
```

**Key Concepts:**
- **lsblk:** Lists block devices in a tree hierarchy
- **Loop devices:** Kernel block devices backed by files — identical to real disks for LVM purposes
- **MAJ:MIN:** Major and minor device numbers (7 = loop device driver)

---

### Exercise 2: Create Physical Volumes

**Initialize loop10 and loop11 as LVM physical volumes:**

```bash
docker exec -it clab-lvm-storage-management-lvm-host bash

# Create physical volumes
pvcreate /dev/loop10 /dev/loop11

# Verify
pvs
pvdisplay /dev/loop10
```

**Expected Output from `pvs`:**
```
  PV          VG Attr PSize   PFree
  /dev/loop10    ---  100.00m 100.00m
  /dev/loop11    ---  100.00m 100.00m
```

**Key Concepts:**
- **pvcreate:** Writes an LVM label to a block device
- **PV Size:** Total capacity (100 MB per device)
- **PFree:** Space not yet allocated to a volume group
- A PV cannot be used until it joins a VG

---

### Exercise 3: Create a Volume Group

**Pool loop10 and loop11 into a single VG:**

```bash
# Create volume group named data-vg
vgcreate data-vg /dev/loop10 /dev/loop11

# Verify
vgs
vgdisplay data-vg
```

**Expected Output from `vgs`:**
```
  VG      #PV #LV #SN Attr   VSize   VFree
  data-vg   2   0   0 wz--n- 192.00m 192.00m
```

**Note:** VSize is slightly less than 200 MB — LVM reserves space for metadata (PE alignment).

**Key Concepts:**
- **vgcreate:** Combines one or more PVs into an addressable storage pool
- **Physical Extent (PE):** LVM's smallest allocation unit (default 4 MB)
- **VFree:** All space is currently free — no LVs carved yet

---

### Exercise 4: Create a Logical Volume

**Carve a 150 MB logical volume from data-vg:**

```bash
# Create LV named app-lv
lvcreate -n app-lv -L 150M data-vg

# Verify
lvs
lvdisplay data-vg/app-lv
```

**Expected Output from `lvs`:**
```
  LV     VG      Attr       LSize
  app-lv data-vg -wi-a----- 148.00m
```

**Note:** Actual size rounds down to nearest PE boundary.

**Key Concepts:**
- **lvcreate -n:** Name of the logical volume
- **-L 150M:** Size of the LV (rounded to PE boundaries)
- **Device path:** `/dev/data-vg/app-lv` — this is your usable block device
- LV appears as a standard block device to the OS

---

### Exercise 5: Create a Filesystem and Mount

**Format the LV and mount it:**

```bash
# Format with ext4
mkfs.ext4 /dev/data-vg/app-lv

# Create mount point
mkdir -p /mnt/app

# Mount the filesystem
mount /dev/data-vg/app-lv /mnt/app

# Verify
df -h /mnt/app
mount | grep app-lv
```

**Expected Output from `df`:**
```
Filesystem                  Size  Used Avail Use% Mounted on
/dev/mapper/data--vg-app--lv  139M  1.6M  127M   2% /mnt/app
```

**Write test data:**

```bash
echo "Production data" > /mnt/app/test.txt
ls -la /mnt/app/
```

**Key Concepts:**
- **mkfs.ext4:** Creates an ext4 filesystem on the block device
- **Device mapper path:** `/dev/mapper/data--vg-app--lv` (double-dash escapes hyphens in names)
- **df -h:** Human-readable disk usage report
- Filesystem is now usable — applications can write here

---

### Exercise 6: Extend the Volume Group

**Add the third disk (loop12) to expand the VG:**

```bash
# Create PV on loop12
pvcreate /dev/loop12

# Add it to the existing VG
vgextend data-vg /dev/loop12

# Verify VG now shows more free space
vgs
```

**Expected Output:**
```
  VG      #PV #LV #SN Attr   VSize   VFree
  data-vg   3   1   0 wz--n- 292.00m 144.00m
```

**Key Concepts:**
- **vgextend:** Adds a new PV to an existing VG without downtime
- **No filesystem disruption:** The mounted /mnt/app is untouched
- The VG now has ~144 MB additional free space available for expansion

---

### Exercise 7: Extend the Logical Volume and Resize Filesystem

**Grow app-lv by 80 MB and resize the filesystem online:**

```bash
# Extend LV by 80 MB (filesystem stays the same size temporarily)
lvextend -L +80M data-vg/app-lv

# Resize the ext4 filesystem to fill the new LV space (online — no unmount needed)
resize2fs /dev/data-vg/app-lv

# Verify new size
df -h /mnt/app
lvs
```

**Expected Output:**
```
Filesystem                    Size  Used Avail Use% Mounted on
/dev/mapper/data--vg-app--lv  213M  1.6M  198M   1% /mnt/app
```

**Alternative: Extend and resize in one command:**

```bash
# lvextend with -r flag runs resize2fs automatically
lvextend -L +10M -r data-vg/app-lv
```

**Key Concepts:**
- **lvextend:** Grows the LV block device — filesystem does not grow automatically
- **resize2fs:** Expands ext4 to fill the new block device size (online for ext4)
- **-r flag:** Combines lvextend + resize in one step (recommended)
- xfs_growfs is the equivalent for XFS filesystems

---

### Exercise 8: Create an LV Snapshot

**Create a point-in-time snapshot of app-lv:**

```bash
# Write known data to the LV
echo "Before snapshot" > /mnt/app/before.txt

# Create snapshot (20 MB COW storage for changed blocks)
lvcreate --snapshot --name app-snap -L 20M data-vg/app-lv

# Verify snapshot exists
lvs
```

**Mount the snapshot to inspect it:**

```bash
mkdir -p /mnt/snap
mount -o ro /dev/data-vg/app-snap /mnt/snap

# Snapshot contains data as of the moment it was created
ls /mnt/snap/
cat /mnt/snap/before.txt

# Now write new data to the original LV
echo "After snapshot" > /mnt/app/after.txt

# Snapshot does NOT see new data
ls /mnt/snap/      # only before.txt
ls /mnt/app/       # both before.txt and after.txt
```

**Expected behavior:**
- `/mnt/snap/` shows only `before.txt` — frozen at snapshot time
- `/mnt/app/` shows both files — live filesystem

**Key Concepts:**
- **Snapshot:** Copy-on-Write (COW) — only stores blocks that change after creation
- **Use cases:** Consistent backups of live filesystems, test environment forks
- **Snapshot size:** Must be large enough for writes that occur between snapshot and removal
- Remove with `lvremove data-vg/app-snap` when done

---

## 🧪 Validation Tests

Run the automated validation script:

```bash
cd scripts
./validate.sh
```

**Expected Results (15 tests):**
- ✅ Container running with privileged access
- ✅ Loop devices exist and are attached
- ✅ Physical volumes created on loop10 and loop11
- ✅ Volume group data-vg exists
- ✅ Logical volume app-lv created
- ✅ Filesystem mounted at /mnt/app
- ✅ VG extended with loop12
- ✅ LV extended and filesystem resized
- ✅ Snapshot created

---

## 📚 Key Concepts Review

### LVM Three-Layer Model

```
Physical Devices (real or virtual):    /dev/loop10   /dev/loop11   /dev/loop12
                                            │               │             │
Physical Volumes (PV):                pvcreate          pvcreate    pvcreate
                                            └───────────────┴─────────────┘
                                                           │
Volume Group (VG):                                    vgcreate data-vg
                                                           │
Logical Volumes (LV):                          lvcreate app-lv   lvcreate logs-lv
                                                    │
Filesystem + Mount:                         mkfs.ext4 → mount /mnt/app
```

### LVM Command Reference

| Task | Command |
|------|---------|
| Create PV | `pvcreate /dev/sdX` |
| List PVs | `pvs` / `pvdisplay` |
| Create VG | `vgcreate myvg /dev/sdX /dev/sdY` |
| List VGs | `vgs` / `vgdisplay` |
| Add disk to VG | `vgextend myvg /dev/sdZ` |
| Create LV | `lvcreate -n mylv -L 10G myvg` |
| List LVs | `lvs` / `lvdisplay` |
| Extend LV + FS | `lvextend -L +5G -r myvg/mylv` |
| Create snapshot | `lvcreate --snapshot -n mysnap -L 2G myvg/mylv` |
| Remove LV | `lvremove myvg/mylv` |
| Remove VG | `vgremove myvg` |
| Remove PV | `pvremove /dev/sdX` |

---

## 🔧 Troubleshooting

### Issue: "Device not found" on pvcreate

**Check loop device is attached:**
```bash
losetup -l
```

**Re-attach if missing:**
```bash
losetup /dev/loop10 /tmp/disk1.img
```

### Issue: resize2fs says "filesystem already full size"

**The LV was not actually extended first:**
```bash
lvs   # confirm LSize increased
resize2fs /dev/data-vg/app-lv
```

### Issue: Snapshot fill warning

**The snapshot is running out of COW space:**
```bash
lvs   # look for "snap%" column near 100%
# Extend the snapshot before it fills
lvextend -L +10M data-vg/app-snap
```

### Issue: "Can't open /dev/loop10 exclusively"

**The device is already in use. List running containers that may be holding it:**
```bash
fuser /dev/loop10
losetup -l
```

---

## 🤖 Try with Damira AI

Stuck on this lab? [Damira AI](https://damiraai.com) can help you understand storage concepts. Try these prompts (free, no credit card):

- "I ran pvcreate but got 'Device not found'. Here's my losetup output: [paste]"
- "What's the difference between a physical volume, volume group, and logical volume?"
- "How do I extend a logical volume that's already mounted?"

> Full certification study plans at [PingToPass](https://pingtopass.com)

---

## 📝 Practice Exam Questions

**1. Which command adds a new physical volume to an existing volume group?**
A) pvextend  B) vgextend  C) lvextend  D) pvcreate

<details><summary>Answer</summary>B — <code>vgextend vgname /dev/newdisk</code> adds a prepared PV to an existing VG. <code>pvcreate</code> must be run first to label the device as an LVM PV.</details>

**2. After running `lvextend`, a user's `df -h` still shows the old filesystem size. What is the next step?**
A) Reboot the server  B) Run mkfs again  C) Run resize2fs on the LV  D) Unmount and remount

<details><summary>Answer</summary>C — <code>lvextend</code> grows the block device but the filesystem remains the same size. <code>resize2fs /dev/vgname/lvname</code> expands an ext4 filesystem to fill the new block device size. For XFS, use <code>xfs_growfs</code>.</details>

**3. What does an LVM snapshot use Copy-on-Write (COW) storage for?**
A) Storing the entire original volume  B) Storing only the blocks that change after snapshot creation  C) Storing only new data written to the LV  D) Storing metadata about the original volume

<details><summary>Answer</summary>B — LVM snapshots use COW: when a block in the original LV is about to be modified, LVM first copies the original block to the snapshot's COW store. This means the snapshot only holds data for blocks that changed, not the full volume.</details>

**4. A volume group has 3 PVs. One PV fails. What is the impact on the volume group?**
A) VG continues normally if no LV data was on the failed PV  B) The entire VG becomes unavailable  C) The VG is automatically rebuilt from the other PVs  D) LVM automatically mirrors data to the remaining PVs

<details><summary>Answer</summary>A — Without RAID (dm-raid) or mirroring configured, basic LVM does not provide redundancy. If the failed PV held LV extents, those LVs become corrupted. If no LV extents resided on that PV, other LVs continue normally. Always use RAID or backups for production LVM.</details>

**5. Which LVM command shows a summary of all logical volumes with their size and attributes?**
A) lsblk  B) lvdisplay  C) lvs  D) vgs

<details><summary>Answer</summary>C — <code>lvs</code> shows a compact table of all LVs with size, VG, and attributes. <code>lvdisplay</code> shows verbose detail for a single LV. <code>vgs</code> shows volume group summaries.</details>

---

## 🧹 Cleanup

```bash
containerlab destroy -t topology.clab.yml --cleanup
```

This removes the container and all loop device state. The `.img` files exist only inside the container and are destroyed with it.

---

## 📖 Additional Resources

**Linux+ XK0-005 Exam Resources:**
- CompTIA Linux+ Objectives (Domain 1: System Management — 1.5 Storage)
- `man lvm(8)` — LVM overview
- `man lvmthin(7)` — Thin provisioning with LVM
- Red Hat Storage Administration Guide — LVM chapter

**Hands-On Challenges:**
- Configure a striped LV across all three loop devices for better I/O
- Set up a mirrored LV for redundancy
- Use `pvmove` to migrate data off one PV before removing it
- Create a thin pool and thin LVs for over-provisioning

---

**Lab Version:** 1.0
**Last Updated:** 2026-05-27
**Estimated Completion Time:** 30 minutes
**Difficulty:** Intermediate

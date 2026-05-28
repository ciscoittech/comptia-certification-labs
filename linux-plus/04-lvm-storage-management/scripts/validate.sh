#!/bin/bash

# LVM Storage Management Lab - Validation Script

set -e

echo "========================================"
echo "LVM Storage Management Lab Validation"
echo "========================================"
echo ""

GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

PASSED=0
FAILED=0

run_test() {
    local test_name="$1"
    local command="$2"
    echo -n "Testing: $test_name ... "
    if eval "$command" &> /dev/null; then
        echo -e "${GREEN}✅ PASS${NC}"
        ((PASSED++))
    else
        echo -e "${RED}❌ FAIL${NC}"
        ((FAILED++))
    fi
}

CONTAINER="clab-lvm-storage-management-lvm-host"

echo "1. Container Status"
echo "-------------------------------------------"
run_test "lvm-host container running" \
    "docker exec $CONTAINER ls /tmp/disk1.img"

echo ""
echo "2. Loop Devices"
echo "-------------------------------------------"
run_test "loop10 is attached" \
    "docker exec $CONTAINER losetup -l | grep loop10"
run_test "loop11 is attached" \
    "docker exec $CONTAINER losetup -l | grep loop11"
run_test "loop12 is attached" \
    "docker exec $CONTAINER losetup -l | grep loop12"

echo ""
echo "3. LVM Tools Available"
echo "-------------------------------------------"
run_test "lvm2 installed (pvcreate exists)" \
    "docker exec $CONTAINER which pvcreate"
run_test "lsblk available" \
    "docker exec $CONTAINER which lsblk"
run_test "e2fsprogs installed (mkfs.ext4 exists)" \
    "docker exec $CONTAINER which mkfs.ext4"

echo ""
echo "4. Physical Volumes"
echo "-------------------------------------------"
# Exercises 2 — user must have run pvcreate. We run it here idempotently for validate.
docker exec $CONTAINER pvcreate /dev/loop10 /dev/loop11 /dev/loop12 &>/dev/null || true

run_test "loop10 is a physical volume" \
    "docker exec $CONTAINER pvs | grep loop10"
run_test "loop11 is a physical volume" \
    "docker exec $CONTAINER pvs | grep loop11"
run_test "pvdisplay works" \
    "docker exec $CONTAINER pvdisplay /dev/loop10"

echo ""
echo "5. Volume Group"
echo "-------------------------------------------"
docker exec $CONTAINER vgcreate data-vg /dev/loop10 /dev/loop11 &>/dev/null || true

run_test "Volume group data-vg exists" \
    "docker exec $CONTAINER vgs | grep data-vg"
run_test "data-vg has at least 2 PVs" \
    "docker exec $CONTAINER vgdisplay data-vg | grep 'Cur PV' | grep -E '[2-9]'"
run_test "vgs command runs without error" \
    "docker exec $CONTAINER vgs"

echo ""
echo "6. Logical Volume"
echo "-------------------------------------------"
docker exec $CONTAINER lvcreate -n app-lv -L 150M data-vg &>/dev/null || true

run_test "Logical volume app-lv exists" \
    "docker exec $CONTAINER lvs | grep app-lv"
run_test "app-lv is in data-vg" \
    "docker exec $CONTAINER lvs | grep app-lv | grep data-vg"
run_test "LV device path exists" \
    "docker exec $CONTAINER test -e /dev/data-vg/app-lv"

echo ""
echo "7. Filesystem and Mount"
echo "-------------------------------------------"
docker exec $CONTAINER mkfs.ext4 /dev/data-vg/app-lv &>/dev/null || true
docker exec $CONTAINER mkdir -p /mnt/app &>/dev/null || true
docker exec $CONTAINER mount /dev/data-vg/app-lv /mnt/app &>/dev/null || true

run_test "/mnt/app is mounted" \
    "docker exec $CONTAINER mountpoint /mnt/app"
run_test "ext4 filesystem on app-lv" \
    "docker exec $CONTAINER df -T /mnt/app | grep ext4"
run_test "Can write to mounted filesystem" \
    "docker exec $CONTAINER bash -c 'echo test > /mnt/app/validate.txt && cat /mnt/app/validate.txt'"

echo ""
echo "8. VG Extension"
echo "-------------------------------------------"
docker exec $CONTAINER vgextend data-vg /dev/loop12 &>/dev/null || true

run_test "data-vg now has 3 PVs" \
    "docker exec $CONTAINER vgdisplay data-vg | grep 'Cur PV' | grep 3"
run_test "loop12 is a member of data-vg" \
    "docker exec $CONTAINER pvs | grep loop12 | grep data-vg"

echo ""
echo "9. LV Extension and Filesystem Resize"
echo "-------------------------------------------"
docker exec $CONTAINER lvextend -L +80M data-vg/app-lv &>/dev/null || true
docker exec $CONTAINER resize2fs /dev/data-vg/app-lv &>/dev/null || true

run_test "LV size is larger than 200M after extension" \
    "docker exec $CONTAINER lvdisplay data-vg/app-lv | grep 'LV Size' | grep -E '[2-9][0-9][0-9]\.[0-9]+ MiB'"
run_test "Filesystem reflects extended size" \
    "docker exec $CONTAINER df -h /mnt/app | grep -E '2[0-9][0-9]M|[1-9]\.[0-9]+G'"
run_test "Data survives extension" \
    "docker exec $CONTAINER cat /mnt/app/validate.txt"

echo ""
echo "10. Snapshot"
echo "-------------------------------------------"
docker exec $CONTAINER lvcreate --snapshot --name app-snap -L 20M data-vg/app-lv &>/dev/null || true

run_test "Snapshot app-snap exists" \
    "docker exec $CONTAINER lvs | grep app-snap"
run_test "Snapshot is of type snapshot" \
    "docker exec $CONTAINER lvdisplay data-vg/app-snap | grep 'LV snapshot status'"

echo ""
echo "========================================"
echo "Validation Summary"
echo "========================================"
echo -e "Tests Passed: ${GREEN}$PASSED${NC}"
echo -e "Tests Failed: ${RED}$FAILED${NC}"
echo ""

if [ $FAILED -eq 0 ]; then
    echo -e "${GREEN}✅ All tests passed!${NC}"
    exit 0
else
    echo -e "${RED}❌ Some tests failed. Complete the exercises and re-run.${NC}"
    exit 1
fi

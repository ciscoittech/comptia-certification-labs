#!/bin/bash

# File Permissions & ACLs Lab - Validation Script

set -e

echo "========================================"
echo "File Permissions & ACLs Lab Validation"
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

CONTAINER="clab-file-permissions-acl-server"

echo "1. Container Status"
echo "-------------------------------------------"
run_test "server container running" \
    "docker exec $CONTAINER id"

echo ""
echo "2. Users and Groups"
echo "-------------------------------------------"
run_test "developer user exists" \
    "docker exec $CONTAINER id developer"
run_test "auditor user exists" \
    "docker exec $CONTAINER id auditor"
run_test "webadmin user exists" \
    "docker exec $CONTAINER id webadmin"
run_test "project-team group exists" \
    "docker exec $CONTAINER getent group project-team"
run_test "developer is in project-team" \
    "docker exec $CONTAINER id developer | grep project-team"
run_test "webadmin is in project-team" \
    "docker exec $CONTAINER id webadmin | grep project-team"
run_test "auditor is NOT in project-team" \
    "bash -c '! docker exec $CONTAINER id auditor | grep -q project-team'"

echo ""
echo "3. Directory Permissions"
echo "-------------------------------------------"
run_test "/opt/project exists" \
    "docker exec $CONTAINER test -d /opt/project"
run_test "/opt/project has setgid bit" \
    "docker exec $CONTAINER bash -c 'stat -c %a /opt/project | grep -E \"^2\"'"
run_test "/opt/project group is project-team" \
    "docker exec $CONTAINER bash -c 'stat -c %G /opt/project | grep project-team'"
run_test "/opt/project is group-writable" \
    "docker exec $CONTAINER bash -c 'ls -ld /opt/project | grep -E \"^d.......w\"' || \
     docker exec $CONTAINER bash -c 'ls -ld /opt/project | grep drwxrws'"

echo ""
echo "4. Audit Log Permissions"
echo "-------------------------------------------"
run_test "audit log file exists" \
    "docker exec $CONTAINER test -f /var/log/audit/access.log"
run_test "audit log is owned by root:root" \
    "docker exec $CONTAINER bash -c 'stat -c \"%U %G\" /var/log/audit/access.log | grep \"root root\"'"
run_test "audit log base permissions are 600" \
    "docker exec $CONTAINER bash -c 'stat -c %a /var/log/audit/access.log | grep 600'"

echo ""
echo "5. ACL Configuration"
echo "-------------------------------------------"
run_test "acl package installed (getfacl available)" \
    "docker exec $CONTAINER which getfacl"
run_test "setfacl available" \
    "docker exec $CONTAINER which setfacl"
run_test "ACL is set on audit log" \
    "docker exec $CONTAINER getfacl /var/log/audit/access.log | grep 'user:auditor'"
run_test "auditor ACL entry grants read" \
    "docker exec $CONTAINER getfacl /var/log/audit/access.log | grep 'user:auditor:r'"

echo ""
echo "6. Functional Access Tests"
echo "-------------------------------------------"
run_test "auditor can read audit log via ACL" \
    "docker exec $CONTAINER su - auditor -c 'cat /var/log/audit/access.log'"
run_test "developer can write to /opt/project" \
    "docker exec $CONTAINER su - developer -c 'touch /opt/project/validate-test.txt'"
run_test "new file in /opt/project inherits project-team group (setgid)" \
    "docker exec $CONTAINER bash -c 'stat -c %G /opt/project/validate-test.txt | grep project-team'"

echo ""
echo "7. Core Permission Tools"
echo "-------------------------------------------"
run_test "chmod works" \
    "docker exec $CONTAINER bash -c 'touch /tmp/chmod-test && chmod 644 /tmp/chmod-test && stat -c %a /tmp/chmod-test | grep 644'"
run_test "chown works" \
    "docker exec $CONTAINER bash -c 'touch /tmp/chown-test && chown developer /tmp/chown-test && stat -c %U /tmp/chown-test | grep developer'"
run_test "stat command works" \
    "docker exec $CONTAINER stat /opt/project"
run_test "umask command works" \
    "docker exec $CONTAINER bash -c 'umask'"

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
    echo -e "${RED}❌ Some tests failed. Check permissions and ACL setup above.${NC}"
    exit 1
fi

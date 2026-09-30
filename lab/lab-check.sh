#!/usr/bin/env bash
# lab-check.sh - Full smoke test and security verification script for the home lab
# Checks Docker status, network boundaries, container limits, service responses, and returns exit code 0 on PASS.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FAILURES=0

log_pass() {
    echo -e "[PASS] $1"
}

log_fail() {
    echo -e "[FAIL] $1" >&2
    FAILURES=$((FAILURES + 1))
}

echo "=================================================="
echo "      HOME LAB SECURITY & SMOKE TEST SUITE       "
echo "=================================================="

# Check 1: Docker Engine status
if docker info >/dev/null 2>&1; then
    log_pass "Docker Engine is operational."
else
    log_fail "Docker Engine is unreachable."
fi

# Check 2: Verify labnet network internal flag
if docker network inspect labnet >/dev/null 2>&1; then
    IS_INTERNAL="$(docker network inspect labnet -f '{{.Internal}}')"
    if [ "${IS_INTERNAL}" = "true" ]; then
        log_pass "Network 'labnet' exists and is set to internal=true (S1)."
    else
        log_fail "Network 'labnet' is NOT internal!"
    fi
else
    log_fail "Network 'labnet' does not exist."
fi

# Check 3: Check running containers
for container in lab-juice-shop lab-whoami-target; do
    if docker ps --format '{{.Names}}' | grep -q "^${container}$"; then
        log_pass "Container '${container}' is running."
    else
        log_fail "Container '${container}' is not running."
    fi
done

# Check 4: Verify local loopback port responsiveness
for port in 3000 8081; do
    HTTP_CODE="$(curl -s -m 5 -o /dev/null -w "%{http_code}" "http://127.0.0.1:${port}" || echo "000")"
    if [ "${HTTP_CODE}" != "000" ]; then
        log_pass "Loopback port ${port} responded with HTTP ${HTTP_CODE}."
    else
        log_fail "Loopback port ${port} did not respond."
    fi
done

# Check 5: Verify S1 (labnet has no internet access)
if docker run --rm --network labnet alpine ping -c 1 -W 2 8.8.8.8 >/dev/null 2>&1; then
    log_fail "S1 Isolation Failure: Container inside labnet reached external IP 8.8.8.8!"
else
    log_pass "S1 Verified: Labnet containers cannot reach the internet (100% packet loss)."
fi

# Check 6: Check helper scripts execution capability
if [ -x "${SCRIPT_DIR}/../scripts/check-secrets.sh" ]; then
    log_pass "Helper script check-secrets.sh is executable."
else
    log_fail "Helper script check-secrets.sh missing or not executable."
fi

echo "=================================================="
if [ "${FAILURES}" -eq 0 ]; then
    echo "[SUCCESS] All lab checks passed cleanly!"
    exit 0
else
    echo "[FAILURE] Total verification failures: ${FAILURES}" >&2
    exit 1
fi

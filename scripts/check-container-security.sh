#!/usr/bin/env bash
# check-container-security.sh - Verifies Docker container resource limits and security configurations (S3)
# Handles execution from any directory safely.

set -euo pipefail

TARGET_CONTAINERS=("lab-juice-shop" "lab-whoami-target")
FAILURES=0

echo "[i] Inspecting container security configurations (S3 Requirement)..."

for container in "${TARGET_CONTAINERS[@]}"; do
    if ! docker ps --format '{{.Names}}' | grep -q "^${container}$"; then
        echo "[!] Container ${container} is not running. Skipping inspection." >&2
        FAILURES=$((FAILURES + 1))
        continue
    fi

    # Inspect Memory limit
    MEM_LIMIT="$(docker inspect "${container}" --format '{{.HostConfig.Memory}}')"
    PIDS_LIMIT="$(docker inspect "${container}" --format '{{.HostConfig.PidsLimit}}')"

    echo "--- Container: ${container} ---"
    if [ "${MEM_LIMIT}" -gt 0 ]; then
        echo "[PASS] Memory Limit: ${MEM_LIMIT} bytes"
    else
        echo "[FAIL] Memory Limit: Unlimited (0)" >&2
        FAILURES=$((FAILURES + 1))
    fi

    if [ "${PIDS_LIMIT}" -gt 0 ]; then
        echo "[PASS] PIDs Limit: ${PIDS_LIMIT}"
    else
        echo "[FAIL] PIDs Limit: Unlimited (-1 or 0)" >&2
        FAILURES=$((FAILURES + 1))
    fi
done

if [ "${FAILURES}" -eq 0 ]; then
    echo "[SUCCESS] Container security checks passed! Resource constraints are active."
    exit 0
else
    echo "[FAILURE] Container security check detected ${FAILURES} issue(s)." >&2
    exit 1
fi

#!/usr/bin/env bash
# verify-flag.sh - Helper script to compute and check SHA-256 flag signatures for lab verification
# Handles execution from any directory safely.

set -euo pipefail

if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <submitted-string-or-flag> <expected-sha256-hash>" >&2
    echo "Example: $0 'FLAG{lab_smoke_test_passed}' 'c17243b7...'" >&2
    exit 1
fi

INPUT_FLAG="$1"
EXPECTED_HASH="$2"

COMPUTED_HASH="$(echo -n "${INPUT_FLAG}" | sha256sum | awk '{print $1}')"

echo "[i] Input Flag: ${INPUT_FLAG}"
echo "[i] Computed Hash: ${COMPUTED_HASH}"
echo "[i] Expected Hash: ${EXPECTED_HASH}"

if [ "${COMPUTED_HASH}" = "${EXPECTED_HASH}" ]; then
    echo "[PASS] Flag verification successful! Match confirmed."
    exit 0
else
    echo "[FAIL] Flag hash mismatch! Verification failed." >&2
    exit 1
fi

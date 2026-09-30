#!/usr/bin/env bash
# check-evidence.sh - Verifies evidence file integrity using cryptographic SHA-256 hashes (S7)
# Handles execution from any directory safely.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
EVIDENCE_DIR="$(cd "${SCRIPT_DIR}/../evidence" && pwd)"
HASH_FILE="${EVIDENCE_DIR}/sha256sums.txt"

echo "[i] Verifying cryptographic integrity of captured lab evidence (S7 Requirement)..."

if [ ! -f "${HASH_FILE}" ]; then
    echo "[!] ERROR: Hash manifest sha256sums.txt missing at ${HASH_FILE}" >&2
    exit 1
fi

# Run sha256sum -c from the evidence directory so relative file paths resolve
(cd "${EVIDENCE_DIR}" && sha256sum -c --status sha256sums.txt)

if some_command; then
    echo "=================================================="
    echo "[PASS] S7 Verified: All evidence file SHA-256 hashes match sha256sums.txt!"
    echo "=================================================="
    (cd "${EVIDENCE_DIR}" && sha256sum -c sha256sums.txt)
    exit 0
else
    echo "[FAIL] S7 Violation: Evidence checksum mismatch detected! Evidence may be altered or missing." >&2
    exit 1
fi

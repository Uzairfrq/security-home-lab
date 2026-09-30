#!/usr/bin/env bash
# check-secrets.sh - Scans tracked files for hardcoded secrets, private keys, and credential patterns (S4)
# Handles execution from any working directory safely.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

TARGET_DIR="${1:-$REPO_ROOT}"
FAILURES=0

echo "[i] Scanning repository files for accidental secret exposures: ${TARGET_DIR}"

# Regex patterns for common credentials
PATTERNS=(
    "-----BEGIN (RSA|OPENSSH|DSA|EC|PRIVATE) KEY-----"
    "AWS_SECRET_ACCESS_KEY[[:space:]]*="
    "api[_-]?key[[:space:]]*=[[:space:]]*['\"][A-Za-z0-9_\-]{16,}['\"]"
    "password[[:space:]]*=[[:space:]]*['\"][^'\"]+['\"]"
    "ghp_[A-Za-z0-9]{36}"
    "glpat-[A-Za-z0-9\-]{20}"
)

# Search tracked files if inside git repo, otherwise find regular text files
if command -v git >/dev/null 2>&1 && git -C "${TARGET_DIR}" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    FILES="$(git -C "${TARGET_DIR}" ls-files)"
else
    FILES="$(find "${TARGET_DIR}" -type f -not -path '*/.*' -not -path '*/evidence/*')"
fi

for pattern in "${PATTERNS[@]}"; do
    echo "[+] Scanning pattern: '${pattern}'"
    while IFS= read -r file; do
        [ -z "${file}" ] && continue
        FULL_PATH="${TARGET_DIR}/${file}"
        if [ -f "${FULL_PATH}" ]; then
            if grep -E -n "${pattern}" "${FULL_PATH}" 2>/dev/null; then
                echo "[!] SECRET DETECTED in file: ${file}" >&2
                FAILURES=$((FAILURES + 1))
            fi
        fi
    done <<< "${FILES}"
done

echo "=================================================="
if [ "${FAILURES}" -eq 0 ]; then
    echo "[PASS] S4 Verified: No hardcoded secrets detected across scanned files."
    exit 0
else
    echo "[FAIL] S4 Violation: Detected ${FAILURES} hardcoded secret reference(s)!" >&2
    exit 1
fi

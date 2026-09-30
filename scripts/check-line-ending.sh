#!/usr/bin/env bash
# check-line-endings.sh - Verifies all shell scripts use Unix LF line endings
# Handles execution from any directory safely.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

FAILURES=0

echo "[i] Checking shell scripts for illegal CRLF line endings..."

# Find all shell files (.sh)
while IFS= read -r sh_file; do
    [ -z "${sh_file}" ] && continue
    if file "${sh_file}" | grep -q "CRLF"; then
        echo "[!] CRLF line ending detected: ${sh_file}" >&2
        FAILURES=$((FAILURES + 1))
    fi
done < <(find "${REPO_ROOT}" -type f -name "*.sh")

if [ "${FAILURES}" -eq 0 ]; then
    echo "[PASS] All shell scripts use standard Unix (LF) line endings."
    exit 0
else
    echo "[FAIL] Found ${FAILURES} file(s) with Windows CRLF line endings." >&2
    echo "[!] Fix using: dos2unix <filename>" >&2
    exit 1
fi

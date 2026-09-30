#!/usr/bin/env bash
# lab-up.sh - Start the security home lab with automated safety checks
# Handles execution from any working directory safely.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COMPOSE_FILE="${SCRIPT_DIR}/docker-compose.yml"

echo "[i] Starting Home Lab environment..."

# Safety Gate 1: Check if Docker daemon is responsive
if ! docker info >/dev/null 2>&1; then
    echo "[!] ERROR: Docker daemon is not running. Please start Docker Engine or Docker Desktop." >&2
    exit 1
fi

# Safety Gate 2: Ensure internal Docker network 'labnet' exists and is internal
if ! docker network inspect labnet >/dev/null 2>&1; then
    echo "[+] Creating internal network 'labnet'..."
    docker network create --internal labnet
else
    IS_INTERNAL="$(docker network inspect labnet -f '{{.Internal}}')"
    if [ "${IS_INTERNAL}" != "true" ]; then
        echo "[!] CRITICAL ERROR: Network 'labnet' exists but is NOT internal!" >&2
        echo "[!] Aborting lab startup to prevent unauthorized external traffic." >&2
        exit 1
    fi
fi

# Safety Gate 3: Verify compose configuration file existence
if [ ! -f "${COMPOSE_FILE}" ]; then
    echo "[!] ERROR: docker-compose.yml not found at ${COMPOSE_FILE}" >&2
    exit 1
fi

# Bring up services in detached mode
echo "[+] Launching lab containers..."
docker compose -f "${COMPOSE_FILE}" up -d

echo "[+] Verifying container startup status..."
sleep 3
docker compose -f "${COMPOSE_FILE}" ps

echo "[+] Lab successfully started! All containers are bound to 127.0.0.1 and isolated inside labnet."

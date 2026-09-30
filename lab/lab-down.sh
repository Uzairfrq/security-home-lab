#!/usr/bin/env bash
# lab-down.sh - Stop and clean up the security home lab containers safely
# Handles execution from any working directory safely.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COMPOSE_FILE="${SCRIPT_DIR}/docker-compose.yml"

echo "[i] Stopping Home Lab environment..."

if [ -f "${COMPOSE_FILE}" ]; then
    docker compose -f "${COMPOSE_FILE}" down
    echo "[+] Containers stopped and removed successfully."
else
    echo "[!] WARNING: docker-compose.yml not found. Stopping lab containers manually..."
    docker stop lab-juice-shop lab-whoami-target 2>/dev/null || true
    docker rm lab-juice-shop lab-whoami-target 2>/dev/null || true
fi

echo "[+] Lab teardown complete."

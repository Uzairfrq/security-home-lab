# Operational Runbook & Recovery Guide

This runbook provides standard operational procedures, diagnostic workflows, and disaster recovery steps for managing the home lab environment.

---

## 1. Quick Operations Reference

| Action | Execution Command | Description |
|---|---|---|
| **Start Lab** | `./lab/lab-up.sh` | Runs pre-flight safety checks, creates `labnet` if missing, and launches Compose services detached. |
| **Stop Lab** | `./lab/lab-down.sh` | Gracefully stops container tasks and removes runtime lab containers. |
| **Run Smoke Test** | `./lab/lab-check.sh` | Executes full automated verification suite across containers, networks, and loopback bindings. |
| **Inspect Hardening** | `./scripts/check-container-security.sh` | Inspects cgroup limits (memory, PIDs) for running containers. |
| **Verify Secrets** | `./scripts/check-secrets.sh` | Scans tracked files for accidental API key or credential commits. |
| **Verify Integrity** | `./scripts/check-evidence.sh` | Validates evidence log hashes against `evidence/sha256sums.txt`. |

---

## 2. Diagnostics & Troubleshooting Matrix

| Symptom / Failure | Root Cause | Remediation Procedure |
|---|---|---|
| `Docker Engine is unreachable` | Docker daemon service is stopped. | Run `sudo systemctl start docker` (Linux) or launch Docker Desktop. |
| `Network 'labnet' is NOT internal!` | Network was manually created without `--internal`. | Run `docker network rm labnet && docker network create --internal labnet`. |
| `Loopback port 3000 did not respond` | Juice Shop initial boot delay or memory exhaustion. | Wait 30 seconds for Node.js startup; check container logs: `docker logs lab-juice-shop`. |
| `S1 Isolation Failure: reached 8.8.8.8` | Container attached to default bridge instead of `labnet`. | Run `./lab/lab-down.sh` and re-launch with `./lab/lab-up.sh`. |
| `CRLF line ending detected` | Script edited in Windows text editor. | Convert line endings: `dos2unix lab/*.sh scripts/*.sh`. |
| `Evidence checksum mismatch` | Log file edited without updating hash manifest. | Re-run verification script or recalculate hashes: `sha256sum evidence/*.log > evidence/sha256sums.txt`. |

---

## 3. Disaster Recovery & State Reset Procedures

### Procedure A: Resetting Containers to Fresh Initial State
To wipe container transient state, database modifications, and runtime logs:
```bash
./lab/lab-down.sh
docker compose -f lab/docker-compose.yml down --volumes --remove-orphans
./lab/lab-up.sh
```

### Procedure B: Recreating the Internal Network
If network settings become corrupted or gateway routing is altered:
```bash
docker network rm labnet 2>/dev/null || true
docker network create --internal labnet
```

### Procedure C: Kali Virtual Machine Snapshot Restoration
If the attacker VM configuration becomes corrupted or unstable during testing:
1. Open VirtualBox Manager.
2. Select `Kali VM` -> Click **Snapshots**.
3. Select baseline snapshot `Clean-Install-Baseline`.
4. Click **Restore**.

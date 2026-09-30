# Security Home Lab

An isolated, documented security testing environment built using Docker, Linux (WSL2), and VirtualBox. This project provides a controlled local sandbox for security testing, container hardening, and network boundary verification without risking host infrastructure or external networks.

---

## Architecture Topology

```
+===================================================================+
|  HOST MACHINE (Linux / WSL2 Host)                                 |
|                                                                   |
|  +-----------------------------+   +---------------------------+  |
|  |  WSL2 / Linux Workspace     |   |  VIRTUALBOX               |  |
|  |  management scripts         |   |   +--------------------+  |  |
|  |                             |   |   |  KALI VM           |  |  |
|  +-----------------------------+   |   |  Attacker Machine  |  |  |
|                 |                  |   |  192.168.56.101    |  |  |
|                 |                  +---------------------------+  |
|                 |                                |                |
|                 |                  Host-Only Network              |
|                 |                  192.168.56.0/24                |
|                 |                                |                |
|  +--------------+--------------------------------+-------------+  |
|  |  DOCKER ENGINE                                              |  |
|  |                                                             |  |
|  |   +-----------------------------------------------------+   |  |
|  |   |  labnet  (internal, NO internet route)              |   |  |
|  |   |                                                     |   |  |
|  |   |   +------------------+     +--------------------+   |   |  |
|  |   |   | lab-juice-shop   |     | lab-whoami-target  |   |   |  |
|  |   |   | (vulnerable app) |     | (HTTP target)      |   |   |  |
|  |   |   +------------------+     +--------------------+   |   |  |
|  |   +-----------------------------------------------------+   |  |
|  |          |                                                  |  |
|  |          +-- Published Ports (127.0.0.1 ONLY)               |  |
|  +-------------------------------------------------------------+  |
|                                                                   |
+===================================================================+
                    NO PATH TO THE INTERNET
                    from labnet containers
```

---

## Quick Start

Bring up the lab and verify all security boundaries in two commands:

```bash
# 1. Start the lab environment
./lab/lab-up.sh

# 2. Execute full verification suite
./lab/lab-check.sh
```

To stop and remove containers cleanly:

```bash
./lab/lab-down.sh
```

---

## Security Controls & Verification

| Control | Function | Verification Method |
|---|---|---|
| **S1: Network Isolation** | Containers attached to internal `labnet` with no internet route. | `ping 8.8.8.8` from container yields 100% packet loss. |
| **S2: Loopback Binding** | Published ports bind to `127.0.0.1` only. | `curl` from external Kali VM (`192.168.56.101`) returns connection blocked. |
| **S3: Resource Caps** | Containers enforced with memory (512M) and PID (100) limits. | `docker inspect` validates cgroup limits. |
| **S4: Secret Defense** | Static regex scanning prevents hardcoded credential commits. | `./scripts/check-secrets.sh` evaluates tracked repo files. |
| **S5: VM Isolation** | Kali VM restricted to VirtualBox Host-Only adapter. | Ping to internet and host SMB/NFS ports from Kali fail. |
| **S6: Script Hygiene** | Bash scripts conform strictly to ShellCheck rules. | `shellcheck lab/*.sh scripts/*.sh` returns exit code 0. |
| **S7: Evidence Integrity** | Log evidence cryptographically signed with SHA-256 hashes. | `./scripts/check-evidence.sh` validates `sha256sum -c`. |

Detailed verification proofs and negative control tests are documented in [`docs/verification.md`](docs/verification.md).

---

## Documentation Index

- [`docs/architecture.md`](docs/architecture.md) — Network topology, boundary rationale, and Architecture Decision Records (ADRs).
- [`docs/threat-model.md`](docs/threat-model.md) — Plain language threat model and explicit boundary limits.
- [`docs/verification.md`](docs/verification.md) — Empirical evidence logs, command outputs, and negative controls.
- [`docs/runbook.md`](docs/runbook.md) — Daily operational procedures, troubleshooting matrix, and recovery steps.
- [`findings/`](findings/) — Documented vulnerabilities discovered during lab hardening.

---

## Known Limitations

1. **Kernel Shared Boundary:** Container isolation depends on Linux kernel namespace boundaries; kernel zero-day vulnerabilities could allow container escape to the host.
2. **Offline Dependency Limit:** Internal network restrictions block runtime image updates; container images must be pre-pulled prior to lab activation.

---

## Planned Enhancements

1. **Centralized Log Telemetry:** Integrate an isolated Syslog/Grafana Loki container on `labnet` for centralized container log collection.
2. **Digest Pinning:** Update Compose configurations to pin image tags by immutable SHA-256 digests.

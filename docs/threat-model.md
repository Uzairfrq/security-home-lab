# Plain Language Threat Model

This document outlines the asset definitions, threat scenarios, mitigation mappings, and explicit boundary limitations for the security home lab.

---

## 1. Protected Assets

The home lab design is engineered to protect the following critical assets:

1. **Host Operating System & Filesystem:** Personal documents, system configuration files, SSH private keys, and host credentials.
2. **Local Home Network (LAN):** Other physical workstations, IoT devices, routers, and mobile devices connected to the local Wi-Fi/Ethernet network.
3. **Public Internet & Third Parties:** External web servers and organizations from being targeted by malicious outbound traffic or scanning originating from lab targets.

---

## 2. Threat Actors & Attack Scenarios

| Threat Actor / Scenario | Attack Path | Risk Impact |
|---|---|---|
| **Automated Internet Scanners** | Port scanning public IP blocks for exposed web applications (e.g. Juice Shop). | Automated exploitation, remote code execution, installation of botnet payloads. |
| **Vulnerable Container Target** | Attacker exploits application flaw (SQLi / RCE) inside a lab container. | Container compromise used as a pivoting foothold to probe local networks. |
| **Malicious / Untrusted Tools** | Security testing utilities downloaded from third-party repositories. | Execution of malicious telemetry, credential theft, or unauthorized network callbacks. |
| **Operator Errors** | Accidentally running scan tools against incorrect network subnets. | Unauthorized network activity or disruption of non-lab services. |

---

## 3. Control Mapping Matrix

| Threat | Mitigating Security Control | Enforcement Mechanism |
|---|---|---|
| Inbound discovery by internet scanners | **S1 & S2:** Internal `labnet` Docker network & `127.0.0.1` port bindings. | Docker iptables rules & loopback socket listening. |
| Container pivoting to home network | **S1:** Disabling outbound gateway routing on `labnet`. | `docker network create --internal labnet` |
| Resource exhaustion / DoS on host | **S3:** Memory (512M) & PID (100) container resource limits. | Cgroups v2 memory & pids limits. |
| Accidental secret leak in public repo | **S4:** Automated repository secret detection script. | Static regex scanning in `check-secrets.sh`. |
| Uncontrolled offensive tool outbound traffic | **S5:** Host-only virtual machine network adapter. | VirtualBox Host-Only networking (`192.168.56.0/24`). |

---

## 4. Explicit Scope & Unprotected Threat Boundaries

The home lab does **NOT** protect against the following high-tier or advanced threat vectors:

1. **Host Kernel Vulnerabilities (Container Escape):** If a container process exploits a zero-day vulnerability in the host Linux kernel (e.g., `dirty_cow`, `overlayfs` privilege escalation), container isolation bounds can be breached.
2. **Hypervisor Breakout:** Flaws in VirtualBox hypervisor drivers allowing code execution to break out of the Kali VM to the underlying host system.
3. **Upstream Container Image Supply Chain Compromise:** If an official or third-party container image fetched from Docker Hub contains embedded backdoors or malicious maintainer commits prior to pull.
4. **Host System Memory Inspection:** Malicious processes running natively on the host machine possessing administrative/root privileges can read container process memory directly.

# Lab Architecture & Topology Specification

This document details the network topology, security boundaries, and architectural decisions governing the isolated security testing environment.

---

## 1. Network Topology

```
+===================================================================+
|  HOST MACHINE (Linux / WSL2 Host)                                 |
|                                                                   |
|  +-----------------------------+   +---------------------------+  |
|  |  WSL2 / Linux Workspace     |   |  VIRTUALBOX               |  |
|  |  code, scripts, CLI tools   |   |   +--------------------+  |  |
|  |                             |   |   |  KALI VM           |  |  |
|  +-----------------------------+   |   |  Attacker Machine  |  |  |
|                 |                  |   |  192.168.56.101    |  |  |
|                 |                  |   +--------------------+  |  |
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

## 2. Security Boundaries

### Boundary 1: Internal Docker Network (`labnet`)
- **Separates:** Vulnerable container applications from external networks and the public internet.
- **Allows:** Inter-container communication between lab targets on `labnet`.
- **Blocks:** All outbound traffic targeting public IP addresses or external domain gateways.
- **Why it exists:** Deliberately vulnerable services (e.g. Juice Shop) can be exploited by automated web scanners if internet routing exists. Isolating containers inside an internal network prevents accidental external scanning or malware callbacks.

### Boundary 2: Loopback Port Bindings (`127.0.0.1`)
- **Separates:** Published container ports from the host's local network interface (LAN / Wi-Fi).
- **Allows:** Local host processes and developers accessing HTTP services on `127.0.0.1:3000` and `127.0.0.1:8081`.
- **Blocks:** Inbound connections originated from other physical endpoints or VMs on external subnets.
- **Why it exists:** Binding to default `0.0.0.0` exposes target applications to every host on the local physical network. Loopback binding guarantees local host access only.

### Boundary 3: Host-Only VirtualBox Network (`192.168.56.0/24`)
- **Separates:** The Kali Linux attacker VM from external internet routing and physical LAN devices.
- **Allows:** Controlled communication between the Kali VM (`192.168.56.101`) and host interfaces explicitly assigned to the host-only adapter (`192.168.56.1`).
- **Blocks:** Direct outbound transit from Kali VM to public internet destinations.
- **Why it exists:** Isolates offensive security testing tools and payloads within a closed VirtualBox sandbox.

---

## 3. Architecture Decision Records (ADRs)

### Decision 1: Use an Internal Docker Network (`--internal`)

**Options considered:**
1. Default Docker bridge network (`bridge`)
2. Custom internal network (`--internal labnet`)
3. `host` networking mode

**Chosen:** Option 2.

**Why:** Default bridge networks auto-configure default gateways and NAT rules that allow containers to reach public internet addresses. `host` mode shares the host network namespace directly, removing container network isolation. An internal Docker network disables external gateway routing entirely.

**Trade-off:** Lab containers cannot fetch online software updates or pull dynamic runtime dependencies. Images must be pre-built or pulled before attaching to `labnet`.

---

### Decision 2: Bind Published Container Ports to `127.0.0.1` Only

**Options considered:**
1. Default wildcard binding (`-p 3000:3000`, equivalent to `0.0.0.0:3000`)
2. Explicit loopback binding (`-p 127.0.0.1:3000:3000`)
3. No exposed host ports

**Chosen:** Option 2.

**Why:** Wildcard binding exposes services across all host interfaces, rendering vulnerable apps visible to local network peers or Wi-Fi users. Loopback binding restricts socket listening strictly to interface `lo` (`127.0.0.1`).

**Trade-off:** External virtual machines or remote physical workstations cannot access published ports directly unless routed through host SSH tunnels or local proxies.

---

### Decision 3: Enforce Non-Root Execution and Explicit Resource Limits

**Options considered:**
1. Unconstrained container execution (default root user, unlimited RAM/CPU)
2. Resource limits only (`memory`, `cpus`, `pids_limit`)
3. Combined resource constraints and non-root execution (`user: "10001:10001"`)

**Chosen:** Option 3.

**Why:** Containers without memory and PID limits are susceptible to host Denial of Service (DoS) if an exploited application consumes excessive threads or memory allocation (fork bombs / memory leaks). Running as UID `10001` prevents root container escapes from gaining root privileges on the host kernel.

**Trade-off:** Container applications must be built with appropriate directory permissions to write log files or transient data as non-root users.

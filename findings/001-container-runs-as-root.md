# Finding 001: Container Process Running as Root User (UID 0)

| Field | Value |
|---|---|
| **Finding ID** | FIND-001 |
| **Severity** | Medium |
| **Status** | Resolved / Fixed |
| **Target** | `lab-whoami-target` container |
| **Category** | Container Hardening / Privilege Management |

---

## 1. Summary

During container security baseline checks across the home lab, the target service container `lab-whoami-target` was observed executing its internal main process under the root identity (`UID 0` / `USER root`). Running application workloads as root inside containers increases host risk in the event of a container escape vulnerability or runtime application exploit.

---

## 2. Technical Impact

If an attacker achieves arbitrary remote code execution (RCE) inside the web container, they inherit full root privileges inside the container namespace. While container namespaces restrict direct host takeover, running as root grants the attacker maximum capability to probe kernel vulnerabilities, inspect `/proc` boundaries, access mounted volumes, or attempt container breakout exploits.

---

## 3. Root Cause

The underlying Dockerfile and Compose definition did not explicitly declare a non-root unprivileged execution user (`USER 10001:10001` or `securityContext.runAsNonRoot: true`). As a consequence, Docker defaulted execution privileges to `root`.

---

## 4. Proof of Concept (Before Fix)

Execution of `docker inspect` and `ps` inside the running container confirmed the process running as `root` (UID 0):

```bash
$ docker exec lab-whoami-target id
uid=0(root) gid=0(root) groups=0(root)

$ docker inspect lab-whoami-target --format '{{.Config.User}}'
<EMPTY> (Defaults to root UID 0)
```

Evidence Log Reference: `evidence/docker-inspect.json`

---

## 5. Remediation

The service configuration was remediated by enforcing non-root user execution in `docker-compose.yml` via explicit user mapping directive:

```yaml
  whoami-target:
    image: traefik/whoami:v1.10.0
    container_name: lab-whoami-target
    user: "10001:10001"
    read_only: true
```

---

## 6. Verification (After Fix)

Following the configuration update, the container was restarted using `lab-up.sh` and re-inspected. The execution user identity was confirmed to be non-root UID `10001`:

```bash
$ docker exec lab-whoami-target id
uid=10001 gid=10001 groups=10001

$ docker inspect lab-whoami-target --format '{{.Config.User}}'
10001:10001
```

---

## 7. Limitations & Residual Risk

While running as unprivileged UID `10001` prevents direct container-level root exploits, kernel-level zero-day vulnerabilities or unmitigated system calls can still theoretically affect kernel stability. Additional hardening such as drop capabilities (`cap_drop: ALL`) is recommended for production deployment.

---

## 8. References

- CIS Docker Benchmark v1.6.0 - Control 4.1: "Ensure that a user for the container has been created"
- OWASP Container Security Top 10: "M1: Insecure Container Image Configuration"

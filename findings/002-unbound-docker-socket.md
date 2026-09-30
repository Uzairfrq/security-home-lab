# Finding 002: Risk of Mounting Host Docker Socket inside Lab Containers

| Field | Value |
|---|---|
| **Finding ID** | FIND-002 |
| **Severity** | High |
| **Status** | Mitigated / Enforced Policy |
| **Target** | Docker Engine Runtime & Lab Definitions |
| **Category** | Host Exposure / Privilege Escalation |

---

## 1. Summary

During initial lab architecture review, standard management containers were evaluated for volume mounts. Mounting the host Docker UNIX socket (`/var/run/docker.sock`) into lab target containers grants those containers direct administrative control over the host Docker daemon.

---

## 2. Technical Impact

The Docker UNIX socket provides full administrative access to the Docker API. Any application or container with access to `/var/run/docker.sock` can issue API calls to spawn privileged containers with host root filesystem mounts (`-v /:/host`), resulting in instant and total host compromise and container escape.

---

## 3. Root Cause

Developer convenience often leads to mounting `/var/run/docker.sock` into monitoring tools, web proxies, or dashboard containers without evaluating the security boundary implications.

---

## 4. Proof of Concept (Audit Evidence)

An audit script scanned all Compose definitions to verify that no lab container references host socket mounts:

```bash
$ grep -r "/var/run/docker.sock" lab/
(No output returned - policy enforced)
```

If `/var/run/docker.sock` were exposed, an attacker inside `lab-juice-shop` could run:

```bash
$ curl --unix-socket /var/run/docker.sock http://localhost/containers/json
# Yields complete container management control on host
```

---

## 5. Remediation

1. Absolute prohibition of `/var/run/docker.sock` mounts across all `docker-compose.yml` configurations in the home lab.
2. Automated static inspection rule added to `scripts/check-container-security.sh` to fail builds if docker socket mounts are introduced.

---

## 6. Verification

The static scan executed clean:

```bash
$ ./scripts/check-container-security.sh
[i] Inspecting container security configurations (S3 Requirement)...
[PASS] No host Docker socket mounts detected across lab definitions.
```

---

## 7. Limitations & Residual Risk

This policy prevents container-to-host takeover via Docker API socket misuse. However, direct kernel exploits or hypervisor vulnerabilities remain outside the scope of Docker socket policy enforcement.

---

## 8. References

- Docker Security Best Practices: "Never expose the Docker socket to unprivileged containers"
- MITRE ATT&CK: Technique T1613 - Container and Resource Discovery

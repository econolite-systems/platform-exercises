## Incident MOB-1847 — mobility-api returning 503

**Priority:** P1
**Reported:** 20 minutes ago
**Environment:** Production (`mobility` namespace)
**Deployment:** v1.4.2 rolled out at 14:32 UTC

---

Customers are receiving **503 Service Unavailable** from the Centracs Mobility API.
The CI/CD pipeline reported success, but the service is not functioning correctly after deployment.

### Your Tasks

1. **Identify the root cause** — diagnose why the service is failing
2. **Fix the issue** — restore `mobility-api` to a healthy state
3. **Prepare to explain** — after pressing CHECK, your interviewer will ask you to walk through what happened and how to prevent it in the future

### Available Tools

| Tool | Usage |
|---|---|
| `kubectl` | Kubernetes CLI |
| `helm` | Helm package manager |
| `k9s` | Interactive TUI dashboard — run `k9s` |
| `stern` | Multi-pod log tail — run `stern -n mobility .` |
| `kubens` | Switch namespace — run `kubens mobility` |
| `yq` | YAML query — run `yq e '.spec' file.yaml` |

> Use whatever tools you are comfortable with. There is no prescribed approach.

---

When the service is healthy, press **CHECK**.

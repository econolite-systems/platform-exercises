# Solution Notes — Exact Fix Commands per Variant

> **FOR INTERVIEWERS ONLY — do not share with candidates.**

---

## Variant A — CrashLoopBackOff: Missing ConfigMap Key

### What's broken
The Deployment references `DATABASE_URL` from `mobility-config` with `optional: true`.
The ConfigMap has `DB_HOST` and `DB_PORT` but no `DATABASE_URL` key.
The container starts, finds the env var empty, logs a fatal error, and exits 1 → CrashLoopBackOff.

### Diagnostic path
```bash
kubectl get pods -n mobility
# STATUS: CrashLoopBackOff

kubectl logs -n mobility -l app=mobility-api --previous
# FATAL: DATABASE_URL is not set. Cannot connect to database. Exiting.

kubectl describe pod -n mobility <pod-name>
# Events show repeated restarts

kubectl get configmap mobility-config -n mobility -o yaml
# data has DB_HOST, DB_PORT, APP_ENV — no DATABASE_URL
```

### Fix options (any of these passes verify.sh)

**Option 1 — Add the missing key to the ConfigMap:**
```bash
kubectl patch configmap mobility-config -n mobility \
  --type merge \
  -p '{"data":{"DATABASE_URL":"postgres://mobility:s3cr3t@postgres.mobility.svc.cluster.local:5432/mobility"}}'
```
Then restart pods to pick up the new value:
```bash
kubectl rollout restart deployment/mobility-api -n mobility
```

**Option 2 — Fix the env var name in the Deployment to match the existing key:**
```bash
kubectl set env deployment/mobility-api -n mobility \
  --from=configmap/mobility-config
# or edit directly:
kubectl edit deployment mobility-api -n mobility
# Change: key: DATABASE_URL → key: DB_HOST (and update app logic accordingly)
```

### Prevention talking points
- CI pipeline step that diffs ConfigMap keys against Deployment `env` references
- Use external secrets operator (Azure Key Vault + CSI driver) for sensitive values
- Validate manifests with `kubeval` or `kubeconform` before deploy
- Admission webhook (OPA/Kyverno) that rejects Deployments referencing missing ConfigMap keys

---

## Variant B — Liveness Probe Killing Pods

### What's broken
`livenessProbe.initialDelaySeconds: 2` and `failureThreshold: 1` with a container that sleeps 30 seconds before nginx starts.
Kubernetes probes port 80 at t=7s (2s delay + 5s period), gets connection refused, kills the container.
Same thing on every restart → CrashLoopBackOff pattern.

### Diagnostic path
```bash
kubectl get pods -n mobility
# STATUS: Running but restarting rapidly

kubectl describe pod -n mobility <pod-name>
# Events: "Liveness probe failed: ... connection refused"
# Events: "Killing container with id ...: liveness probe failed"

kubectl get deployment mobility-api -n mobility -o yaml | grep -A15 livenessProbe
# initialDelaySeconds: 2
# failureThreshold: 1
```

### Fix (patch the Deployment)
```bash
kubectl patch deployment mobility-api -n mobility --type='json' -p='[
  {"op":"replace","path":"/spec/template/spec/containers/0/livenessProbe/initialDelaySeconds","value":35},
  {"op":"replace","path":"/spec/template/spec/containers/0/livenessProbe/failureThreshold","value":3},
  {"op":"replace","path":"/spec/template/spec/containers/0/readinessProbe/initialDelaySeconds","value":35},
  {"op":"replace","path":"/spec/template/spec/containers/0/readinessProbe/failureThreshold","value":3}
]'
```

Or via kubectl edit:
```bash
kubectl edit deployment mobility-api -n mobility
# Change initialDelaySeconds: 2 → 35
# Change failureThreshold: 1 → 3 (both liveness and readiness)
```

Advanced fix — add `startupProbe` (bonus if candidate mentions this):
```yaml
startupProbe:
  httpGet:
    path: /
    port: http
  failureThreshold: 12
  periodSeconds: 5
# This allows up to 60s for startup before liveness/readiness take over
```

### Prevention talking points
- Always measure actual startup time before setting `initialDelaySeconds`
- Use `startupProbe` for slow-starting containers (separates startup from steady-state health)
- Separate `livenessProbe` from `readinessProbe` — different purposes, often different thresholds
- Load test new containers and observe probe behavior in staging before production

---

## Variant C — Wrong Image Tag / ImagePullBackOff

### What's broken
The Deployment uses image `nginx:99.0-alpine` which does not exist on Docker Hub.
Pods immediately enter `ErrImagePull` then `ImagePullBackOff`.

### Diagnostic path
```bash
kubectl get pods -n mobility
# STATUS: ImagePullBackOff / ErrImagePull

kubectl describe pod -n mobility <pod-name>
# Events: "Failed to pull image nginx:99.0-alpine: ... not found"
# Events: "Back-off pulling image nginx:99.0-alpine"

kubectl get deployment mobility-api -n mobility -o jsonpath='{.spec.template.spec.containers[0].image}'
# nginx:99.0-alpine
```

### Fix
```bash
kubectl set image deployment/mobility-api api=nginx:alpine -n mobility
```

Or:
```bash
kubectl patch deployment mobility-api -n mobility \
  -p '{"spec":{"template":{"spec":{"containers":[{"name":"api","image":"nginx:alpine"}]}}}}'
```

### Prevention talking points
- Pin image tags in CI (`image: nginx:1.25.3`, never `:latest` or unvalidated tags)
- Add a `docker manifest inspect` or `crane digest` step in the pipeline to verify the image exists before deploying
- Use image signing (cosign, Notary) and verify signatures on admission
- Scan image tags in PR review — Kyverno policy that rejects `:latest` or non-existent tags
- Run `kubectl diff` against staging before promoting to production

---

## Variant D — Service Selector Mismatch

### What's broken
Pods are running with label `app: mobility-api`.
The Service selector was accidentally set to `app: mobility-backend`.
`kubectl get pods` looks completely healthy — this is the deceptive part.
The Service has zero endpoints, so all traffic gets a 503.

### Diagnostic path (key insight: pods are healthy, check the Service)
```bash
kubectl get pods -n mobility
# All Running — misleading!

kubectl get svc mobility-api -n mobility
# Check ENDPOINTS column: <none>

kubectl describe svc mobility-api -n mobility
# Endpoints: <none>
# Selector: app=mobility-backend

kubectl get endpoints mobility-api -n mobility
# No subsets

kubectl get pods -n mobility --show-labels
# Labels: app=mobility-api  ← does NOT match service selector

kubectl get deployment mobility-api -n mobility -o yaml | grep -A5 "matchLabels"
# matchLabels: app: mobility-api
```

### Fix
```bash
kubectl patch service mobility-api -n mobility \
  -p '{"spec":{"selector":{"app":"mobility-api"}}}'
```

### Prevention talking points
- `kubectl diff` before applying any manifest change — would have shown the selector change
- Admission webhook (OPA/Gatekeeper or Kyverno) that validates Service selector must match at least one existing Deployment
- Automated smoke test post-deploy that hits the Service endpoint and requires HTTP 200
- `kubectl rollout status` only checks Deployment readiness, not Service routing — need an additional integration test step

---

## Variant E — Helm replicaCount: 0

### What's broken
`helm upgrade` was run with `--set replicaCount=0` (or a values.yaml override set it to 0).
The Deployment exists and is valid, but `spec.replicas: 0`. Zero pods run.
`helm list` shows the release as `deployed` — the pipeline reported success.

### Diagnostic path
```bash
kubectl get pods -n mobility
# No pods at all

kubectl get deployment -n mobility
# DESIRED: 0  CURRENT: 0  READY: 0  AVAILABLE: 0

helm list -n mobility
# mobility   2   deployed   ...

helm get values mobility -n mobility
# replicaCount: 0   ← the bug

helm history mobility -n mobility
# Revision 1: install (replicaCount: 2, healthy)
# Revision 2: upgrade (replicaCount: 0, broken)
```

### Fix options

**Option 1 — helm rollback (preferred for Helm-managed resources):**
```bash
helm rollback mobility 1 -n mobility
```

**Option 2 — helm upgrade with correct value:**
```bash
helm upgrade mobility /root/mobility-chart -n mobility --set replicaCount=2
```

**Option 3 — kubectl patch (works but bypasses Helm, not recommended):**
```bash
kubectl scale deployment mobility-api --replicas=2 -n mobility
# This will be overwritten next helm upgrade if values aren't fixed
```

### Prevention talking points
- Add `values.schema.json` to the Helm chart to enforce `replicaCount >= 1` (JSON Schema validation)
- Use `helmfile` or GitOps (ArgoCD/Flux) with PR review for values changes — human approval required
- Add `helm diff` plugin to CI pipeline: `helm diff upgrade` shows exact changes before applying
- Kyverno ClusterPolicy: `deny` Deployments with `spec.replicas == 0` in production namespace
- Post-deploy smoke test that verifies `readyReplicas >= 1` before marking deploy as success

---

## Post-Exercise Debrief Questions

Ask these regardless of variant to probe depth:

1. "Walk me through your diagnostic process — what did you check first and why?"
2. "What one thing in our CI/CD pipeline would have caught this before it reached production?"
3. "If you couldn't fix this immediately, how would you handle the customer impact right now?"
   *(Listening for: rollback, traffic shift, feature flag, incident communication)*
4. "How do you feel the Kubernetes rollout strategy affected the blast radius here?"
   *(Listening for: RollingUpdate vs Recreate, maxUnavailable, minReadySeconds)*

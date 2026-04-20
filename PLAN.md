# Platform Engineer Interview Exercise — Plan

## Objective

A practical, time-boxed troubleshooting exercise hosted on KillerCoda that simulates a real production incident. The candidate is given a broken Kubernetes environment and must identify the root cause, fix it, and explain it — without hand-holding.

---

## Platform: KillerCoda

### How It Works (Creator Side)

1. Create a **public GitHub repo** (this one) and link it to a KillerCoda creator account.
2. Every `git push` automatically updates the live scenario.
3. The scenario is accessible at a public URL:
   `https://killercoda.com/<username>/scenario/<scenario-slug>`
4. A **background script** runs silently when the environment boots to deploy the broken state before the candidate starts.
5. Optionally, a **foreground script** shows a progress message like `Setting up environment... please wait`.

### How the Candidate Connects

- **No installation required.** The candidate opens a URL in any browser.
- KillerCoda provisions a live Kubernetes cluster in ~30 seconds.
- They land on a split-screen: **instructions on the left, terminal on the right**.
- Optionally the layout can include a **Theia IDE** (in-browser VS Code-like editor) for file editing.
- The environment is fully ephemeral and isolated — nothing persists after the session ends.

### Time Limits

| KillerCoda Tier | Session Duration |
|---|---|
| FREE | 1 hour |
| PLUS | 4 hours |

> **Recommendation:** Either the creator account or candidate account should be PLUS (~$12/mo) to get 4-hour sessions. For a 60–90 minute interview a FREE account is sufficient.

### Candidate's Available Tools (Pre-installed)

The `kubernetes-kubeadm-1node` environment includes:

| Category | Tools |
|---|---|
| Kubernetes | `kubectl`, `kubeadm`, `kubelet` (v1.35) |
| Container runtime | `docker`, `podman`, `crictl` |
| Package manager | `helm` |
| Editors | `vim`, `nano`, Theia IDE (optional) |
| Shell utilities | `bash`, `curl`, `wget`, `jq`, `grep`, `awk`, `sed`, `cat`, `less` |
| Networking | `ping`, `curl`, `nslookup`, `netstat`, `ss` |
| File tools | `tar`, `find`, `chmod`, `chown` |

**What's NOT available by default:**
- `az` CLI (Azure) — not pre-installed, but can be bootstrapped via background script if needed
- The candidate cannot reach external cloud APIs unless the scenario explicitly installs them

### Pre-installed Toolset (via `background.sh`)

To level the playing field and keep the focus on diagnostic skill rather than tool setup, the background script will pre-install a curated set of tools and announce them in the intro instructions.

#### Tools to Pre-install

| Tool | Purpose | Why Include It |
|---|---|---|
| `k9s` | TUI Kubernetes dashboard — browse pods, logs, events interactively | Tests whether they prefer TUI vs CLI; experienced users reach for this naturally |
| `stern` | Multi-pod log tailing | Useful for spotting crash patterns across replicas |
| `kubectx` / `kubens` | Fast context/namespace switching | Signals multi-cluster familiarity |
| `kube-ps1` | Shell prompt showing current context/namespace | Quality-of-life; shows shell hygiene habits |
| `yq` | YAML query/edit tool (like `jq` for YAML) | Useful for inspecting manifests without opening an editor |
| `bat` | Syntax-highlighted `cat` replacement | Optional quality-of-life; signals comfort with modern tooling |

#### Install Script (to run in `background.sh`)

```bash
# k9s
K9S_VERSION=$(curl -s https://api.github.com/repos/derailed/k9s/releases/latest | jq -r .tag_name)
curl -sL "https://github.com/derailed/k9s/releases/download/${K9S_VERSION}/k9s_Linux_amd64.tar.gz" \
  | tar xz -C /usr/local/bin k9s

# stern
STERN_VERSION=$(curl -s https://api.github.com/repos/stern/stern/releases/latest | jq -r .tag_name)
curl -sL "https://github.com/stern/stern/releases/download/${STERN_VERSION}/stern_linux_amd64.tar.gz" \
  | tar xz -C /usr/local/bin stern

# kubectx + kubens
curl -sL https://github.com/ahmetb/kubectx/releases/latest/download/kubectx -o /usr/local/bin/kubectx && chmod +x /usr/local/bin/kubectx
curl -sL https://github.com/ahmetb/kubectx/releases/latest/download/kubens  -o /usr/local/bin/kubens  && chmod +x /usr/local/bin/kubens

# yq
YQ_VERSION=$(curl -s https://api.github.com/repos/mikefarah/yq/releases/latest | jq -r .tag_name)
curl -sL "https://github.com/mikefarah/yq/releases/download/${YQ_VERSION}/yq_linux_amd64" \
  -o /usr/local/bin/yq && chmod +x /usr/local/bin/yq

# kube-ps1 (sourced in .bashrc)
curl -sL https://raw.githubusercontent.com/jonmosco/kube-ps1/master/kube-ps1.sh -o /opt/kube-ps1.sh
echo 'source /opt/kube-ps1.sh' >> /root/.bashrc
echo 'PS1="[$(kube_ps1)] \w \$ "' >> /root/.bashrc

# bat
apt-get install -y -q bat 2>/dev/null || true
ln -sf /usr/bin/batcat /usr/local/bin/bat 2>/dev/null || true
```

> **Note:** All installs happen silently in the background while the foreground script shows `Preparing your environment...`. The candidate's terminal is clean and ready when they start.

#### What to Tell the Candidate (Intro Instructions)

```
The following tools are available in addition to kubectl and helm:
  k9s       — interactive cluster dashboard (run: k9s)
  stern     — multi-pod log tailing (run: stern <selector>)
  kubens    — switch namespaces quickly
  kubectx   — switch contexts quickly
  yq        — query/edit YAML files
  bat       — syntax-highlighted file viewer

Use whichever tools you prefer. There is no requirement to use any specific one.
```

> **Observation tip for interviewers:** Note which tools the candidate gravitates toward. Heavy reliance on `k9s` with no `kubectl` fluency can be a yellow flag. A candidate who uses both fluidly is a strong signal.

---

## Scenario Design

### Framing (Candidate Sees This)

> **Situation:** The `mobility-api` service has been failing in production since the last deployment 20 minutes ago. The on-call engineer escalated to you. Customers are reporting a 503 error.
>
> **Your Tasks:**
> 1. Identify the root cause
> 2. Fix the issue so the service is healthy
> 3. Be prepared to explain what happened and how to prevent it in the future

### Recommended Scenario Variants (pick 1–2 per candidate)

Each variant is a self-contained broken deployment. They share the same framing but test different skill areas.

---

#### Variant A — CrashLoopBackOff: Missing Environment Variable

**What's broken:** A Deployment references a `ConfigMap` key that doesn't exist. The container starts, fails to read a required `DATABASE_URL` env var, and crashes immediately.

**Diagnostic path:**
```
kubectl get pods -n mobility
kubectl describe pod <pod> -n mobility
kubectl logs <pod> -n mobility
kubectl get configmap -n mobility
kubectl describe configmap mobility-config -n mobility
```

**Fix:** Either patch the ConfigMap to add the missing key, or correct the env var name in the Deployment.

**Follow-up question:** "How would you prevent a misconfigured ConfigMap from making it to production?"

---

#### Variant B — Liveness Probe Killing Healthy Pods

**What's broken:** A Deployment has a liveness probe with an aggressively short `initialDelaySeconds` (2s) and `failureThreshold` (1). The app takes ~10s to start, so the probe kills it before it's ready. Pods are stuck in `Running -> OOMKilled` loop intermittently.

**Diagnostic path:**
```
kubectl get pods -n mobility
kubectl describe pod <pod> -n mobility    # look at "Liveness probe failed" events
kubectl get deployment mobility-api -n mobility -o yaml
```

**Fix:** Patch the Deployment to increase `initialDelaySeconds` to 15 and `failureThreshold` to 3. Separate `readinessProbe` from `livenessProbe`.

**Follow-up question:** "What's the difference between a liveness probe and a readiness probe, and when would you use each?"

---

#### Variant C — Wrong Image Tag / ImagePullBackOff

**What's broken:** The Deployment references image tag `mobility-api:latest` but the image was pushed as `mobility-api:1.4.2`. The registry is a local registry pre-deployed in the cluster. Pods are in `ImagePullBackOff`.

**Diagnostic path:**
```
kubectl get pods -n mobility
kubectl describe pod <pod> -n mobility    # look at "Failed to pull image" events
kubectl get deployment mobility-api -n mobility -o jsonpath='{.spec.template.spec.containers[0].image}'
# Check what tags actually exist in the registry:
curl http://localhost:5000/v2/mobility-api/tags/list
```

**Fix:** Patch the Deployment image tag to `mobility-api:1.4.2` or re-tag the image.

**Follow-up question:** "Why is `:latest` considered an anti-pattern in production Kubernetes?"

---

#### Variant D — Service Selector Mismatch

**What's broken:** The `Service` was updated during the deployment but the `selector` label was changed from `app: mobility-api` to `app: mobility-backend`. The Deployment pods still have the old label. The Service has no endpoints, causing 503s.

**Diagnostic path:**
```
kubectl get svc -n mobility
kubectl describe svc mobility-api -n mobility     # Endpoints: <none>
kubectl get endpoints mobility-api -n mobility
kubectl get pods -n mobility --show-labels
kubectl get deployment mobility-api -n mobility -o yaml | grep -A5 selector
```

**Fix:** Patch the Service selector back to `app: mobility-api`.

**Follow-up question:** "How would you use `kubectl rollout` to recover from a bad deployment in the future?"

---

#### Variant E — Helm Values Misconfiguration (Advanced)

**What's broken:** A Helm release was upgraded with a `values.yaml` that set `replicaCount: 0`. The Deployment exists but has zero running pods.

**Diagnostic path:**
```
kubectl get pods -n mobility          # no pods
kubectl get deployment -n mobility    # DESIRED: 0
helm list -n mobility
helm get values mobility -n mobility  # shows replicaCount: 0
helm history mobility -n mobility
```

**Fix:** Either `helm rollback mobility 1 -n mobility` or `helm upgrade mobility ./chart -n mobility --set replicaCount=2`.

**Follow-up question:** "Walk me through what `helm rollback` does under the hood. Does it store state anywhere?"

---

## Observation & Scoring Strategy

### How to Monitor the Candidate

KillerCoda provides no live session API. The recommended approach is a **three-layer hybrid**:

#### Layer 1 — Screen Share (Primary)
Have the candidate share their screen over Zoom/Teams while they work. This is the richest signal — you observe:
- Whether they start systematically (`kubectl get pods` → `describe` → `logs`) or guess randomly
- Which tools they reach for
- How they read error messages (do they read carefully or skim?)
- Whether they get stuck and how they recover

**Interviewer role during this phase:** Silent observer. Resist the urge to hint. Note observations on the rubric sheet in real time.

#### Layer 2 — Automated Fix Verification (`verify.sh`)
Each variant has a KillerCoda `CHECK` button backed by a `verify.sh` script. When the candidate clicks it, the script confirms whether the service is actually healthy — no subjectivity.

Example `verify.sh` per variant:

```bash
# Variant A — ConfigMap env var fix
READY=$(kubectl get deployment mobility-api -n mobility -o jsonpath='{.status.readyReplicas}')
[ "$READY" -ge 1 ] && exit 0 || exit 1

# Variant D — Service selector fix
ENDPOINTS=$(kubectl get endpoints mobility-api -n mobility -o jsonpath='{.subsets[*].addresses[*].ip}')
[ -n "$ENDPOINTS" ] && exit 0 || exit 1

# Variant E — Helm replica fix
READY=$(kubectl get deployment mobility-api -n mobility -o jsonpath='{.status.readyReplicas}')
[ "$READY" -ge 1 ] && exit 0 || exit 1
```

#### Layer 3 — Command History Review (Post-session)
The `background.sh` enables timestamped shell history logging silently. After the session, the interviewer runs:

```bash
cat /root/.interview_history
```

This produces a full timestamped log of every command. Paste it to GitHub Copilot Chat with the prompt:

> *"Score this command history against the platform engineer rubric for Variant [X]."*

Copilot can then score the diagnostic methodology, tool fluency, and efficiency sections without the interviewer needing to do it manually.

**`background.sh` additions for history logging:**
```bash
echo 'export PROMPT_COMMAND="history -a"' >> /root/.bashrc
echo 'export HISTTIMEFORMAT="%F %T "' >> /root/.bashrc
echo 'export HISTFILE=/root/.interview_history' >> /root/.bashrc
echo 'export HISTSIZE=10000' >> /root/.bashrc
echo 'export HISTFILESIZE=10000' >> /root/.bashrc
```

### Scoring Flow Summary

```
During session:   Interviewer watches screen share → marks real-time notes
End of exercise:  Candidate clicks CHECK → verify.sh confirms fix (pass/fail)
Post-session:     Interviewer copies command history → pastes to Copilot for rubric scoring
Debrief (5 min):  Interviewer asks verbal follow-up questions → scores explanation + prevention
```

---

## Scoring Rubric (Summary — full rubric in `docs/rubric.md`)

| Area | Weight | How Measured |
|---|---|---|
| Diagnostic methodology | 30% | Screen share observation + command history review |
| Fix correctness | 25% | Automated `verify.sh` — objective pass/fail |
| Explanation quality | 20% | Verbal debrief after the fix |
| Prevention / best practices | 15% | Verbal debrief — mentions CI validation, webhooks, rollback |
| Tool fluency | 10% | Command history efficiency + screen share observation |

---

## Implementation Roadmap

### Phase 1 — Repository Scaffolding
- [ ] `killercoda/index.json` — scenario metadata
- [ ] `killercoda/intro.md` — candidate-facing scenario prompt
- [ ] `killercoda/background.sh` — deploys broken state silently
- [ ] `killercoda/foreground.sh` — "Preparing environment..." message

### Phase 2 — Scenario Assets
- [ ] K8s namespace, Deployment, Service, ConfigMap manifests (broken variants)
- [ ] Variant A: missing env var in ConfigMap
- [ ] Variant B: aggressive liveness probe
- [ ] Variant C: bad image tag + local registry
- [ ] Variant D: service selector mismatch
- [ ] Variant E: Helm chart with `replicaCount: 0`

### Phase 3 — Interviewer Materials
- [ ] `docs/rubric.md` — detailed scoring guide
- [ ] `docs/solution-notes.md` — exact fix commands per variant
- [ ] `docs/interview-guide.md` — what to ask, what to watch for, red flags

### Phase 4 — KillerCoda Setup
- [ ] Create KillerCoda creator account
- [ ] Link this GitHub repo
- [ ] Test each variant end-to-end
- [ ] Set scenario visibility (private or unlisted for interview use)

---

## Open Questions Before Build

1. **How many variants do you want to run in a single session?** KillerCoda supports multi-step scenarios — we could chain 2 variants in one session, or keep each as a standalone link.
2. **Should the scenario be private (interview link only) or public?** Public scenarios on KillerCoda are discoverable. For interview fairness, an unlisted link is better.
3. **Do you want a scoring checkpoint (`CHECK` button)?** KillerCoda supports automated verification scripts — useful if you want to confirm the service is healthy without watching in real time.

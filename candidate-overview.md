# Platform Engineer Interview Exercise — Candidate Overview

## What to Expect

As part of the interview process, you will complete a short hands-on exercise in a live Kubernetes environment. This replaces a whiteboard problem — everything you do will be in a real terminal against a real cluster.

You will be given a broken service and asked to do three things:

1. **Identify the root cause** of the failure
2. **Fix it** so the service is healthy again
3. **Explain** what happened and how you would prevent it in the future

There are no trick questions. The scenario reflects the kind of incident you would encounter in a production platform engineering role.

---

## Environment

- **Access:** You will receive a URL. Open it in any browser — no installation required.
- **What you get:** A browser-based terminal connected to a live Kubernetes cluster (v1.35), ready to use.
- **Time:** The exercise is designed to be completed in under 45 minutes. You will have at least 60 minutes of session time.

---

## Available Tools

The following tools are pre-installed. Use whatever you are comfortable with — there is no requirement to use any specific one.

| Tool | Description |
|---|---|
| `kubectl` | Kubernetes CLI |
| `helm` | Helm package manager |
| `k9s` | Interactive terminal UI for Kubernetes (run: `k9s`) |
| `stern` | Multi-pod log tailing (run: `stern -n <namespace> .`) |
| `kubens` | Fast namespace switching |
| `kubectx` | Fast context switching |
| `yq` | YAML query and edit tool |
| `vim` / `nano` | Text editors |
| Standard Linux utilities | `curl`, `jq`, `grep`, `awk`, `sed`, etc. |

---

## What We Are Looking For

- How you approach an unfamiliar problem — your diagnostic process matters as much as the answer
- Your ability to use Kubernetes tools to gather information before taking action
- Clear communication: can you explain what went wrong and why in plain terms?

---

## Tips

- Start by observing before changing anything
- `kubectl describe` and `kubectl logs` are your best friends
- When you have fixed the issue, click the **CHECK** button to confirm the service is healthy
- After CHECK passes, your interviewer will ask a few follow-up questions


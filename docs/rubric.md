# Interviewer Scoring Rubric

Use this sheet during and after each interview. Score each area independently.
Total: 100 points.

---

## Candidate: ___________________  Date: ___________  Variant: ___

---

## 1. Diagnostic Methodology (30 pts)

*How did they approach the problem? Was it systematic or random?*

| Score | Description |
|---|---|
| 27–30 | Immediate, logical progression: pods → describe/events → logs → resource definitions. No wasted moves. |
| 20–26 | Mostly systematic with minor detours. Finds the issue without significant prompting. |
| 12–19 | Some structure but with notable gaps — skips events, doesn't check logs early, or focuses on wrong resource first. |
| 0–11 | Scatter-shot. Tries random commands. Needs prompting to move forward. |

**Score: ___ / 30**

**Notes:**
```
What did they check first?

Did they use describe/events or jump straight to editing?

Did they read the error messages carefully or skim past them?
```

---

## 2. Fix Correctness (25 pts)

*Did the fix actually resolve the issue? Verified by the CHECK button (`verify.sh`).*

| Score | Description |
|---|---|
| 25 | Service healthy on first CHECK attempt. |
| 18–24 | Fixed with one minor correction after initial attempt. |
| 10–17 | Required significant iteration or partial fix only. |
| 0–9 | Could not resolve without direct assistance. |

**Score: ___ / 25**

**CHECK button result:** Pass / Fail / Not Attempted

**Notes:**
```
What was their fix command or approach?

Did they verify the fix worked (e.g., kubectl get pods after patching)?
```

---

## 3. Explanation Quality (20 pts)

*Assessed verbally after the exercise. Ask: "Walk me through what happened."*

| Score | Description |
|---|---|
| 18–20 | Accurately explains root cause, the failure chain, and impact. Uses correct terminology. Clear and concise. |
| 13–17 | Correct understanding with minor gaps or imprecise language. |
| 7–12 | Partially correct. Describes symptoms rather than root cause, or misidentifies the failure. |
| 0–6 | Explanation is incorrect or the candidate cannot articulate what happened. |

**Score: ___ / 20**

**Notes:**
```
Did they explain the root cause (not just the symptom)?

Did they trace the failure chain end-to-end?

Was their language precise (correct K8s terminology)?
```

---

## 4. Prevention & Best Practices (15 pts)

*Ask: "How would you prevent this from happening again?"*

| Score | Description |
|---|---|
| 13–15 | Proposes concrete preventive controls: CI validation, admission webhooks, readiness gates, rollback strategy, policy enforcement. Mentions more than one layer of defense. |
| 9–12 | Suggests reasonable prevention with some specifics (e.g., "add CI checks" or "use readiness probes properly") but stays surface-level. |
| 4–8 | Vague — "be more careful" or "review changes before deploying." No concrete mechanism. |
| 0–3 | Cannot suggest prevention or gives incorrect/irrelevant advice. |

**Score: ___ / 15**

**Strong answers to listen for (variant-specific):**

- **Variant A (env var):** CI step that validates ConfigMap keys match Deployment env references; use Secrets/external secret operators instead of plain ConfigMaps for sensitive values.
- **Variant B (probe):** Separate liveness from readiness; set `initialDelaySeconds` based on measured startup time; use `startupProbe` for slow-start containers.
- **Variant C (image tag):** Pin image tags in CI (never use `:latest` in production); image tag scanning in pipeline; sign images with cosign/Notary.
- **Variant D (selector):** Use `kubectl diff` before applying; admission webhooks (OPA/Gatekeeper) to validate label consistency; require `kubectl rollout status` as a deployment gate.
- **Variant E (Helm):** Protect `replicaCount` with Helm schema validation (`values.schema.json`); add `helm diff` to CI pipeline before upgrade; lock critical values with Kyverno policies.

**Score: ___ / 15**

---

## 5. Tool Fluency (10 pts)

*Rate the efficiency and naturalness of their kubectl/tool usage.*

| Score | Description |
|---|---|
| 9–10 | Fluent. Uses flags efficiently (`-o yaml`, `-o jsonpath`, `--show-labels`). No unnecessary googling. Chooses the right tool for each task. |
| 6–8 | Comfortable but not polished. Occasionally looks up syntax. Generally correct tool choices. |
| 3–5 | Functional but slow. Significant googling. Relies heavily on one tool (e.g., only `k9s`, can't use `kubectl` independently). |
| 0–2 | Struggles with basic kubectl commands. Requires prompting for syntax. |

**Score: ___ / 10**

**Notes:**
```
Did they use kubectl or k9s or both?

Did they know flags like --show-labels, -o jsonpath, describe, rollout?

Did they verify their fix after applying it?
```

---

## Total Score

| Area | Weight | Score |
|---|---|---|
| Diagnostic methodology | 30 | ___ |
| Fix correctness | 25 | ___ |
| Explanation quality | 20 | ___ |
| Prevention / best practices | 15 | ___ |
| Tool fluency | 10 | ___ |
| **Total** | **100** | **___** |

### Hiring Guidance

| Score | Signal |
|---|---|
| 85–100 | Strong hire. Experienced, systematic, communicates well. |
| 70–84 | Solid hire. Minor gaps in depth or communication but fundamentally capable. |
| 55–69 | Borderline. Good instincts but needs coaching in one or more areas. |
| < 55 | Not recommended at this time. |

---

## Overall Impression

**Strengths:**

**Gaps:**

**Recommendation:** Hire / Borderline / No hire

**Interviewer:** ___________________

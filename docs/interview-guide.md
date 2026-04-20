# Interviewer Guide

## Before the Interview

1. **Choose a variant** — pick one based on the candidate's stated experience level:
   - Less experienced (2–3 yrs): Variant C (image pull) or Variant A (env var) — faster to diagnose
   - Mid-level (3–5 yrs): Variant B (liveness probe) or Variant D (selector mismatch)
   - Senior (5+ yrs): Variant E (Helm) or Variant D — requires knowing where to look beyond pods

2. **Send the candidate the KillerCoda URL** for their chosen variant 5 minutes before the session starts.

3. **Open `docs/rubric.md`** — score in real time during the screen share.

4. **Open `docs/solution-notes.md`** — for the debrief, so you know what ideal answers sound like.

5. **Have screen share ready** — ask the candidate to share their full screen before they start.

---

## Running the Session

### Opening (2 minutes)
> "I'm going to send you a URL. When you open it, you'll see a terminal connected to a Kubernetes cluster. There's a production service that broke after a recent deployment. Your goal is to find out what's wrong, fix it, and be ready to explain it. There's no trick — it's a real broken Kubernetes environment. Take as much time as you need. I'll be watching but won't help unless you're completely stuck. Any questions before we start?"

### During the exercise
- **Stay silent.** Do not hint. Note what they try on the rubric sheet.
- If they are completely frozen after 5+ minutes: "What would you normally check first when a service isn't running?"
- If they're on the right track but moving slowly: say nothing — slow-but-correct is still good.
- If they fix it: "Go ahead and click CHECK when you're ready."

### Timing guidance
| Experience Level | Expected Completion |
|---|---|
| Strong senior | 5–12 minutes |
| Solid mid-level | 10–20 minutes |
| Junior / developing | 20–40 minutes |
| Cannot complete | > 45 minutes or requires hints |

---

## Debrief (5–10 minutes after CHECK passes)

Ask these in order. Let them talk — resist filling silence.

**1. Walkthrough**
> "Tell me what you found and how you found it."

*What to listen for:* Logical sequence, correct root cause, accurate terminology.
*Red flag:* They describe what they did (commands) but not why.

**2. Root cause**
> "What specifically caused the 503? Not what you fixed — what was the underlying cause?"

*What to listen for:* Precise answer (e.g., "The ConfigMap didn't have the key the Deployment was referencing").
*Red flag:* They say "the pod was crashing" without explaining why.

**3. Prevention**
> "If you owned this pipeline, what's the one change you'd make today to prevent this class of problem?"

*What to listen for:* A specific, actionable control — not "be more careful."
*Red flag:* Generic answers ("add more testing") with no mechanism described.

**4. Blast radius / rollback**
> "If you couldn't fix this immediately, what would you do for customers right now?"

*What to listen for:* `kubectl rollout undo`, `helm rollback`, traffic shifting, feature flags, incident communication.
*Red flag:* No mention of rollback — only focused on fixing the root cause, not customer impact.

**5. Stretch (senior candidates only)**
> "How would you design a deployment pipeline for this service that makes this outcome structurally impossible?"

*What to listen for:* GitOps, progressive delivery (Argo Rollouts/Flagger), admission webhooks, schema validation, automated smoke tests, approval gates.

---

## Red Flags to Watch For

| Behavior | What It Suggests |
|---|---|
| Starts editing manifests before checking logs or describe | Guessing rather than diagnosing |
| Can only operate via k9s, fumbles raw kubectl | Limited CLI depth, may struggle in incident response |
| Fixes the issue but can't explain the root cause | Surface-level understanding |
| Mentions only "add more tests" for prevention — no specific mechanism | Has heard the concept but hasn't implemented controls |
| Never verifies the fix worked (doesn't check pods after patching) | Incomplete operational discipline |
| Asks what namespace to check | Should know to `kubectl get ns` and explore |

## Positive Signals

| Behavior | What It Suggests |
|---|---|
| Checks events and logs before touching manifests | Disciplined, methodical |
| Uses `kubectl get pods --show-labels` or `kubectl get endpoints` unprompted | Knows the full resource model |
| Proposes a `startupProbe` for Variant B without prompting | Deep probe knowledge |
| Mentions `helm diff` or GitOps for Variant E | Understands Helm release lifecycle |
| Runs `kubectl rollout status` or curls the service to verify the fix | Closes the loop, doesn't just trust the patch |
| Brings up blast radius / rollback strategy unprompted | Production operations mindset |

---

## After the Interview

1. Complete the scoring rubric (`docs/rubric.md`) within 30 minutes while fresh.
2. Retrieve command history for post-session scoring review:
   - During the session (if you have terminal access): `cat /root/.interview_history`
   - Paste the history to GitHub Copilot Chat with: *"Score this command history against the platform engineer rubric for Variant [X]"*
3. Compare scores across interviewers if multiple people conduct the exercise.

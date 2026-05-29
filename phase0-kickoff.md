# Phase 0 — Kickoff Kit

Companion to `phase0-spec.md` and `CLAUDE.md`. This is the runnable layer: the order to
work in, plus a proposal seed and acceptance scenarios for each milestone to hand to
OpenSpec inside Claude Code.

**Why seeds and not finished specs:** per OpenSpec's own guidance, generating every spec
upfront is wasted effort — you create each change when you reach it. So each milestone
below gives you two things: (1) a one-line seed for `/openspec:proposal`, which makes
OpenSpec generate the proposal, design, tasks, and spec deltas; and (2) the acceptance
scenarios to lock in during the Design phase so the generated `tasks.md` is anchored to
something testable.

---

## Setup (once)
1. Create the repo (empty).
2. `npm install -g @fission-ai/openspec`
3. `openspec init` inside the repo (registers the `/openspec:*` slash commands for Claude Code).
4. Add `CLAUDE.md` at the repo root.
5. Stub the `justfile` with `up`, `down`, `status`, `cost` (M0 fills these in).

## Session order
M0 Scaffold → M1 Substrate → M2 Platform → M3 GitOps → M4 Workload → M5 Observability/cost/writeup.
One milestone per focused session. Each runs Frame → Design → Build → Verify → Ship.

---

## M0 — Scaffold

**Proposal seed:**
`/openspec:proposal "Scaffold the repo: directory layout from the spec, CLAUDE.md in place, justfile with up/down/status/cost/load stubs, README outline with the five proof-claims as section headers, docs/architecture.md + docs/cost.md stubs, a renovate.json for automated dependency PRs, and a .github/workflows/security.yml that runs Trivy against the IaC (and images when present) on PRs."`

**Acceptance scenarios:**
- GIVEN a fresh clone, WHEN I run `just --list`, THEN up, down, status, cost, and load are listed.
- GIVEN the repo, WHEN I open `README.md`, THEN it has the five proof-claims as headers.
- GIVEN the repo, WHEN I open `CLAUDE.md`, THEN stack, workflow, and cost guardrails are present.
- GIVEN `renovate.json`, WHEN Renovate runs, THEN it opens PRs for outdated chart/provider/action versions.
- GIVEN a PR, WHEN the Trivy workflow runs, THEN it scans IaC for misconfig and fails on high-severity findings outside the documented allow-list.

---

## M1 — Cloud substrate (OpenTofu)

**One-time before this milestone:** create the state bucket out-of-band (`aws s3 mb`, enable versioning, block public access).

**Proposal seed:**
`/openspec:proposal "Provision the AWS substrate with OpenTofu: an S3 backend (versioned, encrypt=true, use_lockfile=true), then VPC, EKS cluster, IAM/IRSA, a default CPU node group, and an optional GPU node group gated behind a 'gpu' variable. Wire just up/down to apply/destroy."`

**Acceptance scenarios:**
- GIVEN the configured backend, WHEN I run `just up`, THEN state is written to S3 (not on disk) and a second concurrent `apply` is refused by the lock.
- GIVEN `gpu=false`, WHEN I run `just up`, THEN the cluster comes up and `kubectl get nodes` shows ready CPU nodes and no GPU nodes.
- GIVEN `gpu=true`, WHEN I run `just up`, THEN a GPU node group is present.
- GIVEN a running cluster, WHEN I run `just down`, THEN destroy completes with no orphaned VPC / NAT / EKS resources, and the state bucket remains.

---

## M2 — Platform layer (formae)

**Proposal seed:**
`/openspec:proposal "Introduce formae as the in-cluster platform layer: model the core add-ons in Pkl, run the drift-capture/extract-patch loop against the live cluster, and document one AI-modifiable abstraction in docs/architecture.md."`

**Acceptance scenarios:**
- GIVEN a running cluster, WHEN formae builds its model, THEN it reflects the actual running add-ons.
- GIVEN a deliberate out-of-band change (e.g. a manually edited resource), WHEN formae runs, THEN the change is detected as drift and either reconciled or extracted to code.
- GIVEN `docs/architecture.md`, WHEN I read it, THEN one Pkl abstraction is shown with a note on how an agent would safely modify it.

---

## M3 — GitOps (Argo CD)

**Proposal seed:**
`/openspec:proposal "Install Argo CD via the platform layer and wire an app-of-apps that deploys observability and the workload from gitops/. No hand-applied manifests."`

**Acceptance scenarios:**
- GIVEN Argo installed, WHEN I commit a change under `gitops/`, THEN Argo syncs it automatically.
- GIVEN the app-of-apps, WHEN I open the Argo UI, THEN observability and workload apps are healthy and synced.
- GIVEN the workload, WHEN I check how it was deployed, THEN it arrived through Argo, not `kubectl apply`.

---

## M4 — Inference workload (vLLM + gateway)

**Proposal seed:**
`/openspec:proposal "Deploy vLLM serving the small model behind a thin FastAPI /chat gateway, with autoscaling (HPA or KEDA scale-to-zero). Respect the gpu flag: CPU/small model by default, GPU/larger model when gpu=true. Add a k6 load script and a 'just load' recipe that drives sustained traffic and saves a run summary."`

**Acceptance scenarios:**
- GIVEN the workload deployed, WHEN I `curl /chat` with a prompt, THEN I get a completion.
- GIVEN `just load` is running, WHEN I watch replicas, THEN they scale up under sustained traffic and back down when idle.
- GIVEN a completed `just load` run, WHEN I open the saved k6 summary, THEN p95 latency, RPS, and (on GPU) tokens-per-second are recorded.
- GIVEN `gpu=true`, WHEN the workload deploys, THEN vLLM schedules on the GPU node group with the larger model.

---

## M5 — Telemetry (OTel-native), cost & writeup

**Proposal seed:**
`/openspec:proposal "Stand up an OTel-native telemetry pipeline: a gateway OpenTelemetry Collector routing metrics to Prometheus, logs/events (k8s events, formae OTLP, Argo syncs) to S3-backed Loki, and optionally traces to Tempo. Add OpenCost cost attribution for the inference namespace, a budget alert via Alertmanager, an S3 lifecycle so the audit trail outlives teardown, verify TTL teardown, and finish the README so a founder understands what was built, why it's hard, what it costs, and what I can do for them."`

**Acceptance scenarios:**
- GIVEN Grafana, WHEN I open the workload dashboard, THEN request latency and throughput are shown (metrics).
- GIVEN OpenCost, WHEN I view the inference namespace, THEN a dollar figure is attributed to it (metrics).
- GIVEN a k8s/formae/Argo event, WHEN it occurs, THEN it lands in Loki via the Collector (logs/events).
- GIVEN the budget threshold, WHEN spend crosses it, THEN an alert fires.
- GIVEN a `just down` then `just up` cycle, WHEN I query Loki, THEN the prior audit/event history is still there (S3-backed), while cluster metrics are fresh.
- GIVEN the TTL has elapsed and `just down` runs, THEN zero billable *cluster* resources remain (only S3 audit retention persists).
- GIVEN `README.md`, WHEN a founder reads it, THEN it ends with an explicit "what this demonstrates / what I can do for you" section.

# Phase 0 — Reference Architecture Proof Asset

**Spec-driven build plan for execution with Claude Code**

The goal of Phase 0 is *not* a product. It is one public repository plus a writeup that proves you can stand up production-grade AI infrastructure, and that doubles as a lead magnet for the consulting work in Phases 1–3. Build time: ~1 month, part-time. Revenue this phase: $0 — this is the asset you point prospects at.

The "customer" for this artifact is a seed-stage AI startup founder or early engineer in SF who just raised, is burning cloud/GPU money, and has no platform person. Everything below should be legible to *that* reader, not just to you.

---

## 1. What this asset must demonstrate

A prospect skimming the README in 90 seconds should come away believing five things about you:

1. You can deploy a real LLM workload on Kubernetes, not a toy.
2. You manage infrastructure as code with no drift — the repo *is* reality.
3. You build with GitOps, so changes are reviewable and reversible.
4. You instrument cost and performance, not just uptime.
5. You can do all of this with cost discipline — spin up, prove it, tear down.

If a milestone below doesn't ladder up to one of those five claims, cut it.

---

## 2. Stack decisions (and what's swappable)

| Layer | Default choice | Why | Swap if |
| --- | --- | --- | --- |
| Cloud | AWS | Most common at seed-stage AI startups; EKS is the recognizable standard | Your target clients are GCP-heavy → GKE Autopilot |
| Substrate IaC | OpenTofu | Terraform-compatible, open source, what clients hire for | Client mandates Terraform CLI specifically |
| Platform layer | formae (Pkl) | Drift capture + AI-modifiable abstractions; your differentiator | n/a — this is the showcase piece |
| GitOps | Argo CD | App-of-apps pattern, mature, widely recognized | You prefer Flux |
| Inference | vLLM | De facto OSS serving engine for open models | TGI or Ollama for the CPU demo path |
| Model | A small open model (1–3B) | Cheap to demo; GPU path optional behind a flag | Larger model only on the GPU path |
| Telemetry | OTel Collector → Prometheus / Loki / Tempo | OTLP is the contract; backends swappable; Grafana is just a viewer (see §2.3) | any OTLP-compatible vendor |
| Cost visibility | OpenCost | Open source, emits $/workload as metrics (stored in Prometheus) | Kubecost if a client already runs it |
| Task runner | justfile | One-command up/down, readable | Makefile |
| Spec capture | OpenSpec | Lightweight, Claude-Code-native (slash commands), specs live in git, brownfield-first | n/a — habit transfers to client work |
| Dependency hygiene | Renovate | Automated PRs for chart, provider, action versions; cheap to add, signals discipline | Dependabot if already in use |
| Security scanning | Trivy (in CI) | Scans images and IaC for misconfig + CVEs; supports the SOC-2-flavored story | kubescape if a client prefers it |
| Load testing | k6 | Makes "autoscaling works under load" a concrete, reproducible claim in M4 | Locust |

**The deliberate architecture choice:** OpenTofu owns the cloud substrate that clients must trust (VPC, EKS, IAM/IRSA, node groups). formae layers on top to manage the in-cluster platform add-ons, capture out-of-band drift, and expose clean Pkl abstractions that an AI agent can safely modify. This mirrors formae's own "runs alongside your existing IaC" positioning and lets the README tell the drift-free / AI-era story without betting the credibility-critical layer on a pre-1.0 tool.

### 2.1 Helm install strategy (two tiers)

Three layers can install a Helm chart (OpenTofu's Helm provider, formae's native Helm support as of 0.85, and Argo CD). The rule that decides which: after M3, nothing reaches the cluster except through Argo. Split charts by whether they can live under GitOps.

- **Bootstrap tier — installed by formae (platform layer), not Argo.** Charts that must exist *before or around* Argo, so Argo can't manage them: Argo CD itself, AWS Load Balancer Controller, EBS CSI driver, Karpenter/cluster-autoscaler, cert-manager, and the NVIDIA GPU operator (only when `gpu=true`). formae installs these as Pkl-modeled Helm releases and gets drift capture over them for free. (Fallback if the 0.85 Pkl Helm schema is too green: install the bootstrap tier with the OpenTofu `helm_release` resource at substrate time.)
- **Workload tier — installed by Argo CD as Helm `Application`s.** Everything else: kube-prometheus-stack, OpenCost, and vLLM if charted. These live in `gitops/` as `Application` resources with a Helm source, wired into the app-of-apps. Pin every chart's `targetRevision`.

**The boundary that must hold:** formae and Argo are both reconcilers — if both own the same release they fight forever. formae owns the substrate + bootstrap tier; Argo owns the workload tier. Scope formae's discovery (via `labelTagKeys` / `resourceTypesToDiscover` in its config) so it never reaches into Argo-managed namespaces.

### 2.2 State management

Only the OpenTofu substrate produces state — formae is stateless by design (it auto-discovers and codifies reality rather than keeping a state file). So state discipline applies to exactly one directory, `substrate/`.

Use an S3 backend with four things on: remote storage, bucket versioning (required for the native lock and for rollback), encryption at rest (`encrypt = true`), and native S3 locking (`use_lockfile = true`, OpenTofu 1.7+ — no DynamoDB needed).

```hcl
terraform {
  backend "s3" {
    bucket       = "yourorg-tfstate"
    key          = "ai-infra-reference/substrate.tfstate"
    region       = "us-west-2"
    encrypt      = true
    use_lockfile = true
  }
}
```

Rules: never commit state (`.gitignore` `*.tfstate*` and `*.tflock`); state holds secrets in plaintext, so the bucket is encrypted and access is least-privilege. A stale lock from a crashed run clears with `tofu force-unlock <LOCK_ID>`. Optionally enable OpenTofu's client-side state `encryption` block (passphrase or AWS KMS key provider) to encrypt contents before they reach S3 — belt-and-suspenders, and a clean detail for the README's "secrets never leak" story.

This pairs with the teardown discipline: state lives in S3 and survives `just down`, so teardown destroys the cluster but the next `just up` reads clean state. Never keep state local or in-cluster — the TTL habit would orphan it.

### 2.3 Telemetry (OTel-native)

Design the telemetry around OpenTelemetry, not around Grafana: the OTel Collector plus OTLP is the contract, and every store or dashboard hangs off it as a swappable consumer. The "what happened in the system" data maps onto the three OTel signals, each with a home — there is no separate event database.

- **Metrics** — cost (OpenCost) and resource/performance. OpenCost is effectively stateless; it stores its series in the metrics backend, so retention is the backend's, not OpenCost's. Demo: Prometheus (from kube-prometheus-stack). Scale path: remote-write to Mimir or Thanos for long history.
- **Logs / events** — the audit record: Kubernetes events, formae drift/change events, Argo syncs. These flow through the Collector to Loki, backed by S3. CloudTrail stays the authoritative cloud-account audit log — reference it, don't duplicate it into the cluster.
- **Traces** (optional) — the *execution* of operations (a `formae apply`, an Argo sync) as spans, into Tempo (S3-backed). Add only if you want operation-level timing.

Collector shape: one gateway Collector (Deployment), deployed by Argo as a workload-tier chart (per §2.1). formae already emits OTLP, so point it at the Collector. Grafana (from kube-prometheus-stack) is the single viewer across all three backends; Alertmanager carries the budget alert. Cost stays a **metric**, never a trace.

Retention decision: metrics are ephemeral with the cluster for the demo (cheap, dies on teardown); logs and traces land in S3 with a short lifecycle (e.g. 30 days), so the audit trail outlives a nightly `just down` / `just up` cycle for pennies — the cluster is disposable, the history is not. A client engagement scales this by extending the backends, never by adding a bespoke store.

---

## 3. Repo structure

```
ai-infra-reference/
  README.md              # the story; written for a prospect, not a peer
  CLAUDE.md              # agent constitution: guardrails + conventions
  docs/
    architecture.md      # diagram + decision record
    cost.md              # the cost model and teardown discipline
  substrate/             # OpenTofu: VPC, EKS, IAM/IRSA, node groups
  platform/              # formae (Pkl): add-ons, drift capture, abstractions
  gitops/                # Argo CD app-of-apps
  workload/              # vLLM deployment + thin FastAPI /chat gateway
  observability/         # OTel Collector + kube-prometheus-stack, Loki, Tempo values
  justfile               # up / down / status / cost / load
  renovate.json          # automated dependency PRs (chart, provider, action versions)
  .github/
    workflows/
      security.yml       # Trivy: image + IaC misconfig/CVE scans on PR
  openspec/
    specs/               # living specs, organized by capability/layer
    changes/             # active change proposals (one per milestone)
  .claude/
    agents/              # optional: Explore + Plan subagents
```

Run `npm install -g @fission-ai/openspec` and initialize it in the repo before M0 so the `/openspec:*` slash commands are available inside Claude Code.

---

## 4. CLAUDE.md guardrails (write this first)

`CLAUDE.md` is read at the start of every Claude Code session and anchors the agent's behavior. Keep it tight. It should encode at least:

- **Stack + versions** of OpenTofu, formae, Argo, vLLM, the chart versions in use.
- **Safety rules**, phrased as preferences (the agent follows "prefer X over Y" better than "never X"):
  - Prefer proposing a plan before any `tofu apply`, `formae` apply, or `kubectl` mutation.
  - Always set a teardown TTL on any provisioned cluster; default 4 hours.
  - Prefer the CPU/small-model path unless the `gpu` flag is explicitly set.
  - Keep monthly projected cost under the stated ceiling (see `docs/cost.md`); flag if a change would exceed it.
- **Commands** the agent should use (`just up`, `just down`, `just status`, `just cost`).
- **Spec discipline**: every milestone is captured as an OpenSpec change before building; the agent reads the relevant `openspec/specs/` entry for context and proposes a change rather than improvising.
- **Conventions**: module layout, naming, where secrets come from (never hardcoded).

---

## 5. The execution loop: Frame → Design → Build → Verify → Ship

Each milestone is one OpenSpec change, run through the same five-phase cycle. OpenSpec drives the front half (Frame + Design), Claude Code in plan mode and the build do the middle, and git does the back half (Ship).

1. **Frame.** In Claude Code, run `/openspec:proposal "<milestone goal>"`. OpenSpec reads any existing `openspec/specs/` context, then generates a change folder with a `proposal.md`, `design.md`, `tasks.md`, and the spec deltas. This forces intent to the surface before any code exists.
2. **Design.** Review and refine that proposal — this is where you catch wrong assumptions for free. Write the acceptance criteria as GIVEN/WHEN/THEN scenarios (see §6); for infra they double as your manual test script.
3. **Build.** Enter plan mode (Shift+Tab cycles into it) so Claude proposes an approach before anything destructive, approve it, then let it implement the tasks. Use the read-only Explore subagent to investigate running state and the Plan subagent for sub-planning, to keep the main context clean on longer milestones.
4. **Verify.** Walk the scenarios yourself. Don't take "done" on faith — `kubectl`, `curl`, the Argo UI, the Grafana panel. The scenario passes or the milestone isn't done.
5. **Ship.** Archive the OpenSpec change (folding its delta into `openspec/specs/`) and land one PR-sized commit. The README/writeup gets updated here, not all at the end.

Keep milestones small enough that each fits a single Frame-to-Ship pass. If a proposal balloons in the Design phase, split the milestone.

---

## 6. Milestones

Each milestone is one OpenSpec change, taken through the §5 cycle. The **Acceptance** line below is the plain-English version; in `tasks.md` rewrite it as GIVEN/WHEN/THEN scenarios so it doubles as your verify script.

### M0 — Scaffold
**Goal:** Repo skeleton, `CLAUDE.md`, decision record, justfile stubs, README outline, `renovate.json` for automated dependency PRs, and a `.github/workflows/security.yml` running Trivy against the IaC and (when present) images.
**Acceptance:** Repo structure from §3 exists; `CLAUDE.md` encodes §4 guardrails; `just --list` shows up/down/status/cost/load; README has the §1 five-claims framing as headers; `renovate.json` is valid and Renovate is enabled on the repo; the Trivy workflow runs on PRs and fails on high-severity findings (with an allow-list documented in `docs/architecture.md`).

### M1 — Cloud substrate (OpenTofu)
**Backend bootstrap (once, before first apply):** the state bucket can't be created by the config that stores its state there, so create it out-of-band — `aws s3 mb`, enable versioning, block public access — then wire the `substrate/` backend to it per §2.2. Record the bucket name in `docs/architecture.md`.
**Goal:** VPC, EKS cluster, IAM/IRSA, a default CPU node group, and an optional GPU node group behind a `gpu` variable, with state in the S3 backend (versioned, encrypted, `use_lockfile`).
**Acceptance:** `just up` (substrate only) brings up the cluster; state lands in S3, not on disk, and a concurrent `apply` is blocked by the lock; `kubectl get nodes` returns ready nodes; GPU node group provisions *only* when `gpu=true`; `just down` destroys cleanly with no orphaned resources and leaves the state bucket intact.

### M2 — Platform layer (formae)
**Goal:** Model the in-cluster add-ons in Pkl; demonstrate the drift-capture / extract-patch loop; document one AI-modifiable abstraction.
**Acceptance:** formae discovers the running cluster and builds its model; a deliberate out-of-band change (e.g. an edited resource) is detected as drift and reconciled or extracted to code; `docs/architecture.md` shows one Pkl abstraction with a note on how an agent would safely modify it.

### M3 — GitOps (Argo CD)
**Goal:** Argo CD installed by the bootstrap tier (formae, per §2.1), app-of-apps wiring the workload-tier charts.
**Acceptance:** A commit to `gitops/` syncs to the cluster automatically; the workload-tier charts (kube-prometheus-stack, OpenCost, vLLM) deploy as Argo Helm `Application`s, not by hand; formae's discovery is scoped out of Argo-managed namespaces so the two reconcilers don't fight; Argo UI shows all apps healthy.

### M4 — Inference workload (vLLM + gateway)
**Goal:** vLLM serving the small model behind a thin FastAPI `/chat` gateway; autoscaling (HPA, or KEDA scale-to-zero); GPU path gated by the same flag. When `gpu=true`, the NVIDIA GPU operator is installed as a bootstrap-tier chart (formae, per §2.1) before vLLM schedules. Load is generated reproducibly with k6 via `just load`, which doubles as the autoscaling acceptance script and (on the GPU path) records a tokens-per-second number for the README.
**Acceptance:** `curl` to `/chat` returns a completion; running `just load` drives sustained traffic, replicas scale up while it runs and back down when idle, and the run produces a saved k6 summary (latency p95, RPS, tokens/sec on GPU); switching `gpu=true` installs the GPU operator and schedules vLLM on the GPU node group with the larger model.

### M5 — Telemetry (OTel-native), cost, and the writeup
**Goal:** Stand up the OTel-native telemetry pipeline of §2.3 — a gateway Collector routing the three signals into Prometheus (metrics), S3-backed Loki (logs/events), and optionally Tempo (traces) — with OpenCost cost metrics, a budget alert via Alertmanager, the audit/event trail persisted in S3, verified TTL teardown, and the README that sells the asset. The Collector, kube-prometheus-stack, OpenCost, and Loki ship as workload-tier Argo Helm `Application`s (per §2.1).
**Acceptance:** Grafana shows request latency + throughput for the workload (metrics); OpenCost attributes a dollar figure to the inference namespace (metrics); a Kubernetes/formae/Argo event lands in Loki via the Collector (logs/events); the budget alert fires on threshold; after a `just down` / `just up` cycle the prior audit/event history is still queryable from S3-backed Loki while the cluster's metrics are fresh; `just down` leaves zero billable *cluster* resources (only the pennies of S3 audit retention persist); README tells the story end-to-end with the architecture diagram and an explicit "what this demonstrates / what I can do for you" section aimed at a founder.

---

## 7. Cost guardrails (non-negotiable)

This asset proves cost discipline by *practicing* it. Bake in: default CPU/small path so a demo run is near-free; GPU strictly opt-in; scale-to-zero on the workload; a TTL on the cluster with `just down` as the habit; and a documented cost model in `docs/cost.md` covering both the idle case and a GPU demo run. The single most expensive mistake here is leaving a GPU node group or a NAT gateway running overnight — the guardrails exist to make that impossible by default.

---

## 8. Definition of done

Phase 0 is complete when a founder who has never met you can read the README, understand what was built and why it's hard, see the cost numbers, and come away wanting to talk to you. At that point the asset is also your portfolio piece, your Phase 1 outreach hook, and the reusable skeleton you'll fork for the first paying client.

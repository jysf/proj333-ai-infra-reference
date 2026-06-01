## Context

M0 left a clean scaffold with `up`/`down`/`plan` as stubs. M1 provisions the AWS substrate
the rest of the stack sits on, owned entirely by OpenTofu (per CLAUDE.md: OpenTofu owns the
credibility-critical substrate; formae layers on later). Work happens in the `ai-infra-lab`
member account with short-lived SSO credentials. This is the first milestone that spends
real money, so cost guardrails are load-bearing, not decorative.

## Goals / Non-Goals

**Goals:**
- A reproducible VPC + EKS + IAM/IRSA + CPU node group brought up by `just up` and fully
  destroyed by `just down`, with remote state in S3.
- State discipline: versioned, encrypted, locked; never on disk; bucket survives teardown.
- GPU node group provisioned only when `gpu=true`.
- `kubectl get nodes` shows ready CPU nodes after `just up` (the M1 done-line).

**Non-Goals:**
- No in-cluster add-ons / Helm releases (M2/M3), no Argo, no vLLM, no GPU operator or
  larger model (M4), no observability (M5). No load balancers in M1 (keeps destroy clean).

## Decisions

- **Use the maintained community modules `terraform-aws-modules/vpc/aws` and
  `terraform-aws-modules/eks/aws`, version-pinned.** Rationale: recognizable to clients,
  battle-tested, far less surface area to get IAM/OIDC wrong. Alternative (hand-rolled
  resources) rejected — more credible-looking but more bug surface for no demo benefit.
  Pin exact module + AWS provider + EKS k8s versions in `docs/architecture.md`.
- **Single NAT gateway, not one-per-AZ.** Rationale: a per-AZ NAT triples the most
  expensive idle line item; this is an ephemeral demo. Trade-off: not HA — acceptable and
  noted in `docs/cost.md`. (Documented swap: `single_nat_gateway = false` for prod.)
- **Managed node groups.** Default CPU group: **`t3.medium` × 2** (cheap start; may bump to
  `t3.large`/`m5.large` at M5 when the observability stack lands). GPU group:
  **`g4dn.xlarge`** (the cheapest current-gen NVIDIA GPU) created via `count`/`for_each`
  gated on `var.gpu`, with a GPU taint so only GPU workloads schedule — 0 resources when
  `gpu=false`.
- **EKS Kubernetes version: `1.35`, and track latest going forward.** Standing policy: pin
  to the newest EKS-supported version and bump promptly — BUT verify add-on/chart
  compatibility (EKS module, AWS LB Controller, Argo, kube-prometheus-stack, OpenCost,
  NVIDIA GPU operator) in the plan/CI before applying an upgrade, since the one real risk of
  bleeding-edge k8s is a lagging controller. Recorded as a convention in `CLAUDE.md`.
- **`gpu` gating via a single boolean variable** (`variable "gpu" { default = false }`),
  threaded to the GPU node group's `count = var.gpu ? 1 : 0`. `just up`/`plan` pass it
  through (e.g. `just up gpu=true` → `-var gpu=true`).
- **S3 backend with native locking** (`use_lockfile = true`, OpenTofu ≥1.7 — no DynamoDB),
  `encrypt = true`, bucket versioning on. Bucket created **out-of-band** (chicken-and-egg)
  via a documented one-time bootstrap; name recorded in `docs/architecture.md`. Optional
  client-side state `encryption` block deferred (note as a future hardening).
- **`just up` runs plan then apply; `just down` runs destroy; `just plan` runs `tofu plan`.**
  `up` surfaces the plan before applying (M0 dry-run convention made real). kubeconfig
  fetched via `aws eks update-kubeconfig` — never committed (`.gitignore` covers it).

## Risks / Trade-offs

- [NAT gateway / GPU node group left running overnight = the worst-case spend] → Mitigation:
  `just down` habit + teardown TTL (default 4h, documented) + the $50/mo budget alert;
  GPU strictly opt-in and `desired 0` by default.
- [EKS destroy can orphan ENIs / leftover LB / security groups] → Mitigation: no LBs created
  in M1; rely on module destroy ordering; verify-down checks for zero orphaned VPC/NAT/EKS.
- [GPU instance vCPU quota may be 0 on a fresh account] → Mitigation: GPU path is opt-in;
  document that `gpu=true` may require an AWS service-quota increase first.
- [`use_lockfile` needs OpenTofu ≥1.7] → Mitigation: pin and check the `tofu` version in the
  `up` recipe / verify harness.
- [EKS apply takes ~15–20 min; cost accrues during the run] → expected; keep runs short.

## Migration Plan

Additive and greenfield (no existing infra). Rollback = `just down` (`tofu destroy`) + git
revert of the change. State bucket is intentionally NOT destroyed by `just down`.

## Resolved decisions (Design review)

- **Region:** `us-west-2`.
- **CPU nodes:** `t3.medium` × 2 (~$0.042/hr each); may bump at M5.
- **GPU node:** `g4dn.xlarge` (~$0.526/hr), `gpu=true` only.
- **EKS version:** `1.35` (latest; "track latest" policy with compatibility verification).
- **Cost envelope:** a CPU session ≈ $0.23/hr (control plane $0.10 + NAT $0.045 + 2×
  t3.medium $0.083); a GPU session ≈ $0.76/hr. 24/7 CPU ≈ $165/mo — hence teardown is the
  control. These figures go into `docs/cost.md` at Build.

## Open Questions

- None blocking. Service-quota for GPU instances may need a one-time increase before the
  first `gpu=true` run (handled when we exercise that path).

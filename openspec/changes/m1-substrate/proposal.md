## Why

The reference architecture needs a real, trustworthy cloud substrate before any platform,
GitOps, or workload can land on it. This is the layer clients must trust — VPC, EKS,
IAM/IRSA, node groups — so it is owned by OpenTofu with disciplined remote state. M1 turns
the M0 `just up`/`down`/`plan` stubs into real provisioning and proves claims #2 (IaC, no
drift) and #5 (cost discipline: spin up, prove it, tear down) for the first time.

## What Changes

- **State backend first (bootstrapped out-of-band):** an S3 backend with bucket versioning,
  `encrypt = true`, and native `use_lockfile = true` (OpenTofu 1.7+, no DynamoDB). The
  bucket is created out-of-band (it cannot store the state of the config that creates it)
  and its name recorded in `docs/architecture.md`. State never lives on disk or in-cluster.
- **OpenTofu substrate under `substrate/`,** one concern per module: VPC (public/private
  subnets, single NAT for cost), EKS control plane + cluster, IAM/IRSA (OIDC provider +
  roles), and a default **CPU node group** (small instance types).
- **Optional GPU node group gated behind a `gpu` variable** (default `false`). When
  `gpu=true`, a GPU node group is added; otherwise no GPU resources are created. The larger
  model / GPU operator are later milestones — M1 only provisions the node group.
- **Wire `just up` / `just plan` / `just down`** to `tofu apply` / `tofu plan` /
  `tofu destroy` for the substrate. `up` surfaces the plan before applying (the M0 dry-run
  convention becomes real). Pin the OpenTofu version and the AWS provider / EKS module
  versions in `docs/architecture.md`.
- **Cost guardrails enforced:** CPU/small path by default, GPU strictly opt-in, a teardown
  TTL habit (default 4h) documented, and `docs/cost.md` updated with the real substrate
  cost lines (control plane, NAT, nodes). `just down` leaves zero billable cluster
  resources while preserving the state bucket.

Non-goals: no in-cluster add-ons (M2 formae), no Argo/GitOps (M3), no vLLM/workload (M4),
no GPU operator or larger model (M4). M1 stops at "ready nodes via `kubectl get nodes`".

## Capabilities

### New Capabilities
- `cloud-substrate`: the OpenTofu-managed AWS substrate — VPC, EKS cluster, IAM/IRSA, a
  default CPU node group, and an optional GPU node group gated by the `gpu` variable.
- `tofu-state`: remote state discipline — S3 backend (versioned, encrypted,
  `use_lockfile`), out-of-band bucket bootstrap, no on-disk/in-cluster state, lock blocks
  concurrent applies, bucket survives teardown.

### Modified Capabilities
- `dev-workflow`: the `up`, `down`, and `plan` recipes stop being echo-only stubs and are
  wired to `tofu apply` / `tofu destroy` / `tofu plan` for the substrate layer; `up`
  surfaces the plan before applying.

## Impact

- New `substrate/` OpenTofu modules; `justfile` recipes `up`/`down`/`plan` gain real bodies.
- New external dependencies: OpenTofu, AWS provider, the EKS module, and an **AWS account**
  (the `ai-infra-lab` member account) with credentials via IAM Identity Center (short-lived
  SSO, no static keys). Requires the `aws` and `tofu` CLIs on PATH (not yet installed).
- **Out-of-band prerequisite:** create the state S3 bucket (`aws s3 mb`, enable versioning,
  block public access) before the first `just up`; record the name in `docs/architecture.md`.
- Real spend begins here — bounded by the $50/mo ceiling and teardown discipline. The most
  expensive failure mode (NAT gateway or GPU node group left running) is guarded by default.
- `docs/architecture.md` (version pins, bucket name) and `docs/cost.md` (substrate cost
  lines) updated within this change; `docs/learnings.md` updated at Ship.

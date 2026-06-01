## 0. Prerequisites (out-of-band, before any apply)

- [ ] 0.1 Confirm `ai-infra-lab` AWS account + IAM Identity Center SSO login; `aws sts get-caller-identity` works
- [ ] 0.2 Install/confirm `aws` and `tofu` (≥1.7) on PATH
- [ ] 0.3 Bootstrap the state bucket out-of-band: `aws s3 mb`, enable versioning, block public access; record the bucket name in `docs/architecture.md`
- [ ] 0.4 Set an AWS Budget alert at $50/mo (foreshadows the M5 budget alert)

## 1. State backend (tofu-state)

- [ ] 1.1 Configure the `substrate/` S3 backend: bucket, key, region, `encrypt = true`, `use_lockfile = true`
- [ ] 1.2 Confirm `.gitignore` already excludes `*.tfstate*` / `*.tflock` (from M0)

## 2. Substrate modules (cloud-substrate)

- [ ] 2.1 VPC module (`terraform-aws-modules/vpc/aws`, pinned): public/private subnets, single NAT
- [ ] 2.2 EKS module (`terraform-aws-modules/eks/aws`, pinned): control plane at a pinned k8s version
- [ ] 2.3 IAM/IRSA: OIDC provider + IRSA-ready roles
- [ ] 2.4 Default CPU managed node group (small instances, desired 2)
- [ ] 2.5 GPU managed node group gated by `variable "gpu"` (`count = var.gpu ? 1 : 0`), with a GPU taint
- [ ] 2.6 Pin OpenTofu, AWS provider, VPC + EKS module, and k8s versions in `docs/architecture.md`

## 3. Task runner wiring (dev-workflow)

- [ ] 3.1 `just plan` → `tofu plan` for `substrate/` (passes `gpu`)
- [ ] 3.2 `just up` → `tofu plan` then `tofu apply`; then `aws eks update-kubeconfig` (kubeconfig never committed)
- [ ] 3.3 `just down` → `tofu destroy` (state bucket preserved)
- [ ] 3.4 `just status` → `kubectl get nodes` + cluster summary (can graduate from stub)

## 4. Docs & cost

- [ ] 4.1 `docs/cost.md`: add real substrate cost lines (control plane, single NAT, CPU nodes; GPU run estimate)
- [ ] 4.2 `docs/architecture.md`: record bucket name, version pins, single-NAT trade-off + HA swap note

## 5. Verification harness (extend the M0 pattern)

- [ ] 5.1 Add `scripts/verify-m1.sh` (or extend the harness) for the M1 scenarios that can run without a live cluster (config validity, `tofu validate`, `tofu fmt -check`)
- [ ] 5.2 Wire `tofu validate` / `tofu fmt -check` into CI for `substrate/`

## 6. Verify (walk acceptance scenarios against real output)

- [ ] 6.1 `just up` (gpu=false) → state in S3 (no on-disk tfstate); `kubectl get nodes` shows Ready CPU nodes, no GPU
- [ ] 6.2 Concurrent `apply` is refused by the lock
- [ ] 6.3 `just up gpu=true` → GPU node group present
- [ ] 6.4 `just down` → no orphaned VPC/NAT/EKS; state bucket remains
- [ ] 6.5 `just down` then `just up` reads clean prior state from S3

## 7. Ship

- [ ] 7.1 Update README/docs inside the change; record learnings in `docs/learnings.md`
- [ ] 7.2 One PR-sized change for M1
- [ ] 7.3 Archive the OpenSpec change (`openspec archive m1-substrate`), folding deltas into `openspec/specs/`

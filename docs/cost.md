# Cost Model & Teardown Discipline

Running cost model and teardown rules for the AI Infrastructure Reference project. Every provisioning decision is weighed against these constraints.

## Monthly ceiling

Projected monthly ceiling is **$50/mo**. Any change — new node group, NAT gateway, data transfer pattern, or always-on service — that would push projected spend above this ceiling must be flagged explicitly in the PR description before merging.

## Idle case

The demo defaults to the CPU/small-model path and is near-free when torn down. The cluster is ephemeral: there is no always-on environment. Cost accrues only during active demo or development runs.

## GPU demo run

GPU inference is strictly opt-in, enabled only by passing `gpu=true` to the provisioning scripts. A GPU demo run is short-lived. Placeholder for real numbers (instance type, $/hr, expected run duration) to be filled in during later milestones once a representative workload is benchmarked.

## Teardown discipline

Every provisioned cluster gets a teardown TTL (default: 4 hours). `just down` is the standard habit after any session. The single most expensive mistake in this stack is leaving a GPU node group or a NAT gateway running overnight — a single NAT gateway left up 8 hours can cost more than an entire week of normal usage.

## Substrate cost lines (M1)

Hourly rates for us-west-2 (on-demand, approximate as of M1; verify against the AWS
pricing page before budgeting).

| Resource | Rate | Notes |
|---|---|---|
| EKS control plane | $0.10/hr | Always on while cluster exists |
| NAT gateway (single) | $0.045/hr | Plus ~$0.045/GB data-processed |
| t3.medium (CPU node) | $0.042/hr each | × 2 nodes in default config |
| g4dn.xlarge (GPU node) | $0.526/hr | `gpu=true` only; not in default config |

**Session cost estimates:**

- CPU session (control plane + NAT + 2× t3.medium): ~$0.23/hr
- GPU session (above + g4dn.xlarge): ~$0.76/hr
- CPU cluster left running 24/7 for 30 days: ~$165/mo — **above the $50/mo ceiling**

**Implication:** the cluster must not be left running. `just down` after every session,
enforced by the default 4-hour teardown TTL. One overnight GPU run is enough to exceed
the monthly ceiling on its own.

## Secrets

Secrets are sourced from AWS SSM Parameter Store (SecureString), surfaced into the cluster via IRSA and the External Secrets Operator. The ESO backend is swappable (HashiCorp Vault, AWS Secrets Manager) without changing application manifests. Credentials, kubeconfigs, and `.tfstate` files are never committed; `.gitignore` enforces this.

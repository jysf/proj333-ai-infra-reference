# Architecture & Decision Record

Living record of stack choices and version pins for the AI Infrastructure Reference project.

## Stack

| Layer | Technology |
|---|---|
| Cloud | AWS EKS |
| Substrate IaC | OpenTofu (VPC, EKS, IAM/IRSA, node groups) |
| Platform layer | formae (Pkl) — in-cluster add-ons, drift capture, AI-modifiable abstractions |
| GitOps | Argo CD (app-of-apps pattern) |
| Inference | vLLM behind a thin FastAPI `/chat` gateway |
| Observability | kube-prometheus-stack + OpenCost |
| Specs | OpenSpec |
| Task runner | just |

## State backend

The OpenTofu remote state for the substrate layer is stored in S3.

| Setting | Value |
|---|---|
| Bucket | `tfstate-proj333-ai-infra-716522590236` |
| Key | `ai-infra-reference/substrate.tfstate` |
| Region | `us-west-2` |
| Encryption | AES-256 (SSE-S3) — `encrypt = true` |
| Locking | Native S3 conditional writes — `use_lockfile = true` |
| Versioning | Enabled |
| Public access | Blocked on all four ACL/policy dimensions |

The bucket is bootstrapped once out-of-band (before the first `tofu apply`) with:

```sh
# Create bucket in us-west-2
aws s3api create-bucket \
  --bucket tfstate-proj333-ai-infra-716522590236 \
  --region us-west-2 \
  --create-bucket-configuration LocationConstraint=us-west-2

# Enable versioning
aws s3api put-bucket-versioning \
  --bucket tfstate-proj333-ai-infra-716522590236 \
  --versioning-configuration Status=Enabled

# Block all public access
aws s3api put-public-access-block \
  --bucket tfstate-proj333-ai-infra-716522590236 \
  --public-access-block-configuration \
    BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true

# Enable default SSE-S3 encryption
aws s3api put-bucket-encryption \
  --bucket tfstate-proj333-ai-infra-716522590236 \
  --server-side-encryption-configuration \
    '{"Rules":[{"ApplyServerSideEncryptionByDefault":{"SSEAlgorithm":"AES256"}}]}'
```

The bucket is intentionally excluded from `tofu destroy` — it must be removed manually if
the project is retired.

## Substrate

The `substrate/` module provisions:

- **VPC**: Three public + three private subnets across three AZs. A **single NAT gateway**
  (cost choice: ~$0.045/hr vs ~$0.135/hr for HA). To switch to HA NAT set
  `single_nat_gateway = false` in the vpc module call before applying to production.
- **EKS 1.35**: Managed node groups only; no self-managed or Fargate nodes.
- **CPU node group**: `t3.medium` × 2, always present.
- **GPU node group**: `g4dn.xlarge` × 1, gated behind `var.gpu = true`. Disabled by
  default to avoid accidental GPU charges.

## Version pins

Every tool and chart version is pinned at first use and recorded here. Never upgrade without updating this table and the corresponding lock/config files.

Versions marked *from lockfile* are approximate lower bounds; the exact patch version is
resolved by `tofu init` and recorded in `substrate/.terraform.lock.hcl`.

| Tool | Version | Pinned at |
|---|---|---|
| actions/checkout | v4 | M0 |
| aquasecurity/trivy-action | v0.36.0 | M0 |
| opentofu/setup-opentofu | v1 | M1 |
| OpenTofu (CLI) | >= 1.7 | M1 |
| hashicorp/aws provider | 5.100.0 (constraint `~> 5.100`, locked in `.terraform.lock.hcl`) | M1 |
| terraform-aws-modules/vpc/aws | 5.21.0 | M1 |
| terraform-aws-modules/eks/aws | 20.37.2 | M1 |
| Kubernetes (EKS) | 1.35 | M1 |

## Trivy high-severity allow-list

The CI Trivy gate fails the build on any HIGH or CRITICAL finding except those explicitly listed here. The machine-enforced list lives in `.trivyignore` at the repo root — that file is what Trivy actually reads. This table is the human-readable companion: it records the justification for every exception so the rationale is reviewable in PRs.

| Finding ID | Reason | Added |
|---|---|---|

To add an entry: (1) add the Trivy check ID to `.trivyignore` at repo root, and (2) add a corresponding row to the table above with a brief justification and the milestone in which it was added. Both changes must land in the same commit.

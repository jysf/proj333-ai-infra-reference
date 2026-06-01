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

## Version pins

Every tool and chart version is pinned at first use and recorded here. Never upgrade without updating this table and the corresponding lock/config files.

| Tool | Version | Pinned at |
|---|---|---|
| actions/checkout | v4 | M0 |
| aquasecurity/trivy-action | v0.36.0 | M0 |

## Trivy high-severity allow-list

The CI Trivy gate fails the build on any HIGH or CRITICAL finding except those explicitly listed here. The machine-enforced list lives in `.trivyignore` at the repo root — that file is what Trivy actually reads. This table is the human-readable companion: it records the justification for every exception so the rationale is reviewable in PRs.

| Finding ID | Reason | Added |
|---|---|---|
| AVD-AWS-0089 | TEMPORARY M0 verification fixture (open SG ingress) — proves allow-list suppression; removed at M0 merge | M0 |

To add an entry: (1) add the Trivy check ID to `.trivyignore` at repo root, and (2) add a corresponding row to the table above with a brief justification and the milestone in which it was added. Both changes must land in the same commit.

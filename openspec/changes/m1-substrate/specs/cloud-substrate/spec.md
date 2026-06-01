## ADDED Requirements

### Requirement: VPC and networking
The substrate SHALL provision a VPC with public and private subnets across multiple
availability zones, with a single NAT gateway for cost (HA NAT is a documented prod swap).
All worker nodes SHALL run in private subnets.

#### Scenario: VPC comes up with private node networking
- **WHEN** `just up` completes
- **THEN** a VPC exists with public and private subnets and a single NAT gateway
- **AND** worker nodes are placed in private subnets

### Requirement: EKS cluster
The substrate SHALL provision an EKS cluster (control plane) at a pinned Kubernetes
version, reachable via a kubeconfig fetched by `aws eks update-kubeconfig`. The kubeconfig
MUST NOT be committed.

#### Scenario: Cluster is reachable after up
- **WHEN** `just up` completes and the kubeconfig is fetched
- **THEN** `kubectl get nodes` returns Ready nodes

### Requirement: IAM and IRSA
The substrate SHALL create the cluster OIDC provider and the IAM roles needed for IRSA, so
in-cluster workloads can assume IAM roles without static credentials.

#### Scenario: OIDC provider and IRSA roles exist
- **WHEN** `just up` completes
- **THEN** an IAM OIDC provider is associated with the cluster
- **AND** IRSA-ready IAM roles exist for cluster service accounts

### Requirement: Default CPU node group
The substrate SHALL provision a managed CPU node group with small instance types as the
default compute, with no GPU resources unless explicitly enabled.

#### Scenario: CPU-only by default
- **WHEN** `just up` is run with `gpu=false` (the default)
- **THEN** `kubectl get nodes` shows Ready CPU nodes
- **AND** no GPU node group and no GPU nodes are present

### Requirement: Optional GPU node group gated by a flag
The substrate SHALL provision a GPU node group only when the `gpu` variable is `true`
(default `false`). The GPU group MUST carry a GPU taint so only GPU workloads schedule onto
it.

#### Scenario: GPU node group present only when enabled
- **WHEN** `just up` is run with `gpu=true`
- **THEN** a GPU node group is present
- **WHEN** `just up` is run with `gpu=false`
- **THEN** no GPU node group exists

### Requirement: Clean teardown
`just down` SHALL destroy all provisioned cluster resources with no orphaned VPC, NAT, or
EKS resources, leaving zero billable cluster resources. The remote state bucket SHALL NOT
be destroyed.

#### Scenario: Down leaves nothing billable but keeps state
- **WHEN** `just down` completes on a running cluster
- **THEN** no VPC, NAT gateway, EKS cluster, or node group resources remain
- **AND** the S3 state bucket still exists

# repo-scaffold Specification

## Purpose
TBD - created by archiving change m0-scaffold. Update Purpose after archive.
## Requirements
### Requirement: Directory layout
The repository SHALL contain the top-level directory layout defined in the Phase 0 spec
(§3): `substrate/`, `platform/`, `gitops/`, `workload/`, `observability/`, `docs/`, and
`.github/workflows/`. Empty layer directories MAY hold a `.gitkeep` so the structure is
present from the first commit.

#### Scenario: Layout exists on a fresh clone
- **WHEN** a fresh clone is inspected with `ls` / `find`
- **THEN** `substrate/`, `platform/`, `gitops/`, `workload/`, `observability/`, `docs/`, and `.github/workflows/` all exist

### Requirement: Agent constitution present
`CLAUDE.md` SHALL exist at the repo root and encode the §4 guardrails: the stack and tool
versions, the Frame→Design→Build→Verify→Ship workflow with OpenSpec discipline, and the
cost/safety guardrails (the `$50/mo` ceiling and secrets sourced from SSM Parameter Store
via IRSA + External Secrets Operator). It MUST contain no unresolved `[PLACEHOLDER]`
tokens.

#### Scenario: Constitution encodes stack, workflow, and guardrails
- **WHEN** `CLAUDE.md` is opened
- **THEN** the stack, the workflow, and the cost guardrails are all present
- **AND** no `[SET_CEILING]` / `[SECRET_STORE]` (or any `[UPPER_CASE]`) placeholder remains

### Requirement: README states the five proof-claims
`README.md` SHALL present the five proof-claims from §1 as section headers, so a prospect
skimming it grasps the asset's claims in under 90 seconds.

#### Scenario: Five proof-claims appear as headers
- **WHEN** `README.md` is opened
- **THEN** the five proof-claims (real LLM workload on Kubernetes; infrastructure-as-code with no drift; GitOps; cost & performance instrumentation; cost discipline / spin-up-prove-tear-down) each appear as a section header

### Requirement: Documentation stubs
`docs/architecture.md`, `docs/cost.md`, and `docs/learnings.md` SHALL exist as stubs.
`docs/architecture.md` MUST include a placeholder for version pins and the Trivy
high-severity allow-list; `docs/cost.md` MUST outline the cost model and teardown
discipline; `docs/learnings.md` MUST provide a running per-milestone log of environment
gotchas, decisions, and process improvements, updated at each milestone's Ship step.

#### Scenario: Docs stubs exist with required sections
- **WHEN** `docs/architecture.md`, `docs/cost.md`, and `docs/learnings.md` are opened
- **THEN** `docs/architecture.md` contains a version-pins section and a documented Trivy allow-list section
- **AND** `docs/cost.md` contains the cost model and teardown-discipline sections
- **AND** `docs/learnings.md` contains a per-milestone learnings log


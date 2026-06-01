## Why

Before any cloud substrate exists, the repository must be a legible, self-describing
skeleton: a prospect skimming it should grasp the five proof-claims in 90 seconds, and an
AI agent (or contributor) starting a session must find the constitution, the task runner,
and the safety rails already in place. M0 establishes that scaffold so every later
milestone (M1–M5) drops into a known structure with dependency hygiene and security
scanning enforced from the first commit — not bolted on later.

## What Changes

- Create the directory layout from the spec (§3): `substrate/`, `platform/`, `gitops/`,
  `workload/`, `observability/`, `docs/`, plus `.github/workflows/` (the `openspec/` and
  `.claude/` trees already exist).
- `CLAUDE.md` is already in place with stack, workflow, and cost guardrails (ceiling
  `$50/mo`; secrets from SSM Parameter Store via IRSA + External Secrets Operator) — M0
  verifies it satisfies the §4 requirements.
- Add a `justfile` exposing `up`, `down`, `status`, `cost`, `load`, and `plan` as recipes
  (stubs that echo intent; real wiring lands in later milestones). `plan` is the dry-run
  preview sibling of `up`, establishing the "plan before apply" convention from the start.
- Add a `README.md` whose section headers are the §1 five proof-claims.
- Add `docs/architecture.md` (decision record + version pins + Trivy allow-list) and
  `docs/cost.md` (cost model + teardown discipline) as stubs.
- Add `renovate.json` for automated dependency PRs (chart, provider, action versions).
- Add `.github/workflows/security.yml` running Trivy against IaC (and images when present)
  on pull requests, failing on high-severity findings outside a documented allow-list.

Non-goals: no cloud resources, no OpenTofu/formae/Argo config, no live infrastructure.
M0 is pure scaffold.

## Capabilities

### New Capabilities
- `repo-scaffold`: the directory layout from §3, the `CLAUDE.md` constitution, the
  `README.md` whose headers are the five proof-claims, and the `docs/` stubs
  (`architecture.md`, `cost.md`).
- `dev-workflow`: the `justfile` task runner exposing `up`, `down`, `status`, `cost`,
  `load`, and `plan` as discoverable recipes, with a dry-run/plan-before-apply convention
  for mutating recipes.
- `dependency-automation`: `renovate.json` enabling automated dependency-update PRs across
  Helm charts, IaC providers, and GitHub Actions.
- `security-scanning`: the `.github/workflows/security.yml` CI workflow that runs Trivy on
  PRs and fails on high-severity findings outside a documented allow-list.

### Modified Capabilities
<!-- None — this is the first change; no existing specs to modify. -->

## Impact

- New files only; no existing behavior changes (greenfield repo).
- Adds a GitHub Actions dependency (Trivy action) and a Renovate dependency (requires the
  Renovate GitHub App enabled on the repo).
- Establishes the structure and conventions every subsequent milestone (M1–M5) builds on.
- Affected systems: the GitHub repository (Actions, Renovate app); no cloud account impact.

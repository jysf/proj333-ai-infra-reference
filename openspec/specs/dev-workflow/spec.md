# dev-workflow Specification

## Purpose
TBD - created by archiving change m0-scaffold. Update Purpose after archive.
## Requirements
### Requirement: justfile exposes the core recipes
A `justfile` at the repo root SHALL define the recipes `up`, `down`, `status`, `cost`,
`load`, `plan`, and `test`, each discoverable via `just --list`. In M0 the provisioning
recipes MAY be stubs that echo their intent (real wiring lands in later milestones), but
`test` MUST be real (it runs the acceptance harness), and every recipe MUST be present and
listed.

#### Scenario: just --list shows the core recipes
- **WHEN** `just --list` is run from a fresh clone
- **THEN** `up`, `down`, `status`, `cost`, `load`, `plan`, and `test` are all listed

### Requirement: Acceptance is executable and CI-enforced
The M0 acceptance scenarios SHALL be executable as a single command (`just test`, running
`scripts/verify-m0.sh`) that checks each scenario against real output and exits non-zero on
any failure. The harness MUST also run in CI on every pull request, so acceptance is
enforced automatically rather than checked by hand.

#### Scenario: The harness passes on a correct scaffold
- **WHEN** `just test` is run from the repo root on a correctly scaffolded repo
- **THEN** every check prints PASS and the command exits 0

#### Scenario: CI runs the harness on pull requests
- **WHEN** a pull request is opened
- **THEN** a CI workflow runs `scripts/verify-m0.sh` and fails the check if any acceptance check fails

### Requirement: Mutating recipes have a dry-run preview
The task runner SHALL provide a no-mutation preview of changes before they are applied, so
the "plan before apply" guardrail in `CLAUDE.md` is enforceable through one consistent
verb. `plan` is the dry-run sibling of `up`; as the substrate, platform, and GitOps layers
land, `plan` maps to each layer's native dry-run (`tofu plan`, formae `simulate=true`,
`argocd app diff`) and `up` SHALL surface the plan before applying.

#### Scenario: A plan recipe previews changes without mutating
- **WHEN** `just plan` is run
- **THEN** the intended changes are previewed and no infrastructure is created, modified, or destroyed


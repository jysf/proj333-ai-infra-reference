## MODIFIED Requirements

### Requirement: justfile exposes the core recipes
A `justfile` at the repo root SHALL define the recipes `up`, `down`, `status`, `cost`,
`load`, `plan`, and `test`, each discoverable via `just --list`. As of M1, `up`, `down`,
and `plan` SHALL be wired to the substrate layer — `up` runs `tofu plan` then `tofu apply`,
`down` runs `tofu destroy`, and `plan` runs `tofu plan` — passing the `gpu` variable
through. `status`, `cost`, and `load` MAY remain stubs until their milestones; `test` MUST
be real (it runs the acceptance harness). Every recipe MUST be present and listed.

#### Scenario: just --list shows the core recipes
- **WHEN** `just --list` is run from a fresh clone
- **THEN** `up`, `down`, `status`, `cost`, `load`, `plan`, and `test` are all listed

#### Scenario: up and plan are wired to the substrate
- **WHEN** `just plan` is run
- **THEN** it executes `tofu plan` for the `substrate/` configuration and previews changes without applying
- **WHEN** `just up` is run
- **THEN** it surfaces the plan and then applies the substrate via `tofu apply`

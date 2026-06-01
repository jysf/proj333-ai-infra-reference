## 1. Directory layout (repo-scaffold)

- [x] 1.1 Create `substrate/`, `platform/`, `gitops/`, `workload/`, `observability/` with a `.gitkeep` in each
- [x] 1.2 Create `docs/` and `.github/workflows/` directories
- [x] 1.3 Confirm `CLAUDE.md` exists at root with stack, workflow, and cost guardrails, and no `[UPPER_CASE]` placeholder remains

## 2. README and docs stubs (repo-scaffold)

- [x] 2.1 Write `README.md` with the five §1 proof-claims as section headers (LLM-on-K8s; IaC no-drift; GitOps; cost & performance instrumentation; cost discipline / spin-up-prove-tear-down)
- [x] 2.2 Write `docs/architecture.md` stub with a version-pins section and a documented Trivy high-severity allow-list section
- [x] 2.3 Write `docs/cost.md` stub with the cost model (idle + GPU demo run) and teardown-discipline sections
- [x] 2.4 Write `docs/learnings.md` running per-milestone log; wire it into the Ship step in `CLAUDE.md`

## 3. Task runner (dev-workflow)

- [x] 3.1 Create `justfile` with `up`, `down`, `status`, `cost`, `load`, `plan` recipes (echo-only stubs, each noting the milestone that implements it)
- [x] 3.2 Make `plan` the dry-run sibling of `up`; note in the stub that `up` will surface the plan before applying (maps to `tofu plan` / formae `simulate` / `argocd app diff` per layer)
- [x] 3.3 Run `just --list` and confirm all six recipes are listed

## 4. Dependency automation (dependency-automation)

- [x] 4.1 Write `renovate.json` extending `config:recommended`, with managers for Helm charts, OpenTofu/Terraform providers, and github-actions
- [x] 4.2 Validate `renovate.json` (valid JSON; `npx --yes renovate-config-validator`)
- [x] 4.3 Record "enable the Renovate GitHub App on the repo" as a ship-time checklist item

## 5. Security scanning (security-scanning)

- [x] 5.1 Write `.github/workflows/security.yml` running `aquasecurity/trivy-action` in `config` mode on pull requests, `exit-code: 1` on `HIGH,CRITICAL`
- [x] 5.2 Guard image scanning to run only when an image/Dockerfile is present
- [x] 5.3 Wire the allow-list: `.trivyignore` (or trivyignore config) referenced by the workflow and mirrored in the `docs/architecture.md` allow-list section
- [x] 5.4 Lint/validate the workflow YAML (`actionlint` or equivalent)

## 5b. Verification harness (dev-workflow)

- [x] 5b.1 Write `scripts/verify-m0.sh` (POSIX `sh`, `set -eu`) that runs each acceptance scenario as a real check, printing PASS/FAIL and exiting non-zero on first failure
- [x] 5b.2 Add a real `just test` recipe that runs the harness
- [x] 5b.3 Add `.github/workflows/ci.yml` that runs the harness on every PR (installs `just`, `jq`, `python3`/pyyaml)

## 6. Verify (walk the acceptance scenarios against real output)

- [x] 6.1 Scenario 1 — `just --list` shows `up/down/status/cost/load/plan`; `just plan` previews without mutating
- [x] 6.2 Scenario 2 — `README.md` shows the five proof-claims as headers
- [x] 6.3 Scenario 3 — `CLAUDE.md` shows stack, workflow, cost guardrails; no placeholders
- [x] 6.4 Scenario 4 — `renovate.json` validates clean (`renovate-config-validator`: "Config validated successfully"). NOTE: onboarding-PR confirmation pending the Renovate GitHub App being enabled (user action)
- [x] 6.5 Scenario 5 — Trivy gate fails on a deliberately-bad IaC fixture, and an allow-listed entry suppresses it (observe real CI output, then remove the fixture)
- [x] 6.6 Confirm directory layout exists on a fresh `git clone`

## 7. Ship

- [x] 7.1 Update `README.md` / `docs/` with anything learned during build (per the workflow, docs ship inside the change)
- [x] 7.2 One PR-sized change for M0 (PR #1; verification commits to be squash-merged into one)
- [x] 7.3 Archive the OpenSpec change (`openspec archive m0-scaffold`), folding deltas into `openspec/specs/`

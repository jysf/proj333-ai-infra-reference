## Context

Greenfield repository that will grow into a public AI-infrastructure reference
architecture (M1–M5). `CLAUDE.md` (constitution), `LICENSE`, and the `openspec/` and
`.claude/` trees already exist. M0 adds the remaining skeleton so later milestones drop
into a known structure with dependency hygiene and security scanning enforced from the
first PR. No cloud account is touched in M0; the only external systems are GitHub Actions
and the Renovate GitHub App.

## Goals / Non-Goals

**Goals:**
- A self-describing repo: directory layout (§3), a README whose headers are the five
  proof-claims, and `docs/` stubs (architecture decision record + cost model).
- A one-command developer surface: `just --list` shows `up/down/status/cost/load`.
- Dependency hygiene from day one: `renovate.json` valid and scoped to charts, IaC
  providers, and Actions.
- Security gate from day one: Trivy on PRs, failing on high-severity outside a documented
  allow-list.

**Non-Goals:**
- No cloud resources, no OpenTofu/formae/Argo/vLLM config, no live infrastructure.
- `just` recipes are stubs in M0; real provisioning wiring lands in M1+.
- No model/runtime selection — that is M4.

## Decisions

- **`just` recipes are echo-only stubs in M0.** Rationale: the acceptance scenario only
  requires the recipes to be present and listed by `just --list`; real `up`/`down` need
  the M1 substrate. Stubs that echo intent keep the milestone PR-sized and honest about
  what works. Alternative — wiring real commands now — was rejected: it couples M0 to M1
  and breaks the "one milestone = one change" discipline.
- **Dry-run as a first-class `just plan` recipe.** Rationale: makes the CLAUDE.md "plan
  before apply" guardrail real and demoable (README claim #5) instead of aspirational, and
  establishes the convention in the scaffold so later milestones inherit it rather than
  retrofit. In M0 `plan` is an echo-only stub; as each layer lands it maps to that layer's
  native dry-run, and `up` surfaces the plan before applying:

  | Layer | Native dry-run | Lands in |
  | --- | --- | --- |
  | OpenTofu | `tofu plan` | M1 |
  | formae | `simulate=true` | M2 |
  | Argo CD | `argocd app diff` | M3 |
  | kubectl | `--dry-run=server` | as used |

  Chose a standalone `just plan` recipe over a `--dry-run` flag/variable (`just up
  dry_run=true`) because `just` has no idiomatic flag support and a named recipe is more
  discoverable in `just --list`. Alternative — defer dry-run to M1 — rejected: folding the
  one-line stub in now is cheaper than retrofitting the convention across M1–M3.
- **`.gitkeep` in empty layer directories.** Rationale: git does not track empty dirs;
  `.gitkeep` makes the §3 structure real on a fresh clone (the testable assertion).
  Alternative — a README in each dir — is heavier than needed at M0.
- **Trivy via the official `aquasecurity/trivy-action` in GitHub Actions, `config` scan
  for IaC, with `exit-code: 1` on `HIGH,CRITICAL`.** Allow-list of accepted findings is
  documented in `docs/architecture.md` and enforced via `.trivyignore` (or trivyignore
  config) referenced from the workflow, so the "allow-list" is both human-readable and
  machine-enforced. Alternative — a third-party action or kubescape — rejected to keep the
  recognizable, SOC-2-flavored story (per §2 stack table) and minimize deps.
- **Image scanning is conditional.** M0 has no images, so the workflow scans IaC now and is
  written to also scan images "when present" (guarded), avoiding a failing/empty image
  scan today while satisfying the spec's "and images when present" clause.
- **Renovate scoped to charts, IaC providers, and Actions.** Uses Renovate's
  `config:recommended` base plus managers for Helm, Terraform/OpenTofu, and
  github-actions. Requires the Renovate GitHub App enabled on the repo (an out-of-band,
  one-click step recorded in the verify notes).

## Risks / Trade-offs

- **Renovate enablement is out-of-band.** The `renovate.json` can be valid yet produce no
  PRs until the GitHub App is installed on the repo. → Mitigation: verify config validity
  in CI/locally, and record "enable Renovate app" as an explicit ship-time checklist item;
  treat the "opens PRs" scenario as satisfied once the app is enabled and a first
  onboarding PR appears.
- **Trivy `config` scan finds little on a near-empty repo.** A green check now does not
  prove it would fail on a real misconfig. → Mitigation: verify the gate with a
  deliberately-bad fixture (or a dry-run against a known-bad snippet) so we observe a real
  failure, then confirm an allow-listed entry suppresses it — real output, not assertion.
- **Echo-only `just` recipes could read as "done" when they are not.** → Mitigation: each
  stub echoes that it is a stub and references the milestone that implements it.

## Migration Plan

Additive, greenfield — no migration or rollback of existing behavior. Ships as one
PR-sized commit; rollback is reverting that commit. The OpenSpec change is archived into
`openspec/specs/` at ship time per the workflow.

## Open Questions

- None blocking. (Renovate app enablement and the Trivy allow-list seed are handled in the
  Verify/Ship steps.)

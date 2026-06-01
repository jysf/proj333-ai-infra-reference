# Learnings Log

A running record of what we learned each milestone — environment gotchas, decisions and
their rationale, and process improvements to fold back into how we work. Updated at the
**Ship** step of every milestone (see `CLAUDE.md` → "How we work"). The point is a tight
feedback loop: a lesson here should change the next milestone's behavior.

---

## M0 — Scaffold

### Environment
- **Repo location:** the working repo is `proj333-ai-infra-reference/` (a git repo with its
  own `openspec/`); an earlier copy in the parent dir was just staging.
- **Broken Homebrew node:** `/opt/homebrew/bin/node` is missing `libsimdjson.29.dylib`, so
  the `openspec` CLI (`#!/usr/bin/env node`) fails when it resolves Homebrew's node. Run
  openspec under nvm node (`/Users/jyashinsky/.nvm/versions/node/v22.17.0/bin`). Fix when
  convenient: `brew reinstall simdjson node`.

### Decisions
- **Cost ceiling: $50/mo** — a guardrail enforced by teardown discipline, not a 24/7 budget.
  Raisable as traction grows.
- **Cloud: AWS EKS** as the build target (credibility substrate for the target SF-founder
  audience); **GKE Autopilot** (free first cluster) and **DigitalOcean DOKS** (free control
  plane) documented in `docs/cost.md` as cheaper alternatives — DO is cheapest but weakest
  for the AWS-shop story.
- **Secrets: AWS SSM Parameter Store (SecureString)** via IRSA + External Secrets Operator;
  backend swappable behind ESO (keeps us portable if we leave AWS). Free vs Secrets Manager.
- **AWS account structure:** dedicated `ai-infra-lab` member account under Organizations,
  plus-addressed email (`...+ai-infra-lab@gmail.com`), IAM Identity Center for short-lived
  SSO creds (no static keys), root locked with MFA. Isolated billing + clean teardown.

### Process
- **Delegated the build to parallel `sonnet` subagents** (one per capability group) to
  conserve the main session's context and use a cost-appropriate model for well-specified
  boilerplate. Worked well; verification stayed in the main session where judgment matters.
- **Verification tooling must be portable across local + CI.** The acceptance harness
  (`scripts/verify-m0.sh`) initially failed locally because this machine's `python3` lacks
  `pyyaml` — a false negative, not a real YAML error. Fixed by making the YAML check fall
  back to `ruby`/psych. Lesson: a "proper" test asserts the thing, not the presence of one
  particular tool.
- **Some acceptance scenarios are only verifiable post-push.** The Trivy gate (fail on
  HIGH/CRITICAL) and Renovate's PRs need GitHub (CI / the App). Plan to prove those on the
  milestone PR, not locally.
- **A local harness can't validate upstream tags.** First CI run failed because the pinned
  `aquasecurity/trivy-action@0.28.0` doesn't resolve — the real tags are `v`-prefixed
  (`v0.36.0`). The harness parsed the YAML fine but has no way to know a tag exists on
  GitHub. Lesson: action/chart version pins are only truly verified once CI resolves them;
  treat the first green CI run as part of acceptance, and pin to tags copied from the
  upstream releases page (`gh api repos/<owner>/<repo>/tags`), not from memory.

- **Proved the Trivy gate both directions on the PR.** A throwaway IaC fixture (open
  security group) made the gate fail (AVD-AWS-0089 CRITICAL + AVD-AWS-0107 HIGH); allow-
  listing BOTH IDs in `.trivyignore` flipped it green; removing the fixture + entries
  restored a clean pass. Nuance: a single bad resource can trip multiple AVD checks — the
  allow-list must cover every finding ID, not just the first one seen in the log.

### To fold into the process
- Adopted this learnings log; recording it at Ship is now part of "How we work".
- Keep the harness pattern (`just test` + a CI workflow) for every milestone, extending the
  checks as new layers land.

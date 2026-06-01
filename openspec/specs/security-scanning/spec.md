# security-scanning Specification

## Purpose
TBD - created by archiving change m0-scaffold. Update Purpose after archive.
## Requirements
### Requirement: Trivy scanning on pull requests
A `.github/workflows/security.yml` GitHub Actions workflow SHALL run Trivy on pull
requests, scanning the IaC for misconfiguration (and container images when present). The
workflow MUST fail the check on high-severity (and above) findings, except for findings
covered by an allow-list documented in `docs/architecture.md`.

#### Scenario: Trivy fails on high-severity findings
- **WHEN** a pull request is opened and the security workflow runs
- **THEN** Trivy scans the IaC for misconfiguration
- **AND** the check fails if any high-severity (or critical) finding exists outside the documented allow-list

#### Scenario: Allow-listed findings do not fail the build
- **WHEN** a finding is present that is listed in the `docs/architecture.md` allow-list
- **THEN** that finding does not fail the check


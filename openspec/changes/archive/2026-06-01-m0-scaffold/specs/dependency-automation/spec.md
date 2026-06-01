## ADDED Requirements

### Requirement: Renovate configuration
A valid `renovate.json` SHALL exist at the repo root, configured to open automated
update PRs for outdated dependencies across the dimensions this project tracks: Helm
chart versions, IaC provider versions, and GitHub Actions versions. The configuration
MUST parse as valid Renovate config (valid JSON, recognized schema).

#### Scenario: Renovate opens PRs for outdated versions
- **WHEN** Renovate runs against the repository
- **THEN** it opens pull requests for outdated Helm chart, IaC provider, and GitHub Action versions

#### Scenario: Configuration is valid
- **WHEN** `renovate.json` is validated (valid JSON against the Renovate schema)
- **THEN** validation passes with no errors

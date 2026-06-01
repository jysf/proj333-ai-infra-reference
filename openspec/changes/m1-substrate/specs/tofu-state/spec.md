## ADDED Requirements

### Requirement: Remote S3 state backend
The `substrate/` OpenTofu configuration SHALL use an S3 backend with bucket versioning,
`encrypt = true`, and native locking (`use_lockfile = true`, OpenTofu ≥ 1.7 — no DynamoDB).
State MUST NOT be written to disk or stored in-cluster.

#### Scenario: State lands in S3, not on disk
- **WHEN** `just up` is run with the backend configured
- **THEN** the OpenTofu state is written to the S3 bucket
- **AND** no `*.tfstate` file is left on local disk

### Requirement: Out-of-band state bucket bootstrap
The state bucket SHALL be created out-of-band before the first apply (it cannot be managed
by the configuration whose state it stores), with versioning enabled and public access
blocked. The bucket name SHALL be recorded in `docs/architecture.md`.

#### Scenario: Bucket bootstrap is documented and recorded
- **WHEN** `docs/architecture.md` is opened
- **THEN** it documents the out-of-band bucket bootstrap steps and records the bucket name

### Requirement: State locking blocks concurrent applies
The native S3 lock SHALL prevent two applies from mutating state at once.

#### Scenario: Concurrent apply is refused
- **WHEN** an apply is in progress and a second concurrent `apply` is attempted
- **THEN** the second apply is refused by the lock

### Requirement: State survives teardown
The state bucket and its versioned contents SHALL persist across a `just down` / `just up`
cycle, so the next `up` reads clean prior state.

#### Scenario: Bucket persists after down
- **WHEN** `just down` destroys the cluster
- **THEN** the state bucket and its version history remain intact

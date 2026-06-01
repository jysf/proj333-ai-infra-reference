# Show available recipes
default:
    @just --list

# Provision the substrate + platform (real wiring lands in M1+)
up:
    @echo "Will run a plan first, then apply to provision the substrate + platform (M1+)"

# Tear down all provisioned cluster resources (M1+)
down:
    @echo "Will tear down all provisioned cluster resources (M1+)"

# Show cluster and workload state (M1+)
status:
    @echo "Will show cluster and workload state (M1+)"

# Show current OpenCost / estimated spend (M5)
cost:
    @echo "Will show current OpenCost / estimated spend (M5)"

# Drive sustained k6 load and save a summary (M4)
load:
    @echo "Will drive sustained k6 load and save a summary (M4)"

# DRY-RUN preview of changes, mutating nothing. The plan-before-apply sibling of `up`. Maps to `tofu plan` (M1), formae simulate=true (M2), `argocd app diff` (M3) as layers land.
plan:
    @echo "Dry-run preview of changes — no changes applied (M1/M2/M3)"

# Run the M0 acceptance verification harness
test:
    @sh scripts/verify-m0.sh

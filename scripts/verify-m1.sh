#!/bin/sh
set -eu

# ---------------------------------------------------------------------------
# M1 acceptance verification harness
# Run from repo root: sh scripts/verify-m1.sh
# Prints PASS/FAIL for each check; exits non-zero on first failure.
# Does NOT require a live cluster or AWS credentials.
# ---------------------------------------------------------------------------

_pass() {
    printf 'PASS: %s\n' "$1"
}

_fail() {
    printf 'FAIL: %s\n' "$1" >&2
    exit 1
}

# ---------------------------------------------------------------------------
# Check 1 — substrate/ required files exist
# ---------------------------------------------------------------------------
DESC="substrate/ contains required OpenTofu files"
for f in substrate/versions.tf substrate/variables.tf substrate/vpc.tf substrate/eks.tf substrate/outputs.tf; do
    if [ ! -f "./${f}" ]; then
        _fail "${DESC} — missing: ${f}"
    fi
done
_pass "${DESC}"

# ---------------------------------------------------------------------------
# Check 2 — S3 backend block with correct bucket and use_lockfile
# ---------------------------------------------------------------------------
DESC="substrate/versions.tf declares S3 backend with correct bucket and use_lockfile"
if ! grep -q 'backend "s3"' ./substrate/versions.tf; then
    _fail "${DESC} — no S3 backend block found in substrate/versions.tf"
fi
if ! grep -q 'tfstate-proj333-ai-infra-716522590236' ./substrate/versions.tf; then
    _fail "${DESC} — state bucket name not found in substrate/versions.tf"
fi
if ! grep -q 'use_lockfile' ./substrate/versions.tf; then
    _fail "${DESC} — 'use_lockfile' not found in substrate/versions.tf"
fi
_pass "${DESC}"

# ---------------------------------------------------------------------------
# Check 3 — gpu variable declared with default = false
# ---------------------------------------------------------------------------
DESC="substrate/variables.tf declares gpu variable defaulting to false"
if ! grep -q 'variable "gpu"' ./substrate/variables.tf; then
    _fail "${DESC} — 'variable \"gpu\"' not found in substrate/variables.tf"
fi
if ! grep -q 'default *= *false' ./substrate/variables.tf; then
    _fail "${DESC} — 'default = false' not found in substrate/variables.tf"
fi
_pass "${DESC}"

# ---------------------------------------------------------------------------
# Check 4 — tofu fmt -check passes
# ---------------------------------------------------------------------------
DESC="tofu fmt -check -recursive passes on substrate/"
if ! command -v tofu >/dev/null 2>&1; then
    _fail "${DESC} — 'tofu' not found in PATH"
fi
if ! tofu -chdir=substrate fmt -check -recursive; then
    _fail "${DESC} — formatting issues detected; run: tofu -chdir=substrate fmt -recursive"
fi
_pass "${DESC}"

# ---------------------------------------------------------------------------
# Check 5 — tofu validate passes (backend-free init)
# ---------------------------------------------------------------------------
DESC="tofu validate passes on substrate/ (backend=false)"
if ! command -v tofu >/dev/null 2>&1; then
    _fail "${DESC} — 'tofu' not found in PATH"
fi
if ! tofu -chdir=substrate init -backend=false -reconfigure -input=false >/dev/null; then
    _fail "${DESC} — 'tofu init -backend=false' failed"
fi
if ! tofu -chdir=substrate validate; then
    _fail "${DESC} — 'tofu validate' failed"
fi
_pass "${DESC}"

# ---------------------------------------------------------------------------
# Check 6 — just --list still lists all required recipes
# ---------------------------------------------------------------------------
DESC="justfile recipes: up down status cost load plan test are listed"
if ! command -v just >/dev/null 2>&1; then
    _fail "${DESC} — 'just' not found in PATH"
fi
JUST_LIST="$(just --list 2>&1)"
for recipe in up down status cost load plan test; do
    if ! printf '%s\n' "${JUST_LIST}" | grep -qw "${recipe}"; then
        _fail "${DESC} — recipe not listed: '${recipe}'"
    fi
done
_pass "${DESC}"

# ---------------------------------------------------------------------------
# All checks passed
# ---------------------------------------------------------------------------
printf 'ALL M1 CHECKS PASSED\n'

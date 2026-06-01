#!/bin/sh
set -eu

# ---------------------------------------------------------------------------
# M0 acceptance verification harness
# Run from repo root: sh scripts/verify-m0.sh
# Prints PASS/FAIL for each check; exits non-zero on first failure.
# ---------------------------------------------------------------------------

_pass() {
    printf 'PASS: %s\n' "$1"
}

_fail() {
    printf 'FAIL: %s\n' "$1" >&2
    exit 1
}

# ---------------------------------------------------------------------------
# Check 1 — Directory layout
# ---------------------------------------------------------------------------
DESC="Directory layout: required top-level directories exist"
for dir in substrate platform gitops workload observability docs; do
    if [ ! -d "./${dir}" ]; then
        _fail "${DESC} — missing: ${dir}/"
    fi
done
_pass "${DESC}"

# ---------------------------------------------------------------------------
# Check 1b — Required documentation stubs exist
# ---------------------------------------------------------------------------
DESC="Documentation stubs exist (architecture, cost, learnings)"
for doc in docs/architecture.md docs/cost.md docs/learnings.md; do
    if [ ! -f "./${doc}" ]; then
        _fail "${DESC} — missing: ${doc}"
    fi
done
_pass "${DESC}"

# ---------------------------------------------------------------------------
# Check 2 — README proof-claim headers
# ---------------------------------------------------------------------------
DESC="README.md contains all five proof-claim headers"
if [ ! -f "./README.md" ]; then
    _fail "${DESC} — README.md not found"
fi
for claim in \
    "real LLM workload" \
    "no drift" \
    "GitOps" \
    "cost and performance" \
    "Cost discipline"
do
    if ! grep -qi "${claim}" "./README.md"; then
        _fail "${DESC} — missing claim: '${claim}'"
    fi
done
_pass "${DESC}"

# ---------------------------------------------------------------------------
# Check 3 — CLAUDE.md guardrails
# ---------------------------------------------------------------------------
DESC="CLAUDE.md contains required guardrail substrings and no unresolved placeholders"
if [ ! -f "./CLAUDE.md" ]; then
    _fail "${DESC} — CLAUDE.md not found"
fi
for substr in "Stack" "How we work" '$50/mo'; do
    if ! grep -qF "${substr}" "./CLAUDE.md"; then
        _fail "${DESC} — missing substring: '${substr}'"
    fi
done
# Fail if any unresolved placeholder of the form [UPPER_CASE] exists
if grep -qE '\[[A-Z_]+\]' "./CLAUDE.md"; then
    _fail "${DESC} — unresolved placeholder(s) found in CLAUDE.md"
fi
_pass "${DESC}"

# ---------------------------------------------------------------------------
# Check 4 — justfile recipes
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
# Check 5 — Dry-run convention: `plan` is a no-mutation preview
# Creds-free static check (M1 wires `plan` to `tofu plan`, which needs AWS
# creds; M0 used an echo stub). Either form satisfies the convention.
# ---------------------------------------------------------------------------
DESC="justfile 'plan' recipe is a no-mutation dry-run (tofu plan or stub echo)"
if ! grep -Eq '^plan( |:)' justfile; then
    _fail "${DESC} — no 'plan' recipe found in justfile"
fi
if ! grep -Eq 'tofu .*plan|no changes applied' justfile; then
    _fail "${DESC} — 'plan' recipe is neither wired to 'tofu plan' nor a no-changes stub"
fi
_pass "${DESC}"

# ---------------------------------------------------------------------------
# Check 6 — renovate.json is valid JSON
# ---------------------------------------------------------------------------
DESC="renovate.json is valid JSON"
if ! command -v jq >/dev/null 2>&1; then
    _fail "${DESC} — 'jq' not found in PATH"
fi
if [ ! -f "./renovate.json" ]; then
    _fail "${DESC} — renovate.json not found"
fi
if ! jq empty ./renovate.json >/dev/null 2>&1; then
    _fail "${DESC} — renovate.json failed jq validity check"
fi
_pass "${DESC}"

# ---------------------------------------------------------------------------
# Check 7 — GitHub workflow files exist and parse as valid YAML
# Parser-portable: prefer python3+pyyaml, fall back to ruby/psych. Both are
# available on macOS and on ubuntu-latest CI runners.
# ---------------------------------------------------------------------------
DESC="GitHub workflow files exist and parse as valid YAML"

# _yaml_load <file> : returns 0 if YAML is valid, 1 if invalid, 2 if no parser.
_yaml_load() {
    if python3 -c 'import yaml' >/dev/null 2>&1; then
        python3 -c "import yaml,sys; yaml.safe_load(open(sys.argv[1]))" "$1" >/dev/null 2>&1
    elif command -v ruby >/dev/null 2>&1; then
        ruby -ryaml -e "YAML.load_file(ARGV[0])" "$1" >/dev/null 2>&1
    else
        return 2
    fi
}

for wf in ".github/workflows/security.yml" ".github/workflows/ci.yml"; do
    if [ ! -f "${wf}" ]; then
        _fail "${DESC} — missing: ${wf}"
    fi
    _yaml_load "${wf}"
    rc=$?
    if [ "${rc}" -eq 2 ]; then
        _fail "${DESC} — no YAML parser available (need python3+pyyaml or ruby)"
    elif [ "${rc}" -ne 0 ]; then
        _fail "${DESC} — YAML parse failed for: ${wf}"
    fi
done
_pass "${DESC}"

# ---------------------------------------------------------------------------
# Check 8 — .trivyignore exists and security.yml references it
# ---------------------------------------------------------------------------
DESC=".trivyignore exists and .github/workflows/security.yml references it"
if [ ! -f "./.trivyignore" ]; then
    _fail "${DESC} — .trivyignore not found"
fi
if ! grep -q "trivyignore" ".github/workflows/security.yml"; then
    _fail "${DESC} — security.yml does not reference trivyignore"
fi
_pass "${DESC}"

# ---------------------------------------------------------------------------
# All checks passed
# ---------------------------------------------------------------------------
printf 'ALL CHECKS PASSED\n'

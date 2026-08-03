#!/usr/bin/env bash
# Test staffing-score.py — the ranked-shortlist scorer.
#
# Covers:
#   A. a clean portfolio scores, pinning the counts B compares against,
#   B. an entity record that is not valid UTF-8 is skipped like any other
#      unreadable one — the run still returns its {success, data, error}
#      envelope rather than a bare traceback,
#   C. usage and preflight errors still report through that envelope, so B
#      cannot be satisfied by swallowing every failure.
#
# stdlib-only (bash + python3, no pytest/pip), matching the house convention.
#
# Usage: bash cogni-projects/tests/test_staffing_score.sh
# Exits non-zero on any assertion failure.

set -u  # NOT -e: a failing assertion must not abort the per-fixture counter.

TESTS_DIR="$(cd "$(dirname "$0")" && pwd)"
PLUGIN_DIR="$(cd "$TESTS_DIR/.." && pwd)"
SCRIPT="$PLUGIN_DIR/scripts/staffing-score.py"

if [ ! -f "$SCRIPT" ]; then
  echo "FAIL: staffing-score.py not found at $SCRIPT" >&2
  exit 1
fi

TMPROOT="$(mktemp -d)"
trap 'rm -rf "$TMPROOT"' EXIT

failures=0
pass() { printf 'OK   %s\n' "$1"; }
fail() { printf 'FAIL %s: %s\n' "$1" "$2" >&2; failures=$((failures + 1)); }

# assert_json <label> <python-bool-expr over `d`> — pipes the last stdout line
# (the envelope) into python3 and checks the expression is truthy.
assert_json() {
  local label="$1" expr="$2"
  if printf '%s' "$LAST_JSON" | python3 -c "import json,sys
d = json.loads(sys.stdin.read())
sys.exit(0 if ($expr) else 1)" 2>/dev/null; then
    pass "$label"
  else
    fail "$label" "expr false: $expr | json=$LAST_JSON"
  fi
}

# The crash signature belongs in one place — widening it later should be one
# edit. This is the assertion the whole suite exists for.
assert_no_traceback() {
  local label="$1" file="$2"
  if grep -qF 'Traceback' "$file"; then
    fail "$label" "traceback present: $(head -3 "$file")"
  else
    pass "$label"
  fi
}

assert_exit() {
  local label="$1" want="$2" got="$3"
  if [ "$want" = "$got" ]; then
    pass "$label"
  else
    fail "$label" "want exit $want, got $got"
  fi
}

seed_portfolio() {
  # $1 = portfolio dir. Seeds a manifest + entity subdirs. The manifest's ref
  # lists stay empty on purpose: _load_entities then falls back to scanning the
  # subdirectories, which is the path a hand-authored record takes.
  local pf="$1"
  mkdir -p "$pf"/{consultants,projects,assignments,.metadata}
  cat > "$pf/projects-portfolio.json" <<'EOF'
{"slug":"test","name":"Test Portfolio","language":"en","consultants":[],"projects":[],"assignments":[],"created":"2026-01-01","updated":"2026-01-01"}
EOF
}

write_entity() { # $1 = path; body heredoc'd by the caller on stdin
  cat > "$1"
}

# run_score <stderr-file> [args...] — invoke the scorer, setting LAST_JSON to the
# last stdout line (the envelope) and RUN_CODE to the script's own exit status.
# Redirecting to a file rather than piping into `tail` is load-bearing: after a
# `$(... | tail -n 1)` substitution, `$?` is tail's status, which is always 0, so
# every exit-code assertion would pass vacuously.
run_score() {
  local errfile="$1"; shift
  local outfile="$TMPROOT/stdout.txt"
  python3 "$SCRIPT" "$@" >"$outfile" 2>"$errfile"
  RUN_CODE=$?
  LAST_JSON="$(tail -n 1 "$outfile")"
}

# Seed two valid consultants and one active project with an open role. Shared by
# both fixtures so the only difference between them is the latin-1 file.
seed_entities() {
  local pf="$1"
  write_entity "$pf/consultants/anna.md" <<'EOF'
---
type: consultant
slug: anna
name: Anna Schmidt
seniority: senior
skills: [cloud, architecture]
available_from: 2026-01-01
available_until: 2026-12-31
---
# anna
EOF
  write_entity "$pf/consultants/bruno.md" <<'EOF'
---
type: consultant
slug: bruno
name: Bruno Weber
seniority: consultant
skills: [cloud, data]
available_from: 2026-01-01
available_until: 2026-12-31
---
# bruno
EOF
  write_entity "$pf/projects/migration.md" <<'EOF'
---
type: project
slug: migration
name: Cloud Migration
client: GoodCo
strategic_impact: 4
status: active
start_date: 2026-02-01
end_date: 2026-06-30
open_roles: [cloud]
---
# migration
EOF
}

# ---------------------------------------------------------------------------
# Fixture A — control. A clean, fully decodable portfolio scores normally. This
# is what pins the counts Fixture B compares against: without it, an assertion
# that the latin-1 run still finds two consultants could pass for the wrong
# reason (e.g. the scorer silently finding none at all).
# ---------------------------------------------------------------------------
PFA="$TMPROOT/clean"
seed_portfolio "$PFA"
seed_entities "$PFA"

STDERRA="$TMPROOT/stderr-a.txt"
run_score "$STDERRA" "$PFA"

assert_exit  "1a clean portfolio exits 0"        0 "$RUN_CODE"
assert_json  "1b clean portfolio succeeds"       "d['success'] is True"
assert_json  "1c both consultants loaded"        "d['data']['consultant_count'] == 2"
assert_json  "1d project loaded"                 "d['data']['project_count'] == 1"
assert_json  "1e both consultants ranked"        "d['data']['ranked_candidate_count'] == 2"
# Anna and Bruno share the 'cloud' skill and differ only in seniority, so the
# ranking is what tells them apart — without this the second consultant is a
# fixture nothing distinguishes, and the documented deterministic ordering goes
# unpinned.
assert_json  "1f candidates ranked deterministically" \
  "[c['consultant'] for c in d['data']['projects'][0]['open_roles'][0]['candidates']] == ['anna', 'bruno']"
assert_no_traceback "1g no traceback on stderr"  "$STDERRA"

# ---------------------------------------------------------------------------
# Fixture B — the regression. Same portfolio plus one consultant record saved as
# latin-1, which is invalid UTF-8. Before the shared read_frontmatter helper,
# this raised UnicodeDecodeError out of the scorer: no JSON on stdout at all,
# just a traceback on stderr, which reads to a caller as neither success nor a
# reportable failure. The record must now be skipped like any other unreadable
# one while the rest of the portfolio still scores.
# ---------------------------------------------------------------------------
PFB="$TMPROOT/latin1"
seed_portfolio "$PFB"
seed_entities "$PFB"

# Written via python3 in wb mode because bash printf parses a leading '---' as
# options; \xe9 is 'é' in latin-1 and an invalid UTF-8 start byte here.
python3 -c "
import sys
open(sys.argv[1], 'wb').write(
    '---\ntype: consultant\nslug: cesar\nname: C\xe9sar Rossi\nseniority: senior\nskills: [cloud]\navailable_from: 2026-01-01\navailable_until: 2026-12-31\n---\n'.encode('latin-1')
)" "$PFB/consultants/cesar.md"

STDERRB="$TMPROOT/stderr-b.txt"
run_score "$STDERRB" "$PFB"

assert_exit  "2a latin-1 record does not fail the run"  0 "$RUN_CODE"
assert_json  "2b envelope still returned"               "d['success'] is True"
# The undecodable consultant is dropped; the two decodable ones still load.
assert_json  "2c undecodable consultant skipped"        "d['data']['consultant_count'] == 2"
assert_json  "2d project still scored"                  "d['data']['project_count'] == 1"
# The assertion this suite exists for: the guard gap surfaced as a raw traceback.
assert_no_traceback "2e no traceback on stderr"         "$STDERRB"

# ---------------------------------------------------------------------------
# Fixture C — usage and preflight errors still report through the envelope, so
# the fix above cannot have been achieved by swallowing every failure.
# ---------------------------------------------------------------------------
STDERRC="$TMPROOT/stderr-c.txt"

run_score "$STDERRC"
assert_exit  "3a no-args exits 2"                2 "$RUN_CODE"
assert_json  "3b no-args reports usage"          "d['success'] is False and 'usage' in d['error']"
assert_no_traceback "3c no-args stderr is clean" "$STDERRC"

run_score "$STDERRC" "$TMPROOT/does-not-exist"
assert_exit  "3d missing dir exits 1"            1 "$RUN_CODE"
assert_json  "3e missing dir reports envelope"   "d['success'] is False and d['error'] != ''"
assert_no_traceback "3f missing dir stderr is clean" "$STDERRC"

# A directory that exists but is not a portfolio.
mkdir -p "$TMPROOT/not-a-portfolio"
run_score "$STDERRC" "$TMPROOT/not-a-portfolio"
assert_exit  "3g non-portfolio dir exits 1"      1 "$RUN_CODE"
assert_json  "3h non-portfolio reports envelope" "d['success'] is False and 'projects-portfolio.json' in d['error']"
assert_no_traceback "3i non-portfolio stderr is clean" "$STDERRC"

if [ "$failures" -gt 0 ]; then
  printf '\n%d assertion(s) failed\n' "$failures" >&2
  exit 1
fi
printf '\nAll staffing-score.py assertions passed\n'

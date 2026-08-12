#!/usr/bin/env bash
# Mutation harness for cogni-portfolio (AC: scripts/mutation-check.sh).
#
# Runs each feature's mutation falsifier in turn and asserts the targeted test
# goes RED against the mutant — proving the detection actually has teeth. Exit 0
# iff EVERY mutation is caught; non-zero if any mutation survives.
#
#   1. commercial-consolidation gate (#1230): flip the "commercial structure
#      shared?" check in project-status.sh to a constant false; expect
#      test_hybrid_consolidates to go RED.
#   2. solution-candidate register: remove the Solutions-block mapping in
#      register-solution-candidates.py; expect test_ingest_registers_candidates
#      to go RED.
#   3. dashboard-refresher no-skip-path: revert the "no theme found" branch of
#      agents/dashboard-refresher.md to a terminal skipped status; expect
#      test_refresher_has_no_skip_path to go RED.
#   4. handoff citation: strip the canonical-reference citation from the handoff
#      section of skills/markets/SKILL.md; expect test_entity_skills_cite_handoff
#      to go RED.
#   5. portfolio-resume dashboard row: delete the Dashboard row from
#      skills/portfolio-resume/SKILL.md; expect test_resume_shows_dashboard_row
#      to go RED.
#   6. dispatch-site Agent grant: strip the Agent token from the allowed-tools
#      line of skills/products/SKILL.md, a skill that carries a
#      dashboard-refresher dispatch; expect test_dispatch_sites_grant_agent
#      to go RED.
#
# Kept under scripts/ (NOT tests/) deliberately: run-plugin-tests.py auto-discovers
# tests/*.sh and would run this as a normal suite; this is a manual meta-check that
# deliberately drives failing sub-runs.
#
# Usage: bash cogni-portfolio/scripts/mutation-check.sh   (no args, no network)

set -u

SCRIPTS_DIR="$(cd "$(dirname "$0")" && pwd)"
PLUGIN_DIR="$(cd "$SCRIPTS_DIR/.." && pwd)"

overall=0

# --- Mutation 1: commercial-consolidation gate -----------------------------
# Reverts the "commercial structure shared?" check in project-status.sh to a
# constant false, then asserts test_hybrid_consolidates goes RED against the
# mutant. Returns 0 when the mutation is caught, non-zero otherwise.
mutation_commercial_consolidation() {
  local test="$PLUGIN_DIR/tests/test-commercial-consolidation.sh"
  for f in "$SCRIPTS_DIR/project-status.sh" "$test"; do
    [ -f "$f" ] || { echo "FAIL: missing $f" >&2; return 1; }
  done

  local tmp; tmp="$(mktemp -d)"
  # Copy the whole scripts/ dir so the mutant still finds its sibling scripts.
  cp -R "$SCRIPTS_DIR" "$tmp/scripts"
  local mutated="$tmp/scripts/project-status.sh"

  if ! python3 - "$mutated" <<'PY'
import re, sys
path = sys.argv[1]
src = open(path).read()
new, n = re.subn(
    r'shared = rm in SHARED_MODELS.*',
    'shared = False  # MUTATED by mutation-check.sh',
    src, count=1)
if n != 1:
    sys.stderr.write("could not locate the commercial-structure check to mutate\n")
    sys.exit(3)
open(path, 'w').write(new)
PY
  then
    echo "FAIL: commercial-consolidation mutation could not be applied" >&2
    rm -rf "$tmp"; return 1
  fi

  local rc=0
  if PROJECT_STATUS_SCRIPT="$mutated" bash "$test" test_hybrid_consolidates >/dev/null 2>&1; then
    echo "FALSIFIER: mutation survived — test_hybrid_consolidates still passed with the shared check disabled" >&2
    rc=1
  else
    echo "OK: mutation caught — test_hybrid_consolidates went red with the shared check disabled"
  fi
  rm -rf "$tmp"
  return "$rc"
}

# --- Mutation 2: solution-candidate register -------------------------------
# Excises the Solutions-block mapping (between the AC6-MUTATION-TARGET markers)
# in register-solution-candidates.py, then asserts test_ingest_registers_candidates
# goes RED. The source is always restored. Returns 0 when caught, non-zero otherwise.
mutation_solution_candidates() {
  local target="$SCRIPTS_DIR/register-solution-candidates.py"
  local suite="$PLUGIN_DIR/tests/test-solution-candidates.sh"
  local test_name="test_ingest_registers_candidates"
  for f in "$target" "$suite"; do
    [ -f "$f" ] || { echo "FAIL: missing $f" >&2; return 1; }
  done

  # Baseline: the target test must be GREEN before we mutate, or a later red
  # tells us nothing.
  if ! bash "$suite" "$test_name" >/dev/null 2>&1; then
    echo "FAIL: baseline $test_name is already red before mutation" >&2
    return 1
  fi

  local backup; backup="$(mktemp)"
  cp "$target" "$backup"

  if ! python3 - "$target" <<'PY'
import re, sys
path = sys.argv[1]
src = open(path, encoding="utf-8").read()
mutated, n = re.subn(
    r"^[ \t]*# >>> AC6-MUTATION-TARGET:.*?^[ \t]*# <<< AC6-MUTATION-TARGET[ \t]*\n",
    "",
    src,
    count=1,
    flags=re.DOTALL | re.MULTILINE,
)
if n != 1:
    sys.stderr.write("AC6-MUTATION-TARGET markers not found — cannot mutate.\n")
    sys.exit(4)
open(path, "w", encoding="utf-8").write(mutated)
PY
  then
    echo "FAIL: solution-candidate mutation could not be applied" >&2
    cp "$backup" "$target"; rm -f "$backup"; return 1
  fi

  local rc=0
  if bash "$suite" "$test_name" >/dev/null 2>&1; then
    echo "FALSIFIER: mutation survived — $test_name stayed GREEN with the Solutions-block mapping removed" >&2
    rc=1
  else
    echo "OK: mutation caught — $test_name goes red when the Solutions-block mapping is removed"
  fi
  cp "$backup" "$target"; rm -f "$backup"   # always restore
  return "$rc"
}

# --- Mutation 3: dashboard-refresher no-skip-path -------------------------
# Reverts the "no theme found" branch of agents/dashboard-refresher.md to the
# terminal skipped status the fix removed, then asserts
# test_refresher_has_no_skip_path goes RED against the mutant. The target is a
# documentation file on purpose: the suite asserts on documentation content, so
# mutating a script would leave the case green and prove nothing.
mutation_dashboard_no_skip_path() {
  local target="$PLUGIN_DIR/agents/dashboard-refresher.md"
  local suite="$PLUGIN_DIR/tests/test-dashboard-handoff.sh"
  local test_name="test_refresher_has_no_skip_path"
  for f in "$target" "$suite"; do
    [ -f "$f" ] || { echo "FAIL: missing $f" >&2; return 1; }
  done

  # Baseline: the target test must be GREEN before we mutate, or a later red
  # tells us nothing.
  if ! bash "$suite" "$test_name" >/dev/null 2>&1; then
    echo "FAIL: baseline $test_name is already red before mutation" >&2
    return 1
  fi

  local backup; backup="$(mktemp)"
  cp "$target" "$backup"

  if ! python3 - "$target" <<'PY'
import re, sys
path = sys.argv[1]
src = open(path, encoding="utf-8").read()
mutated, n = re.subn(
    r"^- \*\*If neither exists\*\*: run the generator with no theme flag\..*$",
    '- **If neither exists**: return this JSON and stop:\n'
    '  ```json\n'
    '  {"status": "skipped", "reason": "No design-variables.json or theme found. '
    'Run /portfolio-dashboard first to set up a theme."}\n'
    '  ```',
    src,
    count=1,
    flags=re.MULTILINE,
)
if n != 1:
    sys.stderr.write("no-theme-found branch not found — cannot mutate.\n")
    sys.exit(5)
open(path, "w", encoding="utf-8").write(mutated)
PY
  then
    echo "FAIL: dashboard no-skip-path mutation could not be applied" >&2
    cp "$backup" "$target"; rm -f "$backup"; return 1
  fi

  local rc=0
  if bash "$suite" "$test_name" >/dev/null 2>&1; then
    echo "FALSIFIER: mutation survived — $test_name stayed GREEN with the terminal skipped branch restored" >&2
    rc=1
  else
    echo "OK: mutation caught — $test_name goes red when the terminal skipped branch is restored"
  fi
  cp "$backup" "$target"; rm -f "$backup"   # always restore
  return "$rc"
}

# --- Mutation 4: handoff citation ------------------------------------------
# Strips the canonical-reference citation from the handoff section of
# skills/markets/SKILL.md, then asserts test_entity_skills_cite_handoff goes RED
# against the mutant. markets/ is the target because it carries the citation
# exactly once and takes no pointer line, so the count=1 anchor is unambiguous.
# A documentation file on purpose: the suite asserts on documentation content, so
# mutating a script would leave the case green and prove nothing.
mutation_handoff_citation() {
  local target="$PLUGIN_DIR/skills/markets/SKILL.md"
  local suite="$PLUGIN_DIR/tests/test-dashboard-handoff.sh"
  local test_name="test_entity_skills_cite_handoff"
  for f in "$target" "$suite"; do
    [ -f "$f" ] || { echo "FAIL: missing $f" >&2; return 1; }
  done

  # Baseline: the target test must be GREEN before we mutate, or a later red
  # tells us nothing.
  if ! bash "$suite" "$test_name" >/dev/null 2>&1; then
    echo "FAIL: baseline $test_name is already red before mutation" >&2
    return 1
  fi

  local backup; backup="$(mktemp)"
  cp "$target" "$backup"

  if ! python3 - "$target" <<'PY'
import re, sys
path = sys.argv[1]
src = open(path, encoding="utf-8").read()
mutated, n = re.subn(
    r"^.*references/dashboard-handoff\.md.*$\n?",
    "",
    src,
    count=1,
    flags=re.MULTILINE,
)
if n != 1:
    sys.stderr.write("handoff citation not found — cannot mutate.\n")
    sys.exit(6)
open(path, "w", encoding="utf-8").write(mutated)
PY
  then
    echo "FAIL: handoff-citation mutation could not be applied" >&2
    cp "$backup" "$target"; rm -f "$backup"; return 1
  fi

  local rc=0
  if bash "$suite" "$test_name" >/dev/null 2>&1; then
    echo "FALSIFIER: mutation survived — $test_name stayed GREEN with the handoff citation removed" >&2
    rc=1
  else
    echo "OK: mutation caught — $test_name goes red when the handoff citation is removed"
  fi
  cp "$backup" "$target"; rm -f "$backup"   # always restore
  return "$rc"
}

# --- Mutation 5: portfolio-resume dashboard row ---------------------------
# Deletes the Dashboard row from the portfolio-resume status table, then
# asserts test_resume_shows_dashboard_row goes RED against the mutant. The
# target is a documentation file on purpose: the case asserts on documented
# behaviour, so mutating a script would leave it green and prove nothing.
mutation_resume_dashboard_row() {
  local target="$PLUGIN_DIR/skills/portfolio-resume/SKILL.md"
  local suite="$PLUGIN_DIR/tests/test-dashboard-handoff.sh"
  local test_name="test_resume_shows_dashboard_row"
  for f in "$target" "$suite"; do
    [ -f "$f" ] || { echo "FAIL: missing $f" >&2; return 1; }
  done

  # Baseline: the target test must be GREEN before we mutate, or a later red
  # tells us nothing.
  if ! bash "$suite" "$test_name" >/dev/null 2>&1; then
    echo "FAIL: baseline $test_name is already red before mutation" >&2
    return 1
  fi

  local backup; backup="$(mktemp)"
  cp "$target" "$backup"

  if ! python3 - "$target" <<'PY'
import re, sys
path = sys.argv[1]
src = open(path, encoding="utf-8").read()
mutated, n = re.subn(
    r"^\| Dashboard \|.*\n",
    "",
    src,
    count=1,
    flags=re.MULTILINE,
)
if n != 1:
    sys.stderr.write("Dashboard status-table row not found - cannot mutate.\n")
    sys.exit(6)
open(path, "w", encoding="utf-8").write(mutated)
PY
  then
    echo "FAIL: resume dashboard-row mutation could not be applied" >&2
    cp "$backup" "$target"; rm -f "$backup"; return 1
  fi

  local rc=0
  if bash "$suite" "$test_name" >/dev/null 2>&1; then
    echo "FALSIFIER: mutation survived — $test_name stayed GREEN with the Dashboard row deleted" >&2
    rc=1
  else
    echo "OK: mutation caught — $test_name goes red when the Dashboard row is deleted"
  fi
  cp "$backup" "$target"; rm -f "$backup"   # always restore
  return "$rc"
}

# --- Mutation 5: dispatch-site Agent grant ---------------------------------
# Strips the Agent token from the allowed-tools line of a skill that documents a
# dashboard-refresher dispatch, then asserts test_dispatch_sites_grant_agent goes
# RED against the mutant. The target is a SKILL.md — documentation, not a script —
# for the same reason as mutation 3: the case asserts on frontmatter content, so
# mutating a script would leave it green and prove nothing. products/SKILL.md is
# the grant template and is not otherwise touched by this feature, so the mutation
# stays independent of the skills the fix edits.
mutation_dispatch_agent_grant() {
  local target="$PLUGIN_DIR/skills/products/SKILL.md"
  local suite="$PLUGIN_DIR/tests/test-dashboard-handoff.sh"
  local test_name="test_dispatch_sites_grant_agent"
  for f in "$target" "$suite"; do
    [ -f "$f" ] || { echo "FAIL: missing $f" >&2; return 1; }
  done

  # Baseline: the target test must be GREEN before we mutate, or a later red
  # tells us nothing.
  if ! bash "$suite" "$test_name" >/dev/null 2>&1; then
    echo "FAIL: baseline $test_name is already red before mutation" >&2
    return 1
  fi

  local backup; backup="$(mktemp)"
  cp "$target" "$backup"

  if ! python3 - "$target" <<'PY'
import re, sys
path = sys.argv[1]
src = open(path, encoding="utf-8").read()
# Anchored on the frontmatter grant line, dropping ONLY the trailing Agent token.
# The replacement carries no copy of the searched literal: one that kept `Agent`
# on the line would leave the grant intact, the case green, and this mutation
# would survive unnoticed.
mutated, n = re.subn(
    r"^(allowed-tools: .*), Agent$",
    r"\1",
    src,
    count=1,
    flags=re.MULTILINE,
)
if n != 1:
    sys.stderr.write("allowed-tools line with a trailing Agent token not found — cannot mutate.\n")
    sys.exit(7)
open(path, "w", encoding="utf-8").write(mutated)
PY
  then
    echo "FAIL: dispatch-site Agent-grant mutation could not be applied" >&2
    cp "$backup" "$target"; rm -f "$backup"; return 1
  fi

  local rc=0
  if bash "$suite" "$test_name" >/dev/null 2>&1; then
    echo "FALSIFIER: mutation survived — $test_name stayed GREEN with a dispatching skill's Agent grant stripped" >&2
    rc=1
  else
    echo "OK: mutation caught — $test_name goes red when a dispatching skill loses its Agent grant"
  fi
  cp "$backup" "$target"; rm -f "$backup"   # always restore
  return "$rc"
}

mutation_commercial_consolidation || overall=1
mutation_solution_candidates || overall=1
mutation_dashboard_no_skip_path || overall=1
mutation_handoff_citation || overall=1
mutation_resume_dashboard_row || overall=1
mutation_dispatch_agent_grant || overall=1

if [ "$overall" -eq 0 ]; then
  echo "All mutations caught."
else
  echo "One or more mutations survived." >&2
fi
exit "$overall"

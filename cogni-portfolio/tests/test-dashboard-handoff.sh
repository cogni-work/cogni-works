#!/usr/bin/env bash
# Acceptance suite for the dashboard-refresher handoff contract.
#
# The `dashboard-refresher` agent is the plugin's only non-interactive path to a
# regenerated dashboard, and every end-of-step caller depends on two guarantees:
# a dashboard always gets produced, and nothing opens a browser window unasked.
# Both guarantees live in prose, in a single shared contract file — so nothing
# fails when they drift. These tests are what fails.
#
# The third case is the load-bearing one. `open_browser` defaults to false, and
# eleven in-plugin call sites promise the user "(a) open the dashboard" before
# dispatching the agent. Each of them has to name the opt-in explicitly, because
# the default alone no longer opens anything. The scan is intent-scoped, not
# blanket: a caller that only wants the returned url is correct with no flag.
#
# Named acceptance tests:
#   test_refresher_has_no_skip_path  the agent never terminates without generating
#   test_open_browser_optin          default is non-opening, and every intending call site says so
#   test_refresher_returns_url       a successful result carries a clickable url
#   test_resume_shows_dashboard_row  portfolio-resume surfaces a flag-driven dashboard row
#   test_handoff_does_not_open       the resume generation offer dispatches without opening a browser
#
# Usage: bash cogni-portfolio/tests/test-dashboard-handoff.sh [test_name ...]
#   No args -> run every test (the CI path). One or more names -> run only those
#   (used by the mutation harness to run a single assertion against a mutant).
#   An unknown name exits 2 rather than reporting green, so a stale mutation
#   recipe cannot pass while running zero assertions.
# Exits non-zero on any assertion failure.
#
# Scope note: the scan covers this plugin only, and deliberately excludes the
#   agent contract itself from the call-site surface — it is the file that
#   *documents* open_browser, not a caller of it, so including it would flag the
#   definition as an offender.
#
# Mutation recipe — the SHARED cogni-service harness, which classifies on the output
#   labels below. Replayable as written, from the repo root. The mutant must be a
#   documentation file, not a script: this suite asserts on documentation content, so
#   mutating a scripts/ file would leave every case green and prove nothing.
#   bash ~/.claude/plugins/cache/managed-service/cogni-service/0.0.383/scripts/mutation-check.sh \
#     --root . \
#     --file cogni-portfolio/agents/dashboard-refresher.md \
#     --expr 's#run the generator with no theme flag#return this JSON and stop#' \
#     --test 'bash cogni-portfolio/tests/test-dashboard-handoff.sh test_refresher_has_no_skip_path' \
#     --case test_refresher_has_no_skip_path
#   The expr reverts the no-theme branch to the terminal wording the fix removed, so
#   the case goes red on the mutant and green on HEAD. Pick a metacharacter-free
#   target: the harness feeds the expr to `perl -0pi`, where a dot would be a
#   wildcard rather than a literal.
#   There is no in-repo copy of the SHARED harness; if that version directory is gone,
#   use the newest under the same parent — everything after the path is version-independent.
#   The in-repo equivalent is registered as mutation_dashboard_no_skip_path in
#   cogni-portfolio/scripts/mutation-check.sh.

# `set -u` only — `set -e` would abort on the first failing assertion and defeat
# the failure counter below, which exists so one run reports every offender.
set -u

TESTS_DIR="$(cd "$(dirname "$0")" && pwd)"
PLUGIN_DIR="$(cd "$TESTS_DIR/.." && pwd)"
AGENT="$PLUGIN_DIR/agents/dashboard-refresher.md"

failures=0
# Keep the message a SEPARATE argument. The shared mutation harness anchors on the
# case token and needs whitespace or end-of-line right after it, so folding it back
# into one "<case>: <msg>" string puts a colon there and the case stops matching.
pass() { printf 'ok: %s %s\n' "$1" "${2:-}"; }
fail() { printf 'FAIL: %s %s\n' "$1" "${2:-}" >&2; failures=$((failures + 1)); }

# The agent contract is the scan surface for two of the three cases. A missing or
# empty file would make every literal assertion below vacuously "not found", which
# reads as a real failure rather than a broken surface — so say which it is.
agent_surface_ok() {
  local case_name="$1"
  if [ ! -s "$AGENT" ]; then
    fail "$case_name" "agents/dashboard-refresher.md is missing or empty; scan surface is broken"
    return 1
  fi
  return 0
}

# --- test_refresher_has_no_skip_path ---------------------------------------
# The agent must never document a path that ends without a generated file. The
# generator applies its built-in default theme when given no theme flag, so the
# "no theme found" state is a generate-anyway branch, not a terminal one.
test_refresher_has_no_skip_path() {
  agent_surface_ok test_refresher_has_no_skip_path || return

  local missing=""

  if grep -qF 'run the generator with no theme flag' "$AGENT"; then :; else
    missing="$missing no-theme-branch-generates"
  fi
  if grep -qF 'DEFAULT_THEME' "$AGENT"; then :; else
    missing="$missing cites-DEFAULT_THEME"
  fi

  # The terminal skipped status must be gone entirely, not merely reworded around.
  if grep -qF '"status": "skipped"' "$AGENT"; then
    missing="$missing terminal-skipped-status-still-present"
  fi

  # Step 2 must actually SHOW the flagless invocation, or the branch names a
  # command shape the agent was never given.
  if grep -F 'generate-dashboard.py "<project_dir>"' "$AGENT" \
     | grep -vF -- '--theme' | grep -qvF -- '--design-variables'; then :; else
    missing="$missing no-flag-invocation-form"
  fi

  # The error branch is not part of this change and must survive it: a diff that
  # folds it into the new unconditional-generation flow would let a failed
  # generator return a success payload.
  if grep -qF '"status": "error"' "$AGENT"; then :; else
    missing="$missing error-branch-removed"
  fi
  if grep -qF 'Do not retry.' "$AGENT"; then :; else
    missing="$missing do-not-retry-removed"
  fi

  if [ -n "$missing" ]; then
    fail test_refresher_has_no_skip_path "agent contract problems:$missing"
  else
    pass test_refresher_has_no_skip_path "generates unconditionally; error branch intact"
  fi
}

# --- test_open_browser_optin -----------------------------------------------
# Two halves: the documented default is the non-opening one, and every call site
# whose prose promises to open names the opt-in explicitly.
test_open_browser_optin() {
  agent_surface_ok test_open_browser_optin || return

  # Half 1 — the input contract.
  local contract_line
  contract_line="$(grep -F '`open_browser` (optional' "$AGENT" | head -1)"
  if [ -z "$contract_line" ]; then
    fail test_open_browser_optin "no open_browser input-contract line in agents/dashboard-refresher.md"
  else
    case "$contract_line" in
      *"default: false"*) pass test_open_browser_optin "input contract documents the non-opening default" ;;
      *) fail test_open_browser_optin "input-contract line does not document 'default: false': $contract_line" ;;
    esac
  fi
  if grep -qF 'default: true' "$AGENT"; then
    fail test_open_browser_optin "agent contract still documents 'default: true' somewhere"
  fi

  # Half 2 — the call-site surface. Three globs: agents/, skills/*/SKILL.md and
  # skills/*/references/*.md. The last one is not optional — two of the eleven
  # dispatch sites live only there, so a SKILL.md-bounded scan finds nine.
  local surface scanned
  surface="$(
    find "$PLUGIN_DIR/agents" -name '*.md' -type f 2>/dev/null
    find "$PLUGIN_DIR/skills" -mindepth 2 -maxdepth 2 -name 'SKILL.md' -type f 2>/dev/null
    find "$PLUGIN_DIR/skills" -mindepth 3 -maxdepth 3 -path '*/references/*.md' -type f 2>/dev/null
  )"
  scanned="$(printf '%s\n' "$surface" | grep -c . )"
  if [ "$scanned" -eq 0 ]; then
    fail test_open_browser_optin "scanned no files; scan surface is broken"
    return
  fi

  # A dispatch line mentions the agent by name. The agent's own contract file is
  # the definition, not a caller — exclude it.
  local dispatch_lines dispatch_count offenders=""
  dispatch_lines="$(
    printf '%s\n' "$surface" | while IFS= read -r f; do
      [ -n "$f" ] || continue
      [ "$f" = "$AGENT" ] && continue
      grep -nF 'dashboard-refresher' "$f" 2>/dev/null | while IFS= read -r hit; do
        printf '%s:%s\n' "$f" "$hit"
      done
    done
  )"
  dispatch_count="$(printf '%s\n' "$dispatch_lines" | grep -c . )"
  if [ "$dispatch_count" -eq 0 ]; then
    fail test_open_browser_optin "found no dashboard-refresher dispatch lines; scan surface is broken"
    return
  fi

  # Intent-scoped: require the flag only where the surrounding prose promises to
  # open. The window is the dispatch line plus the 8 lines above it — the widest
  # real offer-to-dispatch gap in the plugin is 6. A future end-of-step caller
  # that only wants the returned url is correct with no flag and stays green.
  while IFS= read -r entry; do
    [ -n "$entry" ] || continue
    local file lineno text window from
    file="${entry%%:*}"
    text="${entry#*:}"
    lineno="${text%%:*}"
    text="${text#*:}"
    from=$(( lineno - 8 )); [ "$from" -lt 1 ] && from=1
    window="$(sed -n "${from},${lineno}p" "$file")"
    case "$(printf '%s' "$window" | tr '[:upper:]' '[:lower:]')" in
      *"open the dashboard"*)
        case "$text" in
          *open_browser*) : ;;
          *) offenders="$offenders ${file#"$PLUGIN_DIR/"}:$lineno" ;;
        esac
        ;;
    esac
  done <<EOF
$dispatch_lines
EOF

  if [ -n "$offenders" ]; then
    fail test_open_browser_optin "call sites promise to open but pass no flag:$offenders"
  else
    pass test_open_browser_optin "all intending call sites name the opt-in ($dispatch_count dispatch lines scanned)"
  fi
}

# --- test_refresher_returns_url --------------------------------------------
# Callers should cite a link, not each rebuild file:// + path themselves.
test_refresher_returns_url() {
  agent_surface_ok test_refresher_returns_url || return

  local missing=""
  grep -qF '"url": "file://' "$AGENT" || missing="$missing url-field"
  grep -qF '"path"' "$AGENT"          || missing="$missing path-field-dropped"
  grep -qF 'theme_source' "$AGENT"    || missing="$missing theme_source-field"

  # The three documented values, so a caller can tell a defaulted dashboard from
  # a themed one.
  local vocab
  vocab="$(grep -F 'theme_source' "$AGENT")"
  case "$vocab" in
    *design-variables*) : ;;
    *) missing="$missing theme_source-vocab-design-variables" ;;
  esac
  case "$vocab" in
    *default*) : ;;
    *) missing="$missing theme_source-vocab-default" ;;
  esac

  if [ -n "$missing" ]; then
    fail test_refresher_returns_url "return block problems:$missing"
  else
    pass test_refresher_returns_url "success payload carries a clickable url and theme_source"
  fi
}

# The resume skill is the scan surface for the two cases below. Same reasoning
# as agent_surface_ok: a missing or empty file makes every literal assertion
# vacuously "not found", which reads as a real failure rather than a broken
# surface — so say which it is.
RESUME="$PLUGIN_DIR/skills/portfolio-resume/SKILL.md"
resume_surface_ok() {
  local case_name="$1"
  if [ ! -s "$RESUME" ]; then
    fail "$case_name" "skills/portfolio-resume/SKILL.md is missing or empty; scan surface is broken"
    return 1
  fi
  return 0
}

# --- test_resume_shows_dashboard_row ---------------------------------------
# The resume status table must carry a Dashboard row, and BOTH documented
# branches must survive: the has_dashboard-driven link, and the opt-in,
# non-opening generation offer. Anchor on the row's cell shape, not the bare
# word "dashboard" — that word appears elsewhere in this skill's prose, so a
# word-level grep would stay green with the row deleted.
test_resume_shows_dashboard_row() {
  resume_surface_ok test_resume_shows_dashboard_row || return

  local missing=""

  # The row itself, by cell shape.
  grep -qF '| Dashboard |' "$RESUME" || missing="$missing dashboard-table-row"

  # Branch 1 — presence comes from the discovery flag, not a fresh probe.
  # Anchor on the bullet's own phrasing: the bare flag name also appears in the
  # Step 1 discovery contract, so grepping it alone could never fail.
  grep -qF 'discovery flag `has_dashboard`' "$RESUME"             || missing="$missing presence-flag-not-cited"
  grep -qF 'never re-probe the filesystem' "$RESUME"              || missing="$missing filesystem-reprobe-not-banned"
  grep -qF 'file://<project-dir>/output/dashboard.html' "$RESUME" || missing="$missing no-clickable-link"

  # Branch 2 — the missing case says so, and generation stays opt-in.
  grep -qF 'offer to generate one' "$RESUME" || missing="$missing no-generation-offer"
  grep -qF 'if the user accepts' "$RESUME"   || missing="$missing no-opt-in-gate"

  # The frontmatter must permit the dispatch, or the documented branch is inert.
  grep -q '^allowed-tools:.*Agent' "$RESUME" || missing="$missing agent-tool-not-declared"

  if [ -n "$missing" ]; then
    fail test_resume_shows_dashboard_row "portfolio-resume dashboard row problems:$missing"
  else
    pass test_resume_shows_dashboard_row "dashboard row is flag-driven, links, opt-in gated, and Agent is declared"
  fi
}

# --- test_handoff_does_not_open --------------------------------------------
# The resume offer regenerates a dashboard; it must never launch a browser on
# its own. The refresher already defaults open_browser to false, but the resume
# call site states it explicitly so the intent is readable where it is made.
# test_open_browser_optin does not cover this: that case is scoped to call
# sites whose surrounding prose promises to open, and this one does not.
test_handoff_does_not_open() {
  resume_surface_ok test_handoff_does_not_open || return

  local missing=""
  grep -qF 'dashboard-refresher' "$RESUME" || missing="$missing no-refresher-dispatch"
  grep -qF 'open_browser: false' "$RESUME" || missing="$missing generation-may-open-browser"
  # Presence, not absence, is the defect here — so an explicit if, matching the
  # inverted-polarity assertions elsewhere in this suite.
  if grep -qF 'open_browser: true' "$RESUME"; then
    missing="$missing resume-opens-a-browser"
  fi

  if [ -n "$missing" ]; then
    fail test_handoff_does_not_open "portfolio-resume generation offer problems:$missing"
  else
    pass test_handoff_does_not_open "the resume generation offer dispatches with the non-opening flag"
  fi
}

ALL_TESTS="test_refresher_has_no_skip_path test_open_browser_optin test_refresher_returns_url test_resume_shows_dashboard_row test_handoff_does_not_open"

# Reject an unknown case name instead of letting bash's "command not found" pass
# through: with no `set -e` and no failures increment, an unrecognised name would
# otherwise print "All tests passed." having run nothing at all.
run_one() {
  case " $ALL_TESTS " in
    *" $1 "*) "$1" ;;
    *) printf 'unknown test %s\n' "$1" >&2; exit 2 ;;
  esac
}

if [ "$#" -gt 0 ]; then
  for t in "$@"; do run_one "$t"; done
else
  for t in $ALL_TESTS; do "$t"; done
fi

if [ "$failures" -gt 0 ]; then
  printf '\n%d test(s) failed\n' "$failures" >&2
  exit 1
fi
printf '\nAll tests passed.\n'

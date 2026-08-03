# test_helpers.sh — shared bash assertion harness sourced by cogni-projects/tests/*.
#
# Source via:
#   . "$TESTS_DIR/fixtures/test_helpers.sh"
#
# The POSIX dot, not `source`, and no shebang: this file is sourced, never
# executed. It lives under fixtures/ rather than beside the suites so a
# `tests/test_*.sh` sweep never collects a non-suite file as a suite.
#
# `set -u` is deliberately NOT set here — it is a per-suite preamble line that
# must precede this source. Nor is there a shared summary/exit tail: the suites
# print different completion lines.
#
# Bash 3.2 compatible (the macOS default these suites run under).

failures=0
pass() { printf 'OK   %s\n' "$1"; }
fail() { printf 'FAIL %s: %s\n' "$1" "$2" >&2; failures=$((failures + 1)); }

# init_tmproot — set TMPROOT to a fresh temp dir and arm its cleanup trap.
# TMPROOT is a global on purpose: run_script defaults its stdout/stderr sinks
# underneath it, and the suites reference it directly when building fixtures.
# The chmod is what lets a fixture leave a read-only (0555) directory behind
# without defeating cleanup; it is a harmless no-op for suites that never do.
init_tmproot() {
  TMPROOT="$(mktemp -d)"
  trap 'chmod -R u+rwx "$TMPROOT" 2>/dev/null; rm -rf "$TMPROOT"' EXIT
}

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
# edit. Every "the script degraded instead of crashing" fixture needs it.
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
  #
  # Never call this from a suite that exercises portfolio-init.sh — creating
  # this layout is that script's job, and seeding it would pre-empt the
  # behaviour under test.
  local pf="$1"
  mkdir -p "$pf"/{consultants,projects,assignments,.metadata}
  cat > "$pf/projects-portfolio.json" <<'EOF'
{"slug":"test","name":"Test Portfolio","language":"en","consultants":[],"projects":[],"assignments":[],"created":"2026-01-01","updated":"2026-01-01"}
EOF
}

write_entity() { # $1 = path; body heredoc'd by the caller on stdin
  cat > "$1"
}

# write_latin1 <path> — body heredoc'd by the caller on stdin as UTF-8, written
# out latin-1-encoded. python3 does the write in wb mode because bash printf
# parses a leading '---' as options; the encoded bytes are invalid UTF-8 start
# bytes by design, which is the whole point of the fixture. stdin is read as
# binary and decoded explicitly so a C/POSIX locale cannot change the result.
#
# The encode happens before the file is opened, and a failure is reported rather
# than swallowed. Both matter: a character outside latin-1 (say 'ł') would
# otherwise leave a 0-byte file, which the loaders skip as frontmatter-less — so
# the very regression fixture that exists to prove non-UTF-8 records are
# tolerated would pass while testing nothing.
write_latin1() {
  if ! python3 -c "
import sys
body = sys.stdin.buffer.read().decode('utf-8')
blob = body.encode('latin-1')
open(sys.argv[1], 'wb').write(blob)" "$1"; then
    fail "write_latin1 $1" "payload is not latin-1 encodable"
    return 1
  fi
}

# run_script <command> [args...] — invoke a script and capture its envelope and
# its own exit status. The whole command line is positional, so the runner is
# interpreter-agnostic: `run_script python3 "$SCRIPT" ...` and
# `run_script bash "$SCRIPT" ...` both work.
#
# Sets LAST_JSON (the last stdout line) and RUN_CODE (the command's status).
# Redirecting to a file rather than piping into `tail` is load-bearing: after a
# `$(... | tail -n 1)` substitution, `$?` is tail's status, which is always 0,
# so every exit-code assertion would pass vacuously.
#
# Two optional globals tune a single call, and both are ONE-SHOT — consumed and
# cleared here, so a fixture cannot leak its setting into the next run:
#   RUN_ERRFILE  stderr sink for this call (default "$TMPROOT/stderr.txt")
#   RUN_CWD      run the command in this directory, leaving the caller's cwd
#                untouched; the redirections and the status capture stay in the
#                caller's shell, so RUN_CODE is still the command's own.
# Clearing them here is what keeps every caller on one discipline: set it on the
# line above the call, and never think about resetting it. The sink FILE of
# course survives — only the variable is cleared — so an assertion reading it
# after the call still works.
#
# init_tmproot must have run first — the default sink dereferences TMPROOT.
run_script() {
  local outfile="$TMPROOT/stdout.txt"
  local errfile="${RUN_ERRFILE:-$TMPROOT/stderr.txt}"
  local cwd="${RUN_CWD:-}"
  RUN_ERRFILE=""
  RUN_CWD=""
  if [ -n "$cwd" ]; then
    ( cd "$cwd" && "$@" ) >"$outfile" 2>"$errfile"
  else
    "$@" >"$outfile" 2>"$errfile"
  fi
  RUN_CODE=$?
  LAST_JSON="$(tail -n 1 "$outfile")"
}

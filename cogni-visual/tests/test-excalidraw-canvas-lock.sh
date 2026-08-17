#!/usr/bin/env bash
# test-excalidraw-canvas-lock.sh — pins the atomic start claim in
# hooks/ensure-excalidraw-canvas.sh.
#
# What it guards: cogni-visual and cogni-portfolio ship byte-identical copies of
# that hook and register the same unqualified mcp__excalidraw__* PreToolUse
# matcher, so a machine with both plugins installed dispatches two of them in
# parallel on every tool call. The hook's port probe is a check, not a
# mutual-exclusion primitive — without the claim both invocations spawn a
# server, the loser dies on EADDRINUSE, and canvas.pid is left naming a dead
# process. Every exit status stays 0 throughout, so the failure is silent: only
# a behavioural test catches it.
#
# Hermetic by construction: each case builds its own sandbox under `mktemp -d`
# and prepends a stub bin/ to PATH shadowing every external the hook touches
# (nc, node, curl, open, xdg-open). No socket is bound, no network is used, and
# nothing is written outside the sandbox.
#
# `set -u` only, never `set -e`: one run reports every offender rather than
# stopping at the first.
#
# Mutation recipes — the SHARED cogni-service harness, which classifies on the
#   output labels below (a FAIL: line naming the case is RED). Replayable as
#   written, from the repo root. If that version directory is gone, use the
#   newest under the same parent; everything after the path is version-independent.
#
#   M1 -> test_cold_start_spawns_exactly_one_server
#   bash ~/.claude/plugins/cache/managed-service/cogni-service/0.0.402/scripts/mutation-check.sh \
#     --root . \
#     --file cogni-visual/hooks/ensure-excalidraw-canvas.sh \
#     --expr 's#mkdir "\$LOCK_DIR" 2>/dev/null#mkdir -p "\$LOCK_DIR" 2>/dev/null#' \
#     --test 'bash cogni-visual/tests/test-excalidraw-canvas-lock.sh test_cold_start_spawns_exactly_one_server' \
#     --case test_cold_start_spawns_exactly_one_server
#   `mkdir -p` succeeds against an existing directory, so both racers believe
#   they won and both spawn — exactly the pre-fix behaviour. The searched
#   literal occurs once (the two other `mkdir` mentions are prose), the
#   replacement is disjoint from it, `#` is safe as a delimiter because neither
#   side contains one, and `\$` reaches perl as a literal dollar rather than an
#   interpolated variable.
#
#   M2 -> test_stale_lock_does_not_deadlock
#     --expr 's#LOCK_STALE_SECS=60#LOCK_STALE_SECS=999999999#'
#   The aged claim is never swept, so no spawn happens. Occurs once as the
#   declaration; every use is "$LOCK_STALE_SECS".
#
#   M3 -> test_release_is_trapped_for_signals
#     --expr 's#trap release_start_claim EXIT INT TERM#trap release_start_claim EXIT#'
#   Still valid bash, so nothing aborts — only the signal-coverage case reddens.
#
#   M4 -> test_hook_copies_are_identical
#     --file cogni-portfolio/hooks/ensure-excalidraw-canvas.sh
#     --expr 's#LOCK_STALE_SECS=60#LOCK_STALE_SECS=61#'
#   Mutates the other copy so the pair diverges. Run against the cogni-visual
#   suite, which reads both copies, so a drift introduced on either side reddens.
#
#   Mutating a hook copy is required: these cases assert hook behaviour, so
#   mutating this suite or a docs file would prove nothing. All four recipes
#   were replayed against the shared harness and each returned guard_verified.

set -u

HERE="$(cd "$(dirname "$0")" && pwd)"
PLUGIN_DIR="$(cd "$HERE/.." && pwd)"
REPO_ROOT="$(cd "$PLUGIN_DIR/.." && pwd)"
VISUAL_HOOK="$REPO_ROOT/cogni-visual/hooks/ensure-excalidraw-canvas.sh"
PORTFOLIO_HOOK="$REPO_ROOT/cogni-portfolio/hooks/ensure-excalidraw-canvas.sh"
VISUAL_HOOKS_JSON="$REPO_ROOT/cogni-visual/hooks/hooks.json"
PORTFOLIO_HOOKS_JSON="$REPO_ROOT/cogni-portfolio/hooks/hooks.json"

failures=0

# Emitters stay plain: no escape sequence may precede a result label, or a
# genuinely red case reports as case_not_found to the mutation harness. The
# case id is always a separate argument, so the harness's whole-token match
# against the label holds.
pass() { printf 'ok: %s %s\n' "$1" "${2:-}"; }
fail() { printf 'FAIL: %s %s\n' "$1" "${2:-}" >&2; failures=$((failures + 1)); }

TMPROOT="$(mktemp -d)"
STARTED_PIDS=""

cleanup() {
  for p in $STARTED_PIDS; do
    kill "$p" 2>/dev/null || true
  done
  rm -rf "$TMPROOT"
}
trap cleanup EXIT

# Build a sandbox: an EXCALIDRAW_MCP_DIR with a dist/server.js fixture, plus a
# stub bin/ shadowing every external the hook shells out to.
#
#   node  records one line per spawn, waits, then signals "port up" by creating
#         the marker, and finally execs sleep so the recorded pid stays live
#         (canvas.pid must name a live process). The wait is what forces real
#         contention: without it the second invocation would take the fast path
#         and the case would pass vacuously.
#   nc    reports the port up only once the marker exists — the cold canvas.
#   curl  reports a connected websocket client once the port is up, so the
#         browser branch is never reached.
make_fixture() {
  fx="$TMPROOT/$1"
  mkdir -p "$fx/mcp/dist" "$fx/bin"
  : > "$fx/mcp/dist/server.js"
  : > "$fx/spawns.log"

  cat > "$fx/bin/node" <<EOF
#!/usr/bin/env bash
echo spawn >> "$fx/spawns.log"
sleep 0.7
: > "$fx/port.up"
exec sleep 30
EOF

  cat > "$fx/bin/nc" <<EOF
#!/usr/bin/env bash
[ -f "$fx/port.up" ]
EOF

  cat > "$fx/bin/curl" <<EOF
#!/usr/bin/env bash
[ -f "$fx/port.up" ] || exit 1
printf '%s\n' '{"websocket_clients":1}'
EOF

  printf '#!/usr/bin/env bash\nexit 0\n' > "$fx/bin/open"
  cp "$fx/bin/open" "$fx/bin/xdg-open"
  chmod +x "$fx/bin/node" "$fx/bin/nc" "$fx/bin/curl" "$fx/bin/open" "$fx/bin/xdg-open"
}

# Run the hook against a sandbox. stdin must be /dev/null: the hook consumes
# stdin to avoid a broken pipe and would otherwise block on an inherited
# terminal.
run_hook() {
  fx="$TMPROOT/$1"
  PATH="$fx/bin:$PATH" \
  EXCALIDRAW_MCP_DIR="$fx/mcp" \
  EXCALIDRAW_CANVAS_PORT=39117 \
    bash "$VISUAL_HOOK" < /dev/null > "$fx/out.$2" 2>&1
}

spawn_count() { wc -l < "$TMPROOT/$1/spawns.log" | tr -d ' '; }

# Strip comments before asserting on code: the hook's prose deliberately names
# the primitives it forbids ("never mkdir -p", "flock is not stock on macOS"),
# so an unstripped grep would match the explanation rather than the code.
hook_code() { sed 's/#.*//' "$1"; }

# AC 1 + AC 2 + AC 3: two concurrent invocations against a cold canvas spawn
# exactly one server, canvas.pid names a live process, and both exit 0.
test_cold_start_spawns_exactly_one_server() {
  c=cold; make_fixture "$c"
  run_hook "$c" a & pa=$!
  run_hook "$c" b & pb=$!
  wait "$pa"; rca=$?
  wait "$pb"; rcb=$?

  n="$(spawn_count "$c")"
  if [ "$n" = "1" ]; then
    pass test_cold_start_spawns_exactly_one_server "exactly one spawn"
  else
    fail test_cold_start_spawns_exactly_one_server "expected 1 spawn, got $n"
  fi

  if [ "$rca" = "0" ] && [ "$rcb" = "0" ]; then
    pass test_cold_start_spawns_exactly_one_server "both invocations exited 0"
  else
    fail test_cold_start_spawns_exactly_one_server "exit codes were $rca and $rcb"
  fi

  pidfile="$TMPROOT/$c/mcp/canvas.pid"
  if [ -f "$pidfile" ]; then
    livepid="$(cat "$pidfile")"
    STARTED_PIDS="$STARTED_PIDS $livepid"
    if kill -0 "$livepid" 2>/dev/null; then
      pass test_cold_start_spawns_exactly_one_server "canvas.pid names a live process"
    else
      fail test_cold_start_spawns_exactly_one_server "canvas.pid $livepid is not live"
    fi
  else
    fail test_cold_start_spawns_exactly_one_server "canvas.pid was never written"
  fi

  if [ -d "$TMPROOT/$c/mcp/canvas-start.lock" ]; then
    fail test_cold_start_spawns_exactly_one_server "claim was not released"
  else
    pass test_cold_start_spawns_exactly_one_server "claim released"
  fi
}

# AC 5: a claim left behind by a killed spawn is swept, not waited on forever.
test_stale_lock_does_not_deadlock() {
  c=stale; make_fixture "$c"
  mkdir -p "$TMPROOT/$c/mcp/canvas-start.lock"
  touch -t 202001010000 "$TMPROOT/$c/mcp/canvas-start.lock"

  run_hook "$c" a; rc=$?

  n="$(spawn_count "$c")"
  if [ "$n" = "1" ] && [ "$rc" = "0" ]; then
    pass test_stale_lock_does_not_deadlock "stale claim swept and server started"
  else
    fail test_stale_lock_does_not_deadlock "expected 1 spawn and rc 0, got $n and $rc"
  fi

  pidfile="$TMPROOT/$c/mcp/canvas.pid"
  if [ -f "$pidfile" ]; then
    STARTED_PIDS="$STARTED_PIDS $(cat "$pidfile")"
  fi

  if [ -d "$TMPROOT/$c/mcp/canvas-start.lock" ]; then
    fail test_stale_lock_does_not_deadlock "claim was not released"
  else
    pass test_stale_lock_does_not_deadlock "claim released"
  fi
}

# AC 4: the two plugin-private copies must not drift apart. Their hooks.json
# pair is checked too — the shared matcher is what makes the double dispatch
# happen at all. Each path is floored on existence so a deleted file cannot
# read as identical.
test_hook_copies_are_identical() {
  for f in "$VISUAL_HOOK" "$PORTFOLIO_HOOK" "$VISUAL_HOOKS_JSON" "$PORTFOLIO_HOOKS_JSON"; do
    if [ ! -s "$f" ]; then
      fail test_hook_copies_are_identical "missing or empty: $f"
      return
    fi
  done

  if cmp -s "$VISUAL_HOOK" "$PORTFOLIO_HOOK"; then
    pass test_hook_copies_are_identical "hook copies are byte-identical"
  else
    fail test_hook_copies_are_identical "hook copies have diverged"
  fi

  if cmp -s "$VISUAL_HOOKS_JSON" "$PORTFOLIO_HOOKS_JSON"; then
    pass test_hook_copies_are_identical "hooks.json copies are byte-identical"
  else
    fail test_hook_copies_are_identical "hooks.json copies have diverged"
  fi
}

# Per-arm liveness floor the behavioural cases cannot reach: a release armed
# for EXIT alone would pass every case above and still strand the claim when
# the harness kills the hook at its declared timeout.
test_release_is_trapped_for_signals() {
  for h in "$VISUAL_HOOK" "$PORTFOLIO_HOOK"; do
    code="$(hook_code "$h")"

    traps="$(printf '%s\n' "$code" | grep -c '^trap ')"
    if [ "$traps" != "1" ]; then
      fail test_release_is_trapped_for_signals "expected exactly 1 trap line in $h, got $traps"
      continue
    fi

    trapline="$(printf '%s\n' "$code" | grep '^trap ')"
    case "$trapline" in
      *EXIT*INT*TERM*) pass test_release_is_trapped_for_signals "release trapped for EXIT INT TERM" ;;
      *) fail test_release_is_trapped_for_signals "trap does not cover INT/TERM: $trapline" ;;
    esac

    if printf '%s\n' "$code" | grep -q 'mkdir -p'; then
      fail test_release_is_trapped_for_signals "claim uses mkdir -p, which cannot tell winner from loser"
    else
      pass test_release_is_trapped_for_signals "claim is a bare mkdir"
    fi

    # The release must be guarded by the claim flag, or a loser deletes the
    # winner's claim on its way out through the shared wait-loop exits.
    if printf '%s\n' "$code" | grep -A 3 'release_start_claim()' | grep -q 'SPAWN_CLAIMED'; then
      pass test_release_is_trapped_for_signals "release is guarded by the claim flag"
    else
      fail test_release_is_trapped_for_signals "release is not guarded by the claim flag in $h"
    fi

    # The staleness sweep must outlast the hook's own declared timeout, or a
    # healthy in-flight winner gets robbed and the double spawn comes back.
    secs="$(printf '%s\n' "$code" | sed -n 's/^LOCK_STALE_SECS=\([0-9][0-9]*\)$/\1/p')"
    hooks_json="$(dirname "$h")/hooks.json"
    timeout="$(sed -n 's/.*"timeout"[ ]*:[ ]*\([0-9][0-9]*\).*/\1/p' "$hooks_json" | head -1)"
    if [ -n "$secs" ] && [ -n "$timeout" ] && [ "$secs" -gt "$timeout" ]; then
      pass test_release_is_trapped_for_signals "staleness $secs s outlasts the $timeout s hook timeout"
    else
      fail test_release_is_trapped_for_signals "staleness ($secs) does not outlast the hook timeout ($timeout)"
    fi
  done
}

ALL_TESTS="test_cold_start_spawns_exactly_one_server test_stale_lock_does_not_deadlock test_hook_copies_are_identical test_release_is_trapped_for_signals"

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
  printf '\nRESULT: %d check(s) failed\n' "$failures" >&2
  exit 1
fi
printf '\nRESULT: all checks passed\n'

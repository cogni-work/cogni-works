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
#   M5 -> test_stale_lock_survives_divergent_stat
#     --expr 's#\[\[ "\$lock_mtime" =~ \^\[0-9\]\+\$ \]\]#[[ -n "\$lock_mtime" ]]#'
#   Reverts the mtime floor to the emptiness test, which structurally cannot see
#   a successful wrong answer: the stub's non-numeric reading survives it,
#   reaches the arithmetic, and aborts the hook. Occurs once.
#
#   M6 -> test_stale_lock_survives_divergent_stat
#     --expr 's#stat -c %Y "\$LOCK_DIR"#stat -f %m "\$LOCK_DIR"#'
#   Puts the BSD form first, leaving the GNU arm unreachable on the platform
#   that needs it. The floor keeps the behavioural arm green, so only the
#   ordering arm reddens — which is exactly the defence-in-depth split. Occurs
#   once; the quoted form is deliberately absent from every comment.
#
#   Mutating a hook copy is required: these cases assert hook behaviour, so
#   mutating this suite or a docs file would prove nothing. All six recipes
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

# Shadow `stat` with one whose flag semantics diverge from the BSD shape this
# hook was first written against. make_fixture deliberately does not stub it:
# stat is the one external here whose flags mean different things on different
# platforms, so leaving it real is what let a Linux-only defect pass a macOS
# run. The hook carries the full rationale for the chain order.
#
# Non-numeric for BOTH forms on purpose: what is pinned is the numeric floor
# itself — that no unusable reading can reach the arithmetic — not which arm of
# the chain happened to answer.
add_divergent_stat_stub() {
  fx="$TMPROOT/$1"
  cat > "$fx/bin/stat" <<'STATSTUB'
#!/usr/bin/env bash
echo /
exit 0
STATSTUB
  chmod +x "$fx/bin/stat"
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

# Plant an aged claim: the state both stale-sweep cases start from.
plant_stale_claim() {
  mkdir -p "$TMPROOT/$1/mcp/canvas-start.lock"
  touch -t 202001010000 "$TMPROOT/$1/mcp/canvas-start.lock"
}

# Shared post-conditions for both stale-sweep cases: exactly one server
# started, the hook exited 0, and the claim was released again. Kept in one
# place so a change to what "swept successfully" means cannot land on one case
# and silently leave the other asserting the old contract — that failure mode
# is a GREEN suite, since each case stays self-consistent.
#
# The case name travels as a separate argument all the way to pass/fail, so
# the mutation harness's whole-token match on the result label still holds.
assert_stale_claim_swept() {
  _case="$1"; _c="$2"; _rc="$3"; _label="$4"

  _n="$(spawn_count "$_c")"
  if [ "$_n" = "1" ] && [ "$_rc" = "0" ]; then
    pass "$_case" "$_label"
  else
    fail "$_case" "expected 1 spawn and rc 0, got $_n and $_rc"
  fi

  _pidfile="$TMPROOT/$_c/mcp/canvas.pid"
  if [ -f "$_pidfile" ]; then
    STARTED_PIDS="$STARTED_PIDS $(cat "$_pidfile")"
  fi

  if [ -d "$TMPROOT/$_c/mcp/canvas-start.lock" ]; then
    fail "$_case" "claim was not released"
  else
    pass "$_case" "claim released"
  fi
}

# AC 5: a claim left behind by a killed spawn is swept, not waited on forever.
test_stale_lock_does_not_deadlock() {
  c=stale; make_fixture "$c"; plant_stale_claim "$c"

  run_hook "$c" a; rc=$?

  assert_stale_claim_swept test_stale_lock_does_not_deadlock "$c" "$rc" \
    "stale claim swept and server started"
}

# The sweep must survive a stat whose flags mean something else. This is the
# cross-platform contract: the suite runs on macOS but CI (and most users) run
# Linux, so a chain that only works under BSD semantics passes locally and dies
# there. Two arms, because the fix has two independent halves and neither one
# alone is observable through the other.
test_stale_lock_survives_divergent_stat() {
  # Ordering arm first, and deliberately so. It is a static read of two files
  # (sub-second) while the behavioural arm below costs a real hook run against
  # a stubbed canvas (seconds). It is also the ONLY arm that reddens when the
  # chain order is reverted — the numeric floor keeps the behavioural arm green
  # by design — so running it first is where the failing path gets its feedback.
  #
  # Textual by necessity: because that floor makes both orders behave
  # identically at runtime, no behavioural case can reach the ordering. It
  # still matters — a BSD-first chain leaves the GNU arm dead on the platform
  # that needs it, and the floor then silently degrades every sweep to
  # "ancient" instead of reading the real age.
  for h in "$VISUAL_HOOK" "$PORTFOLIO_HOOK"; do
    chain="$(hook_code "$h" | grep -E 'lock_mtime=\$\(stat ' | head -1)"
    if [ -z "$chain" ]; then
      fail test_stale_lock_survives_divergent_stat "no stat chain found in $h"
      continue
    fi
    case "$chain" in
      *"stat -c "*"stat -f "*)
        pass test_stale_lock_survives_divergent_stat "GNU form precedes BSD form in $h" ;;
      *)
        fail test_stale_lock_survives_divergent_stat "chain is not GNU-first in $h: $chain" ;;
    esac
  done

  # Behavioural arm. Pre-fix this is rc 1 with 0 spawns: the mtime read
  # succeeds with a non-numeric value, which reaches the arithmetic and aborts
  # the hook under set -e before it can ever spawn.
  c=divergentstat; make_fixture "$c"; add_divergent_stat_stub "$c"
  plant_stale_claim "$c"

  run_hook "$c" a; rc=$?

  assert_stale_claim_swept test_stale_lock_survives_divergent_stat "$c" "$rc" \
    "swept and started despite a divergent stat"
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

    traps="$(printf '%s\n' "$code" | grep -cE '^[[:space:]]*trap ')"
    if [ "$traps" != "1" ]; then
      fail test_release_is_trapped_for_signals "expected exactly 1 trap line in $h, got $traps"
      continue
    fi

    trapline="$(printf '%s\n' "$code" | grep -E '^[[:space:]]*trap ')"
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

    # No claim machinery may sit above the fast path: an already-warm canvas
    # must stay a bare probe plus a /health call, and the acceptance contract
    # pins this textually, not just by runtime cost.
    fastline="$(printf '%s\n' "$code" | grep -n 'has_ws_client; then' | head -1 | cut -d: -f1)"
    if [ -n "$fastline" ]; then
      above="$(printf '%s\n' "$code" | sed -n "1,${fastline}p" | grep -cE 'LOCK_DIR|LOCK_STALE_SECS|SPAWN_CLAIMED|canvas-start.lock|_claim')"
      if [ "$above" = "0" ]; then
        pass test_release_is_trapped_for_signals "fast path carries no claim machinery"
      else
        fail test_release_is_trapped_for_signals "$above claim token(s) above the fast path in $h"
      fi
    else
      fail test_release_is_trapped_for_signals "could not locate the fast path in $h"
    fi

    # The staleness sweep must outlast the hook's own declared timeout, or a
    # healthy in-flight winner gets robbed and the double spawn comes back.
    secs="$(printf '%s\n' "$code" | sed -n 's/^[[:space:]]*LOCK_STALE_SECS=\([0-9][0-9]*\)[[:space:]]*$/\1/p')"
    hooks_json="$(dirname "$h")/hooks.json"
    timeout="$(sed -n 's/.*"timeout"[ ]*:[ ]*\([0-9][0-9]*\).*/\1/p' "$hooks_json" | head -1)"
    if [ -n "$secs" ] && [ -n "$timeout" ] && [ "$secs" -gt "$timeout" ]; then
      pass test_release_is_trapped_for_signals "staleness $secs s outlasts the $timeout s hook timeout"
    else
      fail test_release_is_trapped_for_signals "staleness ($secs) does not outlast the hook timeout ($timeout)"
    fi
  done
}

ALL_TESTS="test_cold_start_spawns_exactly_one_server test_stale_lock_does_not_deadlock test_stale_lock_survives_divergent_stat test_hook_copies_are_identical test_release_is_trapped_for_signals"

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

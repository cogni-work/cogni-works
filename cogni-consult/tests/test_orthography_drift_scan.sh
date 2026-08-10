#!/usr/bin/env bash
# Suite for scripts/orthography-drift-scan.py — the read-only scan that reports Swiss-ss
# spellings sitting in ß positions across an engagement's stored corpus.
#
# Fixtures are heredoc'd inline: no engagement corpus is committed anywhere in the repo,
# so every case builds a minimal engagement in a temp directory.
#
# Coverage
#   1  clean            correct short-vowel ss (dass, muss, Prozess) reports nothing
#   2  markdown-finding a Swiss form in scope/key-question.md carries path, line, form,
#                       suggestion
#   3  stem-match       Messgrösse is reported from the bare Grösse entry (a whole-word
#                       matcher would miss the issue's own headline example)
#   4  case-variance    both heisst and sentence-initial Heisst report
#   5  homographs       Masse and Busse are not entries and report nothing
#   6  json-prose-key   field.json `framing` reports; a Swiss-looking non-prose slug does not
#   7  dot-directory    .metadata/decision-log.json `rationale` reports
#   8  generated-echo   marker-bearing echoes are excluded, a marker-less file is not
#   8b escaped-json     \uXXXX-escaped JSON values are decoded before matching, so a
#                       file written with ensure_ascii=True does not silently lose
#                       every non-ASCII entry
#   9  failure-paths    engagement_missing, not_a_directory, usage
#  10  envelope-shape   exactly one stdout line per exit path; literal ß bytes, no escapes
#  11  read-only-flag   --fix is rejected as unexpected_argument
#  12  read-only-tree   the fixture tree is byte-identical before and after a scan
#  13  goes-red         emptying the pair list, or anchoring the matcher whole-word,
#                       flips this suite's own detection cases red
#
# Usage: bash cogni-consult/tests/test_orthography_drift_scan.sh   (no args, no network)

set -u

TESTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGIN_DIR="$(dirname "$TESTS_DIR")"
SCRIPT="$PLUGIN_DIR/scripts/orthography-drift-scan.py"

if [ ! -f "$SCRIPT" ]; then
  echo "FAIL orthography-drift-scan.py not found at $SCRIPT" >&2
  exit 1
fi

TMPROOT="$(mktemp -d)"
trap 'rm -rf "$TMPROOT"' EXIT

failures=0
pass() { printf 'OK   %s\n' "$1"; }
fail() { printf 'FAIL %s: %s\n' "$1" "$2" >&2; failures=$((failures + 1)); }

# Always invoked through python3: this plugin's script mode bits are mixed, and a copied
# fixture need not keep the executable bit.
scan() { python3 "$SCRIPT" "$@" 2>/dev/null; }

assert_envelope() {
  # assert_envelope <name> <want_success> <want_failed_check-or-empty> <envelope>
  local name="$1" want_success="$2" want_check="$3" envelope="$4"
  local verdict
  verdict="$(printf '%s' "$envelope" | python3 -c '
import json, sys
want_success = sys.argv[1] == "true"
want_check = sys.argv[2]
try:
    d = json.loads(sys.stdin.read())
except Exception as exc:
    print("unparseable envelope: %s" % exc)
    raise SystemExit(0)
if d.get("success") is not want_success:
    print("success is %r, want %r" % (d.get("success"), want_success))
    raise SystemExit(0)
if want_check:
    got = (d.get("data") or {}).get("failed_check")
    if got != want_check:
        print("failed_check is %r, want %r" % (got, want_check))
        raise SystemExit(0)
    if not d.get("error"):
        print("error is empty on a failure envelope")
        raise SystemExit(0)
print("")
' "$want_success" "$want_check")"
  if [ -z "$verdict" ]; then
    pass "$name"
  else
    fail "$name" "$verdict"
  fi
}

# Prints data.total_findings out of an envelope. Deliberately not a generic dotted-path
# walker: a typo would print a parent object instead of raising on the bad key, and the
# assertion would then fail with an opaque value.
total_findings() {
  printf '%s' "$1" | python3 -c '
import json, sys
print(json.loads(sys.stdin.read())["data"]["total_findings"])
'
}

# Counts findings whose form == $1 in the envelope $2.
count_form() {
  printf '%s' "$2" | python3 -c '
import json, sys
d = json.loads(sys.stdin.read())
print(sum(1 for f in d["data"]["findings"] if f["form"] == sys.argv[1]))
' "$1"
}

digest_tree() {
  python3 -c '
import hashlib, os, sys
root = sys.argv[1]
h = hashlib.sha256()
for dirpath, dirnames, filenames in os.walk(root):
    dirnames.sort()
    for name in sorted(filenames):
        p = os.path.join(dirpath, name)
        h.update(os.path.relpath(p, root).encode("utf-8"))
        with open(p, "rb") as fh:
            h.update(fh.read())
print(h.hexdigest())
' "$1"
}

# --- fixtures ---------------------------------------------------------------

build_clean() {
  local e="$TMPROOT/clean"
  mkdir -p "$e/scope"
  cat > "$e/scope/key-question.md" <<'MD'
Der Prozess muss zeigen, dass die Masse und die Busse korrekt sind.
Einfluss und Ergebnis bleiben davon unberührt.
MD
  printf '%s' "$e"
}

build_drift() {
  local e="$TMPROOT/drift"
  mkdir -p "$e/scope" "$e/action-fields/wirkungsmodell" "$e/.metadata" "$e/sources"
  cat > "$e/scope/key-question.md" <<'MD'
Die Messgrösse heisst Wirkung.
Heisst das etwas anderes?
Der Prozess muss zeigen, dass Masse und Busse korrekt sind.
Die Grösse bleibt offen.
MD
  cat > "$e/action-fields/wirkungsmodell/field.json" <<'JSON'
{
  "title": "Wirkungsmodell",
  "framing": "Wir gehen schliesslich so vor.",
  "deliverable": "messgrösse-analyse",
  "state": "open",
  "dt_stage": "ideate"
}
JSON
  cat > "$e/.metadata/decision-log.json" <<'JSON'
{
  "entries": [
    {"kind": "decision", "rationale": "Die Strasse ist gemäss Plan gewählt.", "verdict": "ok"}
  ]
}
JSON
  # Generated echoes carry the footer sentinel their generators write; that marker,
  # not the path, is what excludes them.
  printf 'Dieser Auszug heisst anders.\n\n---\n\n_Auto-generated front door._\n' > "$e/README.md"
  printf 'Register-Auszug mit Grösse darin.\n\n---\n\n_Auto-generated register._\n' > "$e/assumptions.md"
  # No marker: a hand-authored scaffold IS a source the consultant edits, so it must
  # be scanned rather than excluded.
  printf 'Quellen-Auszug: die Strasse.\n' > "$e/sources/README.md"
  printf '%s' "$e"
}

# A field.json written the way json.dump writes it by default: ensure_ascii=True, so
# every non-ASCII pair-list entry arrives as a \uXXXX escape.
build_escaped_json() {
  local e="$TMPROOT/escaped"
  mkdir -p "$e/action-fields/x"
  python3 -c '
import json, sys
json.dump(
    {"framing": "Wir gehen schliesslich vor, gemäss der Grösse."},
    open(sys.argv[1], "w"),
    ensure_ascii=True,
)
' "$e/action-fields/x/field.json"
  printf '%s' "$e"
}

CLEAN="$(build_clean)"
DRIFT="$(build_drift)"
ESCAPED="$(build_escaped_json)"

# Captured BEFORE any scan runs, so case 12's read-only claim is load-bearing: taking
# the baseline after a scan would bake any mutation into it and the comparison would
# pass regardless.
DRIFT_DIGEST_BEFORE="$(digest_tree "$DRIFT")"

# --- 1  clean ---------------------------------------------------------------

env_clean="$(scan "$CLEAN")"
assert_envelope "clean: envelope" true "" "$env_clean"
if [ "$(total_findings "$env_clean")" = "0" ]; then
  pass "clean: dass/muss/Prozess/Masse/Busse report nothing"
else
  fail "clean" "expected 0 findings, got $(total_findings "$env_clean")"
fi

env_drift="$(scan "$DRIFT")"
assert_envelope "drift: envelope is success (drift is a successful scan)" true "" "$env_drift"
if [ "$(total_findings "$env_drift")" -gt 0 ]; then
  pass "drift: reports a non-zero finding count"
else
  fail "drift" "expected findings, got 0"
fi

# --- 2  markdown-finding ----------------------------------------------------

shape="$(printf '%s' "$env_drift" | python3 -c '
import json, sys
d = json.loads(sys.stdin.read())
hits = [f for f in d["data"]["findings"]
        if f["path"] == "scope/key-question.md" and f["form"] == "Grösse"]
if not hits:
    print("no Grösse finding in scope/key-question.md")
    raise SystemExit(0)
f = hits[0]
missing = [k for k in ("path", "line", "form", "suggestion") if k not in f]
if missing:
    print("finding missing keys: %s" % missing)
elif f["line"] != 4:
    print("expected line 4, got %r" % f["line"])
elif f["suggestion"] != "Größe":
    print("expected suggestion Größe, got %r" % f["suggestion"])
else:
    print("")
')"
if [ -z "$shape" ]; then
  pass "markdown-finding: path + line + form + suggestion"
else
  fail "markdown-finding" "$shape"
fi

# --- 3  stem-match ----------------------------------------------------------

if [ "$(count_form 'grösse' "$env_drift")" = "1" ]; then
  pass "stem-match: Messgrösse reported from the bare Grösse entry"
else
  fail "stem-match" "expected 1 lowercase grösse finding (from Messgrösse), got $(count_form 'grösse' "$env_drift")"
fi

# --- 4  case-variance -------------------------------------------------------

if [ "$(count_form 'heisst' "$env_drift")" -ge 1 ] && [ "$(count_form 'Heisst' "$env_drift")" -ge 1 ]; then
  pass "case-variance: heisst and sentence-initial Heisst both report"
else
  fail "case-variance" "heisst=$(count_form 'heisst' "$env_drift") Heisst=$(count_form 'Heisst' "$env_drift"), want both >= 1"
fi

# --- 5  homographs ----------------------------------------------------------

if [ "$(count_form 'Masse' "$env_drift")" = "0" ] && [ "$(count_form 'Busse' "$env_drift")" = "0" ]; then
  pass "homographs: Masse and Busse are not entries"
else
  fail "homographs" "Masse and Busse must never be reported — spelling cannot disambiguate them"
fi

# --- 6  json-prose-key ------------------------------------------------------

json_verdict="$(printf '%s' "$env_drift" | python3 -c '
import json, sys
d = json.loads(sys.stdin.read())
fs = d["data"]["findings"]
framing = [f for f in fs if f["path"].endswith("field.json") and f["form"] == "schliesslich"]
slug = [f for f in fs if f.get("json_key") == "deliverable"]
if not framing:
    print("field.json framing finding missing")
elif framing[0].get("json_key") != "framing":
    print("expected json_key framing, got %r" % framing[0].get("json_key"))
elif slug:
    print("a non-prose key (deliverable) produced a finding: %r" % slug)
else:
    print("")
')"
if [ -z "$json_verdict" ]; then
  pass "json-prose-key: framing reports, the non-prose deliverable slug does not"
else
  fail "json-prose-key" "$json_verdict"
fi

# --- 7  dot-directory ------------------------------------------------------

dot_verdict="$(printf '%s' "$env_drift" | python3 -c '
import json, sys
d = json.loads(sys.stdin.read())
fs = [f for f in d["data"]["findings"] if f["path"].startswith(".metadata/")]
forms = sorted(f["form"] for f in fs)
if not fs:
    print("nothing found under .metadata/ — the dot-directory was skipped")
elif "Strasse" not in forms:
    print("expected Strasse from decision-log rationale, got %s" % forms)
elif any(f.get("json_key") != "rationale" for f in fs):
    print("unexpected json_key among %r" % fs)
else:
    print("")
')"
if [ -z "$dot_verdict" ]; then
  pass "dot-directory: .metadata/decision-log.json rationale reports"
else
  fail "dot-directory" "$dot_verdict"
fi

# --- 8  generated-echo -----------------------------------------------------

echo_verdict="$(printf '%s' "$env_drift" | python3 -c '
import json, os, sys
d = json.loads(sys.stdin.read())
marked = {"README.md", "assumptions.md"}
unmarked = os.path.join("sources", "README.md")
excluded = set(d["data"]["excluded"])
paths = {f["path"] for f in d["data"]["findings"]}
if excluded != marked:
    print("excluded is %s, want exactly the marker-bearing %s" % (sorted(excluded), sorted(marked)))
elif paths & marked:
    print("a marker-bearing echo produced findings: %s" % sorted(paths & marked))
elif unmarked not in paths:
    print("the marker-less %s was not scanned — path-based exclusion would blind a hand-authored file" % unmarked)
else:
    print("")
')"
if [ -z "$echo_verdict" ]; then
  pass "generated-echo: marker-bearing echoes excluded, a marker-less file still scanned"
else
  fail "generated-echo" "$echo_verdict"
fi

# --- 8b  escaped-json ------------------------------------------------------

env_escaped="$(scan "$ESCAPED")"
esc_verdict="$(printf '%s' "$env_escaped" | python3 -c '
import json, sys
d = json.loads(sys.stdin.read())
forms = sorted(f["form"] for f in d["data"]["findings"])
want = ["Grösse", "gemäss", "schliesslich"]
if forms != want:
    print("got %s, want %s — a \\uXXXX-escaped value must still match" % (forms, want))
else:
    print("")
')"
if [ -z "$esc_verdict" ]; then
  pass "escaped-json: \\uXXXX-escaped values are decoded before matching"
else
  fail "escaped-json" "$esc_verdict"
fi

# --- 9  failure-paths ------------------------------------------------------

assert_envelope "failure-paths: missing engagement" false "engagement_missing" "$(scan "$TMPROOT/does-not-exist")"
assert_envelope "failure-paths: not a directory" false "not_a_directory" "$(scan "$DRIFT/scope/key-question.md")"
assert_envelope "failure-paths: no argument" false "usage" "$(scan)"

# --- 10  envelope-shape ----------------------------------------------------

lines_ok=1
for envelope in "$env_clean" "$env_drift" "$(scan "$TMPROOT/does-not-exist")" "$(scan)"; do
  if [ "$(printf '%s\n' "$envelope" | wc -l | tr -d ' ')" != "1" ]; then
    lines_ok=0
  fi
done
if [ "$lines_ok" -eq 1 ]; then
  pass "envelope-shape: exactly one stdout line on every exit path"
else
  fail "envelope-shape" "an exit path emitted a preamble line before the JSON"
fi

if printf '%s' "$env_drift" | grep -qF 'Grösse' \
  && printf '%s' "$env_drift" | grep -qF 'Größe' \
  && ! printf '%s' "$env_drift" | grep -q 'u00df'; then
  pass "envelope-shape: literal ß bytes, no ASCII substitutes and no \\u escapes"
else
  fail "envelope-shape" "reported forms must be the literal bytes Grösse / Größe"
fi

# --- 11  read-only-flag ----------------------------------------------------

assert_envelope "read-only-flag: --fix rejected" false "unexpected_argument" "$(scan "$DRIFT" --fix)"

# --- 12  read-only-tree ----------------------------------------------------

scan "$DRIFT" >/dev/null
after="$(digest_tree "$DRIFT")"
if [ "$DRIFT_DIGEST_BEFORE" = "$after" ]; then
  pass "read-only-tree: fixture tree byte-identical across a drift-reporting scan"
else
  fail "read-only-tree" "the scan modified the corpus it was asked to inspect"
fi

# --- 13  goes-red ----------------------------------------------------------
#
# Each mutation must (a) actually apply — a no-op regex would let a broken detector
# look defended — (b) still emit a valid success envelope, so a crash is never mistaken
# for detection, and (c) lose the specific finding it was aimed at.

mutate() {
  # mutate <dest> <python-re-program-name>
  python3 - "$SCRIPT" "$1" "$2" <<'PY'
import re, sys
src_path, dest_path, which = sys.argv[1], sys.argv[2], sys.argv[3]
src = open(src_path, encoding="utf-8").read()
if which == "empty-pairs":
    mutated, n = re.subn(
        r"# --- swiss-pairs-begin ---.*?# --- swiss-pairs-end ---",
        "# --- swiss-pairs-begin ---\nSWISS_PAIRS = ()\n# --- swiss-pairs-end ---",
        src,
        count=1,
        flags=re.S,
    )
elif which == "anchor-whole-word":
    mutated, n = re.subn(
        r"re\.compile\(re\.escape\(form\)\)",
        r're.compile(r"\\b" + re.escape(form) + r"\\b")',
        src,
        count=1,
    )
else:
    raise SystemExit("unknown mutation %s" % which)
if n != 1:
    raise SystemExit("mutation %s applied %d times, want exactly 1" % (which, n))
if mutated == src:
    raise SystemExit("mutation %s changed nothing" % which)
open(dest_path, "w", encoding="utf-8").write(mutated)
PY
}

mutant_findings() {
  python3 "$1" "$DRIFT" 2>/dev/null
}

# 13a  the curated pair list emptied — detection must collapse to zero
if mutate "$TMPROOT/mutant_empty.py" empty-pairs; then
  env_mut="$(mutant_findings "$TMPROOT/mutant_empty.py")"
  got="$(total_findings "$env_mut" 2>/dev/null || echo unparseable)"
  if [ "$got" = "0" ]; then
    pass "goes-red: emptying SWISS_PAIRS drops every finding (detection has teeth)"
  else
    fail "goes-red/empty-pairs" "mutant still reported $got findings — the pair list is not what drives detection"
  fi
else
  fail "goes-red/empty-pairs" "mutation could not be applied — the sentinel comments moved"
fi

# 13b  matching anchored whole-word — the compound case must be lost
if mutate "$TMPROOT/mutant_anchored.py" anchor-whole-word; then
  env_mut="$(mutant_findings "$TMPROOT/mutant_anchored.py")"
  if printf '%s' "$env_mut" | python3 -c 'import json,sys; sys.exit(0 if json.loads(sys.stdin.read()).get("success") is True else 1)'; then
    if [ "$(count_form 'grösse' "$env_mut")" = "0" ]; then
      pass "goes-red: anchoring the matcher whole-word loses Messgrösse (stem matching is load-bearing)"
    else
      fail "goes-red/anchored" "the anchored mutant still reported Messgrösse — matching is not stem-based"
    fi
  else
    fail "goes-red/anchored" "the anchored mutant did not emit a success envelope — a crash is not detection"
  fi
else
  fail "goes-red/anchored" "mutation could not be applied — the matcher expression moved"
fi

# --- tally -----------------------------------------------------------------

if [ "$failures" -gt 0 ]; then
  echo "$failures assertion(s) failed" >&2
  exit 1
fi
echo "All orthography-drift-scan assertions passed"

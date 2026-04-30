#!/usr/bin/env bash
# check-region-catalogs-hook.sh — PostToolUse drift gate for the three watched files.
#
# Runs silently on edits to any file outside the three watched paths. When one
# of the watched files is touched, runs check-region-catalogs.sh against the
# checked-in baseline and decides one of three outcomes:
#
#   - exit 2  →  Class 1–3 violation (hard structural drift)
#                stderr: BLOCK message + class hints + pointer to audit-region-sources
#   - exit 0  →  New Bucket A/B drift vs baseline
#                stderr: one-line NOTE + pointer to /cogni-workspace:manage-markets
#   - exit 0  →  Drift unchanged or shrunk vs baseline (silent success)
#
# Watched paths:
#   - cogni-workspace/references/supported-markets-registry.json
#   - cogni-research/references/market-sources.json
#   - cogni-trends/skills/trend-report/references/region-authority-sources.json
#
# Never blocks on tooling failure — if the audit script errors or emits an
# unparsable envelope, the hook exits 0. Drift detection must not break the
# user's edit flow.
#
# Hook protocol: reads tool-call JSON from stdin, parses tool_input.file_path.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
BASELINE="$SCRIPT_DIR/baselines/region-catalog-drift-baseline.json"
AUDIT="$SCRIPT_DIR/check-region-catalogs.sh"

# 1. Read tool input from stdin (Claude Code hook protocol).
INPUT="$(cat)"
FILE_PATH="$(printf '%s' "$INPUT" \
  | python3 -c "import sys, json
try:
    d = json.load(sys.stdin)
    print((d.get('tool_input') or {}).get('file_path', ''))
except Exception:
    print('')" 2>/dev/null || echo "")"

# 2. Filter — exit 0 silently on unrelated edits.
case "$FILE_PATH" in
  */cogni-workspace/references/supported-markets-registry.json) ;;
  */cogni-research/references/market-sources.json) ;;
  */cogni-trends/skills/trend-report/references/region-authority-sources.json) ;;
  *) exit 0 ;;
esac

# 3. Run the audit; capture only the JSON envelope (last line). Suppress all
#    other audit output so the hook stays terse.
ENVELOPE="$(bash "$AUDIT" --baseline "$BASELINE" 2>/dev/null | tail -n 1 || true)"
if [ -z "$ENVELOPE" ]; then
  exit 0
fi

# 4. Parse and decide. Never block on tooling failure.
python3 - "$ENVELOPE" "$FILE_PATH" <<'PY'
import json, sys
try:
    env = json.loads(sys.argv[1])
except Exception:
    sys.exit(0)
file_path = sys.argv[2]
data = env.get("data") or {}
violations = data.get("violations") or []
if violations:
    print(f"BLOCK: Class 1–3 region-catalog drift detected on {file_path}", file=sys.stderr)
    for v in violations:
        print(f"  [{v.get('class', '?')}] {v.get('hint', '')}", file=sys.stderr)
    print("Run /cogni-workspace:audit-region-sources for the full report.", file=sys.stderr)
    sys.exit(2)
deltas = (data.get("info_findings") or {}).get("deltas_vs_baseline") or {}
added = (deltas.get("summary") or {}).get("total_domains_added", 0)
if added:
    print(
        f"NOTE: {added} new authority-domain drift finding(s) vs baseline. "
        "Run /cogni-workspace:manage-markets to review and either curate or refresh-baseline.",
        file=sys.stderr,
    )
sys.exit(0)
PY

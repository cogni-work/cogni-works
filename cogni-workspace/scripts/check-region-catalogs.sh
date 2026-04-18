#!/usr/bin/env bash
# check-region-catalogs.sh — Cross-plugin drift checker for the three region catalogs.
#
# Verifies that the region/market keys are consistent across:
#   - cogni-portfolio/skills/portfolio-setup/references/regions.json     (broadest catalog)
#   - cogni-trends/skills/trend-report/references/region-authority-sources.json
#   - cogni-research/references/market-sources.json
#
# Also verifies that cogni-trends DACH region references all CLAUDE.md-curated
# DACH authority sources. The curated list is loaded from
# cogni-workspace/references/curated-region-sources.json — the single source of
# truth synced with CLAUDE.md's "Multilingual European Support" section.
#
# Exits non-zero if any drift is detected with a per-class remediation hint.
# Prints a single-line JSON envelope `{success, data, error}` on the final line
# so callers (CI, hooks, other scripts) can parse the verdict deterministically.
#
# Usage: bash cogni-workspace/scripts/check-region-catalogs.sh

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
PORTFOLIO="${REPO_ROOT}/cogni-portfolio/skills/portfolio-setup/references/regions.json"
TRENDS="${REPO_ROOT}/cogni-trends/skills/trend-report/references/region-authority-sources.json"
RESEARCH="${REPO_ROOT}/cogni-research/references/market-sources.json"
CURATED="${REPO_ROOT}/cogni-workspace/references/curated-region-sources.json"

# Verify all catalog files exist before doing anything else.
for f in "$PORTFOLIO" "$TRENDS" "$RESEARCH" "$CURATED"; do
  if [[ ! -f "$f" ]]; then
    rel="${f#"$REPO_ROOT/"}"
    echo "ERROR: catalog file not found: $rel" >&2
    printf '{"success":false,"data":{},"error":"missing catalog: %s"}\n' "$rel"
    exit 2
  fi
done

# All comparison logic lives in python so the set arithmetic and JSON parsing
# stay readable. The script body is just orchestration.
python3 - "$PORTFOLIO" "$TRENDS" "$RESEARCH" "$CURATED" <<'PY'
import json
import sys

portfolio_path, trends_path, research_path, curated_path = sys.argv[1:5]


def load(path):
    with open(path) as f:
        return json.load(f)


def real_keys(d):
    """Top-level keys that aren't metadata (anything starting with _)."""
    return {k for k in d.keys() if not k.startswith("_")}


portfolio_raw = load(portfolio_path)
trends = load(trends_path)
research = load(research_path)

# CLAUDE.md DACH authority sources — loaded from curated-region-sources.json
# (single source of truth synced with CLAUDE.md 'Multilingual European Support').
EXPECTED_DACH_SOURCES = set(load(curated_path)["dach"])

# cogni-portfolio nests regions under a "regions" key; the other two don't.
portfolio_regions = portfolio_raw.get("regions", portfolio_raw)
portfolio_keys = real_keys(portfolio_regions)
trends_keys = real_keys(trends)
research_keys = real_keys(research)

violations = []

# Drift class 1: regions in trends or research that aren't in portfolio.
# Portfolio is the union-of-markets source of truth (per the issue #46
# Stage 1 option (b) recommendation), so the other two catalogs should be
# subsets of portfolio.
for plugin, keys in (("cogni-trends", trends_keys), ("cogni-research", research_keys)):
    extra = sorted(keys - portfolio_keys)
    if extra:
        violations.append({
            "class": "extra_keys",
            "plugin": plugin,
            "detail": extra,
            "hint": f"{plugin} has region keys not in cogni-portfolio: {extra}. "
                    "Either add them to cogni-portfolio/skills/portfolio-setup/"
                    "references/regions.json or remove from this plugin.",
        })

# Drift class 2: regions in trends and research must agree on their intersection
# with portfolio. Any key that's in one and not the other is drift.
trends_minus_research = sorted(trends_keys - research_keys)
research_minus_trends = sorted(research_keys - trends_keys)
if trends_minus_research:
    violations.append({
        "class": "trends_only",
        "detail": trends_minus_research,
        "hint": f"cogni-trends has region keys missing from cogni-research: "
                f"{trends_minus_research}. Add stub entries to cogni-research/"
                "references/market-sources.json so the two web-search catalogs "
                "stay in sync.",
    })
if research_minus_trends:
    violations.append({
        "class": "research_only",
        "detail": research_minus_trends,
        "hint": f"cogni-research has region keys missing from cogni-trends: "
                f"{research_minus_trends}. Add stub entries to cogni-trends/"
                "skills/trend-report/references/region-authority-sources.json "
                "so the two web-search catalogs stay in sync.",
    })

# Drift class 3: cogni-trends DACH must reference all CLAUDE.md-curated sources.
dach_entry = trends.get("dach", {})
dach_text_blob = json.dumps(dach_entry)
missing_dach = sorted(s for s in EXPECTED_DACH_SOURCES if s not in dach_text_blob)
if missing_dach:
    violations.append({
        "class": "dach_sources",
        "detail": missing_dach,
        "hint": f"cogni-trends DACH entry is missing CLAUDE.md-curated authority "
                f"sources: {missing_dach}. Add them as site_searches under the "
                "appropriate dimension in cogni-trends/skills/trend-report/"
                "references/region-authority-sources.json.",
    })

# Print human-readable summary first.
print(f"cogni-portfolio: {len(portfolio_keys)} region keys")
print(f"cogni-trends:    {len(trends_keys)} region keys")
print(f"cogni-research:  {len(research_keys)} region keys")
print()

if not violations:
    print("OK: all region catalogs agree and cogni-trends DACH references all "
          "CLAUDE.md-curated sources.")
    print(json.dumps({"success": True, "data": {
        "portfolio_keys": sorted(portfolio_keys),
        "trends_keys": sorted(trends_keys),
        "research_keys": sorted(research_keys),
        "violations": [],
    }, "error": ""}))
    sys.exit(0)

print(f"FAIL: {len(violations)} drift class(es) detected.")
print()
for v in violations:
    print(f"  [{v['class']}]")
    print(f"    {v['hint']}")
    print()

print(json.dumps({"success": False, "data": {
    "portfolio_keys": sorted(portfolio_keys),
    "trends_keys": sorted(trends_keys),
    "research_keys": sorted(research_keys),
    "violations": violations,
}, "error": f"{len(violations)} drift class(es) detected"}))
sys.exit(1)
PY

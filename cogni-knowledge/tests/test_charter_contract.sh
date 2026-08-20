#!/usr/bin/env bash
# test_charter_contract.sh — schema-0.1.4 charter contract assertions.
#
# Three surfaces in one file (matching the test_language_config_contract.sh
# style):
#   1. knowledge-binding.py init writes the additive charter{} block +
#      seeds topic_lineage.open_themes[] from --open-themes; a plain init
#      writes a complete all-"" charter (framed_at "") with open_themes [].
#   2. knowledge-setup SKILL.md — the Step 2.5 charter interview + the Step 5
#      first-question on-ramp content invariants (so the steering UX cannot
#      silently regress).
#   3. knowledge-plan / knowledge-resume / knowledge-dashboard SKILL.md —
#      the charter is inherited as grounding (plan) and surfaced read-only
#      (resume/dashboard), all fail-soft via .get on a pre-0.1.4 binding.
#
# bash 3.2 + grep + stdlib python3 only.

set -eu

PLUGIN_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SCRIPT="$PLUGIN_ROOT/scripts/knowledge-binding.py"

. "$(dirname "$0")/fixtures/test_helpers.sh"

errors=0

if [ ! -f "$SCRIPT" ]; then
  red "FAIL: charter-00-knowledge-binding-py-not knowledge-binding.py not found at $SCRIPT"
  exit 1
fi

WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT

# -----------------------------------------------------------------------------
# 1. Script surface — charter block + open_themes.
# -----------------------------------------------------------------------------
KB="$WORK/kb"; mkdir -p "$KB/.cogni-wiki"
echo '{"name":"T","slug":"t","schema_version":"0.0.5"}' > "$KB/.cogni-wiki/config.json"

# Plain init — complete all-"" charter, framed_at "", open_themes [].
python3 "$SCRIPT" init \
  --knowledge-root "$KB" --knowledge-slug t-kb \
  --knowledge-title "T KB" --wiki-path "$KB" >/dev/null
if python3 -c "
import json
b = json.load(open('$KB/.cogni-knowledge/binding.json'))
assert b['schema_version'] == '0.1.5', b['schema_version']
assert b['charter'] == {'domain':'','audience':'','scope':'','framed_at':''}, b['charter']
assert b['topic_lineage']['open_themes'] == [], b['topic_lineage']
print('OK')
" | grep -q OK; then
  green "PASS: charter-01-plain-init-writes-schema plain init writes schema 0.1.5 + complete all-empty charter + empty open_themes"
else
  red "FAIL: charter-01-plain-init-writes-schema plain init charter/open_themes wrong"; errors=$((errors+1))
fi

# Charter init — populated + framed_at stamped + open_themes parsed.
KBC="$WORK/kbc"; mkdir -p "$KBC/.cogni-wiki"
echo '{"name":"T","slug":"t","schema_version":"0.0.5"}' > "$KBC/.cogni-wiki/config.json"
python3 "$SCRIPT" init \
  --knowledge-root "$KBC" --knowledge-slug t-kbc \
  --knowledge-title "T KBC" --wiki-path "$KBC" \
  --charter-domain 'EU AI Act compliance' \
  --charter-audience 'compliance officers' \
  --charter-scope 'EU, 2024-2027' \
  --open-themes 'high-risk systems|conformity assessment|GPAI' >/dev/null
if python3 -c "
import json
b = json.load(open('$KBC/.cogni-knowledge/binding.json'))
c = b['charter']
assert c['domain'] == 'EU AI Act compliance', c
assert c['audience'] == 'compliance officers', c
assert c['scope'] == 'EU, 2024-2027', c
assert c['framed_at'], c
assert b['topic_lineage']['open_themes'] == ['high-risk systems','conformity assessment','GPAI'], b['topic_lineage']
print('OK')
" | grep -q OK; then
  green "PASS: charter-02-charter-init-populates-stamps charter init populates charter{} + stamps framed_at + parses open_themes[]"
else
  red "FAIL: charter-02-charter-init-populates-stamps charter init flags not honoured"; errors=$((errors+1))
fi

# -----------------------------------------------------------------------------
# 2. knowledge-setup SKILL.md — interview + on-ramp invariants.
# -----------------------------------------------------------------------------
SETUP="$PLUGIN_ROOT/skills/knowledge-setup/SKILL.md"
if [ ! -f "$SETUP" ]; then
  red "FAIL: charter-03-skills-knowledge-setup-skill skills/knowledge-setup/SKILL.md not found"
  exit 1
fi
assert_grep 'charter' "$SETUP" "charter-04-documents-charter knowledge-setup: documents the charter"
assert_grep 'charter-domain' "$SETUP" "charter-05-accepts-charter-domain knowledge-setup: accepts --charter-domain"
assert_grep 'open-themes' "$SETUP" "charter-06-accepts-open-themes knowledge-setup: accepts --open-themes"
assert_grep 'no-charter' "$SETUP" "charter-07-no-charter-opt-out knowledge-setup: has a --no-charter opt-out"
assert_grep 'no-prelim-search' "$SETUP" "charter-08-no-prelim-search-opt knowledge-setup: has a --no-prelim-search opt-out for the scan"
assert_grep 'charter-framing.md' "$SETUP" "charter-09-references-charter-framing-playbook knowledge-setup: references the charter-framing playbook"
assert_grep 'WebSearch' "$SETUP" "charter-10-declares-websearch-optional-scan knowledge-setup: declares WebSearch (for the optional scan)"
assert_grep '0.1.4' "$SETUP" "charter-11-names-schema-0-1-4 knowledge-setup: names schema 0.1.4"
assert_grep 'Frame your first research question now' "$SETUP" "charter-12-step-5-first-question knowledge-setup: Step 5 first-question on-ramp prompt"
assert_grep 'knowledge-plan' "$SETUP" "charter-13-ramp-chains-knowledge-plan knowledge-setup: on-ramp chains into knowledge-plan"
assert_grep '\-\-frame' "$SETUP" "charter-14-ramp-forces-question-framing knowledge-setup: on-ramp forces per-question framing via --frame"

# Re-frame lifecycle path (#451): --reframe re-steers an existing base via set-charter.
assert_grep '\-\-reframe' "$SETUP" "charter-15-documents-reframe-re-steer knowledge-setup: documents the --reframe re-steer mode"
assert_grep 'set-charter' "$SETUP" "charter-16-reframe-writes-knowledge-binding knowledge-setup: --reframe writes via knowledge-binding.py set-charter (not init)"

# The four writer-quality knobs stay OUT of the charter (per-run, not charter).
assert_grep 'domain / audience / scope' "$SETUP" "charter-17-charter-domain-audience-scope knowledge-setup: charter is domain / audience / scope (+themes) only"

# WebSearch must be in the frontmatter allowed-tools, not just prose.
if head -6 "$SETUP" | grep -q 'allowed-tools:.*WebSearch'; then
  green "PASS: charter-18-websearch-frontmatter-allowed-tools knowledge-setup: WebSearch in frontmatter allowed-tools"
else
  red "FAIL: charter-18-websearch-frontmatter-allowed-tools knowledge-setup: WebSearch not in frontmatter allowed-tools"; errors=$((errors+1))
fi

# -----------------------------------------------------------------------------
# 3. knowledge-plan — charter inherited as grounding (fail-soft).
# -----------------------------------------------------------------------------
PLAN="$PLUGIN_ROOT/skills/knowledge-plan/SKILL.md"
if [ ! -f "$PLAN" ]; then
  red "FAIL: charter-19-skills-knowledge-plan-skill skills/knowledge-plan/SKILL.md not found"
  exit 1
fi
assert_grep 'charter' "$PLAN" "charter-20-step-0-4-reads-base knowledge-plan: Step 0.4 reads the base charter"
assert_grep 'get("charter"' "$PLAN" "charter-21-charter-read-get-fail knowledge-plan: charter read via .get (fail-soft, pre-0.1.4)"
assert_grep 'inherited grounding' "$PLAN" "charter-22-charter-injected-inherited-grounding knowledge-plan: charter injected as inherited grounding"

# -----------------------------------------------------------------------------
# 4. knowledge-resume / knowledge-dashboard — charter surfaced read-only.
# -----------------------------------------------------------------------------
RESUME="$PLUGIN_ROOT/skills/knowledge-resume/SKILL.md"
DASH="$PLUGIN_ROOT/skills/knowledge-dashboard/SKILL.md"
assert_grep 'Charter' "$RESUME" "charter-23-surfaces-charter-line knowledge-resume: surfaces a Charter line"
assert_grep 'get("charter"' "$RESUME" "charter-24-knowledge-resume-reads-charter knowledge-resume: reads charter via .get (fail-soft)"
# Re-frame offer (#451): resume points at --reframe but stays read-only — the
# write (set-charter / init) must NOT live in resume.
assert_grep '\-\-reframe' "$RESUME" "charter-25-surfaces-reframe-re-steer knowledge-resume: surfaces the --reframe re-steer offer"
assert_not_grep 'knowledge-binding.py set-charter' "$RESUME" "charter-26-knowledge-resume-stays-read-only-never-calls-set knowledge-resume: stays read-only — never calls set-charter"
assert_not_grep 'knowledge-binding.py init' "$RESUME" "charter-27-knowledge-resume-stays-read-only-never-calls-init knowledge-resume: stays read-only — never calls init"
assert_grep 'Charter' "$DASH" "charter-28-surfaces-charter-line-overlay knowledge-dashboard: surfaces a Charter line in the overlay"
assert_grep 'get("charter"' "$DASH" "charter-29-knowledge-dashboard-reads-charter knowledge-dashboard: reads charter via .get (fail-soft)"

if [ $errors -eq 0 ]; then
  green ""
  green "ALL PASS"
  exit 0
else
  red "$errors test(s) failed"
  exit 1
fi

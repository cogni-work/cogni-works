# Plan: cogni-wiki #219 — auto-rebuilt `wiki/context_brief.md`

**Parent**: [#212](https://github.com/cogni-work/insight-wave/issues/212) Karpathy-pattern parity tracking issue.
**Sub-issue**: [#219](https://github.com/cogni-work/insight-wave/issues/219).
**Position**: next open Tier 2 item after the per-type-dirs work that landed in #218 (cogni-wiki v0.0.28).
**Target version**: cogni-wiki v0.0.29.
**Status**: PLAN ONLY — no code in this commit.

---

## 1. Goal

A `≤8k`-char `wiki/context_brief.md`, rebuilt at the end of every `wiki-ingest` run, becomes the single "first read" for a new Claude Code session. Stdlib-only, deterministic, zero LLM tokens. Inspired by ΩmegaWiki's `tools/research_wiki.py rebuild-context-brief`.

## 2. Brief contents (deterministic sections, in order)

1. **Header** — schema-version stamp, generation timestamp, total page count.
2. **Type counts** — one line per `_wikilib.PAGE_TYPE_DIRS` entry (e.g. `- concepts: 47`).
3. **Top entities / concepts** — top N pages by inbound backlink count (cheap pass over `iter_pages` + body scan, or fall back to alphabetical if backlink data isn't precomputed).
4. **Recent activity** — last 30 days of `wiki/log.md` lines, verbatim. Already nicely formatted by Step 7 of `wiki-ingest`: `## [YYYY-MM-DD] op | slug — title`.
5. **Open lints (top)** — read `.cogni-wiki/last_lint.json` if recent (≤24h); else skip. Render `data.errors[:10]` + `data.warnings[:10]` as `class | page | message`.
6. **Health snapshot** — invoke `health.py` once (cheap, zero-LLM): `errors`, `entries_count_drift`, `claim_drift_count`.
7. **Truncation marker** — if anywhere we'd cross 8000 chars, hard-truncate the *recent activity* section first, append `…(truncated)`. Type counts and open lints are constant-bounded; never truncate those.

## 3. Files to add / change

| File | Action | Notes |
|---|---|---|
| `cogni-wiki/skills/wiki-ingest/scripts/rebuild_context_brief.py` | **NEW** | Stdlib-only. CLI: `--wiki-root <path>`. Emits `{success, data: {path, bytes, sections}, error}` JSON on stdout. Atomic write via `tempfile.NamedTemporaryFile` + `os.replace`. **No `_wiki_lock` needed for the write** — `context_brief.md` has a single writer (this script). Acquire the lock only for the *read snapshot* of `index.md`/`log.md`/page bodies, drop it before writing. |
| `cogni-wiki/skills/wiki-ingest/scripts/_wikilib.py` | extend | Add `def atomic_write(path: Path, text: str) -> None` and `def emit_json(success, data=None, error=None) -> None`. Both are duplicated inline across scripts today; extracting them now keeps `rebuild_context_brief.py` tiny. Keep additive — do not refactor existing inlines in this PR. |
| `cogni-wiki/skills/wiki-ingest/SKILL.md` | edit | Insert a new step between current Step 8 (`config_bump`) and Step 9 (`report`): `Step 8.5 — rebuild context brief`. Run **once per dispatch** (after the source loop), not per source. A failure here must NOT roll back the ingest — log to `log.md` and continue to Step 9. |
| `cogni-wiki/skills/wiki-resume/SKILL.md` | edit | Insert pre-Step-1 instruction: "Step 0: read `<wiki-root>/wiki/context_brief.md` if present before status collection." Update prose template (lines ~75–115) to summarise from the brief when available. Bump the "As of v0.0.27..." line to v0.0.29. |
| `cogni-wiki/CLAUDE.md` | edit | Add a "v0.0.29 — context brief" subsection alongside existing version notes. |
| `cogni-wiki/.claude-plugin/plugin.json` | edit | `0.0.28` → `0.0.29`. |
| `cogni-wiki/tests/test_context_brief.sh` | **NEW** | Bash smoke modeled on `test_migrate_and_smoke.sh`. Assert: file exists post-ingest, `wc -c` ≤ 8192, contains expected section headers, `head -1` matches schema-version stamp, missing-file fallback in `wiki-resume` works. |

## 4. Out of scope

- No standalone `wiki-context-brief` skill. Manual rebuild hook is `wiki-ingest --rebuild-context-brief` (no other args) — defer until someone asks.
- No schema-version bump. Brief is additive; missing → `wiki-resume` falls back. `_wikilib.SCHEMA_VERSION_PER_TYPE_DIRS` stays at `0.0.5`.
- No LLM rewriting of the brief. The whole point is determinism + zero token cost.
- No new wiki-root `CLAUDE.md.template` for seeded wikis. (None exists today; `wiki-setup/references/` only has `SCHEMA.md.template` + `directory-layout.md`. Session-start nudge therefore lives entirely in `wiki-resume/SKILL.md`.)

## 5. Risks & decisions

### Lint cost on every ingest
Lint is currently the heaviest tokenful operation. Two options:
- **(a)** run `lint_wiki.py` inline at every ingest — simple, but slows every ingest noticeably and burns tokens.
- **(b)** read `.cogni-wiki/last_lint.json` if recent enough (e.g. ≤24h); else skip the open-lints section. `wiki-refresh` is the right place to refresh the lint cache.

**Recommendation: (b).** Keeps ingest fast, brief still useful. Section header reads `## Open lints (cached YYYY-MM-DD)` or `## Open lints (stale — run wiki-refresh)`. **Confirm before coding.**

### 8k cap policy
Truncate "recent activity" section first (longest, least essential). Never truncate type counts or open lints — both constant-bounded. Hard cap, not soft cap (per the issue's explicit guidance against soft caps that defeat the purpose).

### Concurrency
`context_brief.md` has one writer (this script) — no inter-skill contention. But mid-rebuild a concurrent skill could be writing `log.md` or `index.md`. Acquire `_wiki_lock` for the read-snapshot phase, drop, then write. Cheaper than holding the lock through subprocess calls to `health.py`.

### Failure isolation
Brief rebuild failures must not roll back the ingest. Catch all exceptions in the Step 8.5 invocation; log a one-liner to `wiki/log.md` (`## [YYYY-MM-DD] context-brief | rebuild failed: <reason>`); continue to Step 9 report.

## 6. Acceptance

- After `wiki-ingest`, `wiki/context_brief.md` exists, ≤ 8192 bytes, reflects current state.
- A fresh session can answer "what's in this wiki" from the brief alone.
- Brief absent ⇒ `wiki-resume` degrades cleanly to current behaviour.
- New bash test in `cogni-wiki/tests/` asserts presence + size + schema header + fallback path.
- Plugin version bumped to `0.0.29`; `cogni-wiki/CLAUDE.md` has a v0.0.29 entry.

## 7. Suggested PR shape

Single PR titled `cogni-wiki: auto-rebuilt context_brief.md (#219)`, scoped to:

1. New `rebuild_context_brief.py` + helpers in `_wikilib.py` (additive only).
2. SKILL.md edits to `wiki-ingest` (new Step 8.5) and `wiki-resume` (new Step 0).
3. `plugin.json` 0.0.28 → 0.0.29 and `CLAUDE.md` version note.
4. New bash test + tiny fixture extension if needed.

## 8. Open questions to resolve before coding

1. **Lint inline vs cached**: confirm Option (b) above (cached `.cogni-wiki/last_lint.json` with staleness marker). Default to (b) absent objection.
2. **Top-N count for entities/concepts**: 10? 20? Suggest 10 to keep tail headroom under 8k.
3. **Recent-activity window**: issue says "~30 days". Make it a constant `RECENT_DAYS = 30` at top of script for easy tuning. No CLI flag.
4. **`open_questions.md` (Tier 2 sibling, #220)**: issue calls out picking a consistent pattern. Defer that decision to #220's PR — both files are auto-derived at end-of-ingest, both unlocked single-writer; the patterns will line up naturally.

## 9. References

- Parent tracker: cogni-work/insight-wave#212.
- Sub-issue: cogni-work/insight-wave#219.
- Survey anchors:
  - `cogni-wiki/.claude-plugin/plugin.json` (line 3 — version bump site).
  - `cogni-wiki/skills/wiki-ingest/SKILL.md` (Steps 0–9; insertion site is between current 8 and 9).
  - `cogni-wiki/skills/wiki-ingest/scripts/_wikilib.py` (lines 38, 63, 175, 195 — `PAGE_TYPE_DIRS`, `_wiki_lock`, `iter_pages`, `build_slug_index`).
  - `cogni-wiki/skills/wiki-lint/scripts/lint_wiki.py` (subprocess source; JSON contract `{success, data: {errors, warnings, info, stats}, error}`).
  - `cogni-wiki/skills/wiki-health/scripts/health.py` (subprocess source; already invoked by `wiki-resume/scripts/wiki_status.sh` — proven pattern).
  - `cogni-wiki/skills/wiki-resume/SKILL.md` (Step 1 around line 50; Golden Rules ~145).
  - `cogni-wiki/tests/test_migrate_and_smoke.sh` + `cogni-wiki/tests/fixtures/legacy-wiki/` (test pattern + fixture).
- Inspiration: ΩmegaWiki `tools/research_wiki.py rebuild-context-brief`.

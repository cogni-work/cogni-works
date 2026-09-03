# cogni-knowledge tests

Stdlib-only smoke tests for cogni-knowledge primitives. Bash 3.2 + python3
stdlib, no pytest, no pip dependencies — matches the convention used by
`cogni-wiki/tests/`.

## Layout

```
tests/
├── README.md
├── fixtures/                              Shared test fixtures
│   └── redundant-marker-386/              Agent-driven (not bash-CI) acceptance
│                                          fixture for the #386 redundant-marker
│                                          drop — see its README to re-run the
│                                          revisor + wiki-verifier by hand
├── test_knowledge_setup_probe.sh          F1 + A4: probe handles dev-repo
│                                          and marketplace cache layouts,
│                                          present in every gating knowledge-*
│                                          skill (cogni-wiki-only after M11)
├── test_binding_project_path.sh           A2: project_path field + schema
│                                          0.0.2; legacy 0.0.1 compat
└── test_cycle_guard_*.sh                  A3: 6 fixture-driven scenarios
    (direct, transitive, depth_bound,      against scripts/cycle-guard.py
     clear, dry_run, not_applicable)
```

## Run

```sh
for t in tests/test_*.sh; do bash "$t" || exit 1; done
```

Each test creates its own tempdir, sets up the fixture in isolation, runs
the script under test, asserts the documented output shape, and cleans up
via `trap rm -rf "$WORK" EXIT`.

## Convention

- bash 3.2 + python3 stdlib only (no pytest, no pip).
- `set -eu` at the top; exit non-zero on any failure.
- Source `fixtures/test_helpers.sh` for `red`/`green` rather than inlining
  them, so a `PASS:`/`FAIL:` label stays machine-parsable — plain, never
  wrapped in an escape sequence and never chosen by an environment probe.
  `test_plain_result_emitters.sh` holds this shape.
- `assert_grep <pattern> <file> <description>` for contract-level SKILL.md
  checks. `assert_not_grep <pattern> <file> <description>` is its inverted
  counterpart — same three arguments, but it fails when the pattern IS
  present.
- `assert_grep_f` / `assert_not_grep_f` are the fixed-string (`grep -qF`)
  counterparts. Reach for them whenever the pattern is a literal carrying
  `[`, `]`, `.` or `*` — a wikilink, a glob, a path. `assert_grep` reads such
  a pattern as a regex, so it can report green against a file that does not
  contain the string at all.
- `check_grade_census <file>` censuses the two-part check/grade convention in
  `<file>` — every `check("<tag>", ...)` registration paired with exactly one
  `grade <tag>` line — and returns a verdict string on stdout: `PASS`, or a
  diagnostic naming the offending tag(s). Pass the caller's own `"$0"`. It
  emits no label and increments no `errors`, so the calling suite spells its
  own case id **literally in both arms** and folds the verdict into `errors`
  itself. That is what keeps the case addressable: `fixtures/` is one path
  segment out of reach of `scripts/check-case-id-pairing.py`, and an id that
  is entirely an expansion is skipped by it, so an arm emitted from the helper
  — or one whose id arrives only via `$census_desc` — is invisible to the
  guard. Every suite that uses the convention must call it — that rule is not
  a list kept here: `test_check_grade_enrolment.sh` derives the caller set from
  file content (a registration plus a grade line) and names any suite that
  carries both and does not call the helper.
- Real Python harness (inline `python3 - <<PY ... PY` heredoc) for
  script-level assertions.
- Fixtures are minimal — only the files the test actually exercises.

## Case ids on result lines

The plain `PASS:`/`FAIL:` label above is what keeps a result line *parsable*.
What makes one *addressable* is the token after it.

The **case id is the first whitespace-delimited token following the label** —
not the first token of the line. In `PASS: binding-path-03 init bootstraps
fetch-cache/ directory` the id is `binding-path-03`, and that is what
`mutation-check.sh --case <id>` points at when it checks that a guard actually
fires. That harness ships with the cogni-service managed-service tooling and
lives outside this repo; the
same-named `cogni-portfolio/scripts/mutation-check.sh` and
`cogni-consult/scripts/mutation-check.sh` are different, bespoke scripts and are
not this harness.

Seven rules follow from how it matches:

1. **An id is unique within its suite.** Two cases sharing one id cannot be told
   apart, so neither is addressable.

2. **Extend a stem with a hyphenated discriminator; never re-use a bare stem.**
   `test_binding_project_path.sh` used to show the defect — three cases opened
   with the bare stem `init`, and it also collided two-way on `append-project`
   and on `legacy`, a class rather than a one-off:

   ```
   PASS: init writes schema_version 0.1.5
   PASS: init bootstraps fetch-cache/ directory
   PASS: init writes curator_defaults; omits derivable/unused fields
   ```

   No `--case init` addressed any one of them. It now ships as:

   ```
   PASS: binding-path-02 init writes schema_version 0.1.5
   PASS: binding-path-03 init bootstraps fetch-cache/ directory
   PASS: binding-path-04 init writes curator_defaults; omits derivable/unused fields
   ```

   Each is reachable, and the shared `binding-path` stem still groups them by
   eye. Note the id is `<suite-slug>-<NN>`, not a bare descriptive stem like
   `init-fetch-cache`: the recorded scheme in `cogni-knowledge/CLAUDE.md` keys
   the stem to the *suite* so two suites can never claim the same one.

3. **`NN` is an allocation counter, not a position.** Ids happen to run in
   source order today because each suite was converted in one pass. When you add
   a case, take the next unused number for that suite and leave every existing
   id alone — never renumber to keep the sequence contiguous. A renumber
   silently repoints every later id at a different case, so a `--case` recorded
   in an older PR body re-runs against a guard it was never written for and
   still reports green. Running the suite cannot detect this: uniqueness still
   holds. Gaps are expected and harmless.

4. **No trailing colon on an id, and nothing before the label.** The id is
   right-anchored on whitespace-or-end-of-line, so a colon glued to it makes the
   token `binding-path-03:`, and a recipe passing `--case binding-path-03`
   gets `case_not_found` with no hint why. Only whitespace may precede the
   label — the same reason the plain-emitter rule above exists.

5. **Both arms of one case carry the same id.** The discriminator belongs in the
   id, never only in the human-readable message:

   ```sh
   green "PASS: binding-path-03 bootstraps the fetch-cache/ directory"
   red   "FAIL: binding-path-03 bootstraps the fetch-cache/ directory"
   ```

   Breaking this is worse than it looks. `test_binding_project_path.sh` used to
   pair `PASS: init writes schema_version 0.1.5` with `FAIL: schema_version
   expected 0.1.5, got ...` — different ids on the two arms. Under `--case init`
   a genuine failure did not even report `case_not_found`: the two *other*
   `PASS: init` lines still matched the green pattern, so the run read a real red
   as **green** and the check silently proved nothing. Both arms now carry
   `binding-path-02`, so the red is addressable. Only the *id* has to match —
   each arm keeps its own prose, so the fail arm still reports what it got.

6. **Verify uniqueness by running the suite — never by grepping call sites.** An
   id is routinely built from a variable or emitted inside a loop, so the source
   is not a census of what gets printed. Run it and group what came out:

   ```sh
   bash tests/test_binding_project_path.sh 2>&1 \
     | awk '/^[ \t]*(PASS|ok|FAIL):[ \t]/ {print $2}' | sort | uniq -d
   ```

   Empty output is clean; anything printed is a collision. One limitation: a
   passing run emits only the green arms, so this census sees only half the
   picture. Pairing the red arms is no longer a hand-read —
   `scripts/check-case-id-pairing.py` (rule 7) does it mechanically. Uniqueness
   still needs the run above: two cases sharing one id is not statically
   decidable, and the pairing guard makes no claim about it.

7. **Both arms of a case must be reachable, and each is gated only on that
   case's own predicate.** Rule 5 gives the two arms one id; this one keeps both
   of them printable. An arm the case's own predicate cannot reach is
   addressable in name only — `--case <id>` reports `case_not_found` instead of
   a verdict, and the guard it was meant to check proves nothing. Three shapes
   recur here. The plainest is a fail-only check with no `else`, which can never
   print green. The second chains a case onto a *different* case's condition
   with `elif`, so the branch is evaluated only when that earlier condition took
   the other path, and the state satisfying both prints neither arm. The third
   gates a PASS on a suite-wide accumulator such as the shared `errors` counter,
   which unrelated earlier checks increment — any one of them silences this
   case. For a multi-file scan, collect then pair: accumulate offenders into one
   variable during the loop, then gate a single same-id `if`/`else` on that
   variable after the loop closes (`plain-emit-03` in
   `test_plain_result_emitters.sh` is the resident model). The one legitimate
   single arm is a preflight guard with no green state worth reporting — a
   not-found check that aborts, where execution does not continue so a PASS
   could never print. Aborting alone does not earn the exemption: a preflight
   whose subject can legitimately be intact still owes a PASS twin, as `klib-01`
   in `test_knowledge_lib.sh` shows, pairing one with a fatal `exit`.

   Reachability is invisible in a green run: only the arms that fired appear.
   Force each branch — a fixture, or an argument-driven scan root that makes the
   red arm fire — or point `mutation-check.sh --case <id>` at it and let the
   reverted guard do the forcing.

   This rule is now enforced mechanically. `scripts/check-case-id-pairing.py`
   (CI job "Case-id pairing guard") flags a `FAIL: <id>` emission with no
   reachable same-id green arm in the same file, across `tests/*.sh` and
   `*/tests/*.sh`. Two things about it are worth knowing before you read a
   finding. Its **exemption keys on scope, not on abort**: a fail-only arm is
   exempt only when it aborts *and* sits at script scope, so the aborting
   preflight described just above stays exempt while the same shape inside a
   loop or a function is a finding. That is deliberately weaker than this
   rule's own qualification — the straight-line aborting preflights that ship
   today (counted on every run as `script_scope_aborts_exempt`) would all
   become findings under a stricter reading, so whether this rule's sentence
   should narrow or those preflights should gain twins is an open question,
   not something the guard settled. And its detection has a
   **stated recall floor** — out-of-glob sourced helpers such as
   `fixtures/test_helpers.sh`, ids that are entirely an expansion, heredoc
   bodies, and labels not in command position are all knowingly out of reach.
   The guard's module docstring is the single source for both; this rule points
   at it rather than restating it.

How the harness classifies a line, precisely: it matches the id as a **whole
token** (so `--case P1` never matches a `P10` line), keys red on a `FAIL:` line
and green on an `ok:` or `PASS:` line, and lets a red line win over a stray
green. Matching neither is reported as `case_not_found` rather than guessed at.
It reads output **lines**, never the suite's exit status — a suite exits
non-zero when *any* case is red, which cannot say which one.

These rules are about addressability alone; they hold whatever id vocabulary a
suite adopts.

## Contract tests (SKILL.md)

For pure LLM skills, regression coverage is **SKILL.md content invariants**
— grep-based assertions that catch the most likely failure mode (a path,
flag, or step silently disappears from the contract). These do not assert
LLM-driven behaviour, only that the contract surface remains intact.

`test_skill_contracts.sh` also carries the **M11 audit-grep**: a permanent
invariant that `skills/`, `scripts/`, and `agents/` contain zero references to
the archived `knowledge-research` / `knowledge-report` chain. It fails any PR
that re-introduces the legacy chain into the live runtime surface. (The
archived chain itself lives under `_archive/`, outside the live test glob.)

Phase 4.5 (`knowledge-distill`, #336) is covered by two files: `test_concept_store.sh`
exercises the actual `concept-store.py` (create / cross-run compounding / claim-id
namespacing / byte-stable re-run / foundation + no-sentinel skips), and
`test_distill_contract.sh` is the grep-based SKILL.md + agent contract guard.
`test_knowledge_lib.sh` covers the lifted tokenization primitives + `norm_key` /
`claim_similarity` / `parse_concept_records`.

Phase 4 Step 4.5 (`knowledge-ingest` per-sub-question nodes, #407) is covered by
`test_question_store.sh`, which executes the actual `question-store.py emit` against a
synthetic wiki + plan/candidates/manifest fixtures: one `wiki/questions/<slug>.md` per
sub-question with ≥1 finding, transliterated `theme_label` slug, zero-finding skip,
idempotent merge preserving the human `## Notes` tail, cross-type `-q` disambiguation,
and the legacy-plan `sq-NN` slug fallback.

## Maintenance note

Grep patterns assert exact layout (e.g. ``| `--bare` | No |`` for parameter
tables). Cosmetic reformats — column swap, extra column, switching from
`|`-pipe tables to a different structure — will trip these tests even when
the underlying contract is unchanged. When reformatting any covered
SKILL.md, update the patterns in the matching test script.

These suites are CI-enforced: the `Plugin test suites (discover and run
tests/*.sh)` job runs `scripts/run-plugin-tests.py`, which discovers every
`cogni-knowledge/tests/*.sh` suite and fails the build on a non-zero exit.
Run them yourself before a PR with `python3 scripts/run-plugin-tests.py
--filter knowledge`.

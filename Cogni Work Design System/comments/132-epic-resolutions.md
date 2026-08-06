# Phase 2 Resolutions — Open Questions Closed

Resolutions for the seven open questions logged in this epic body. These unblock #125 (manifest schema, load-bearing) and downstream children.

---

## Q1. Token format — JSON canonical, CSS generated

**Resolved.** ✅ JSON is the canonical, machine-readable source of truth. `tokens/tokens.css` is a generated artifact emitted from `tokens/colors.json`, `typography.json`, `spacing.json`, `radii.json`, `shadows.json`, `motion.json`.

**Implementation note for #125:** add a build script to `cogni-workspace/scripts/` (Python, for consistency with the rest of the script directory) that regenerates `tokens.css` from the JSON sources. CI should fail the PR if generated CSS drifts from JSON. Authors edit JSON only; CSS is committed as a generated artifact for `@import` convenience.

---

## Q2. Component versioning — copy-on-use by default, flags reserved (not implemented in v1.0)

**Resolved.** ✅ Copy-on-use is the default for v1.0: components are read at render time and snapshotted into the downstream artifact. No live link to the source theme.

**Rationale:**
- Matches user mental model — a generated deck or landing page should look the same a month later, not silently change when the theme is refactored.
- Isolates blast radius — a theme component change cannot retroactively break existing artifacts.
- Production-aligned — most design-token systems work this way (snapshot at build time).

**Reserved for Phase 3 (do not implement in v1.0):**
- `"live": true` — manifest field for opt-in re-resolution at render time.
- `"live_within_session": true` — re-resolves only within a single in-progress generation (useful for theme-iteration workflows like previewing while editing).

**Action for #125:** document `live` as a reserved field in the manifest schema with a SHALL-NOT-be-set-in-v1.0 constraint. Reject manifests that include it. Reservation prevents the field from being co-opted for unrelated purposes before Phase 3 lands.

**Action for #129 (consumer refactor):** the component loader should always copy. No live-resolution code path in v1.0.

---

## Q3. Component format — HTML primary, JSX optional

**Resolved.** ✅ HTML is the canonical primitive format. JSX is permitted alongside but optional.

**Rationale:**
- HTML primitives are portable across non-React skills (PPTX renderers, DOCX renderers, static HTML generators, email templates).
- JSX is only consumable by React surfaces (`cogni-website`, future React app dashboards).
- Themes that produce only HTML outputs do not need to maintain JSX duplicates.

**Action for #125 (schema):** the `components` tier in the manifest declares per-namespace primitive sets:
```json
{
  "components": {
    "deck": "components/deck/",      // HTML files, .html extension
    "web": "components/web/",        // HTML or JSX, both extensions valid
    "dashboard": "components/dashboard/"
  }
}
```
Schema validates that any `.html` file under a components namespace is valid HTML5. Schema does not require `.jsx` counterparts.

**Action for #127 (cogni-work pilot):** ship HTML for `components/deck/` (slides). HTML + JSX for `components/web/` (since the design system project already has both).

---

## Q4. `themes/` directory naming — leave as-is

**Resolved.** ✅ Keep the directory called `themes/`.

**Rationale:** renaming touches every reference across `cogni-workspace`, every consuming skill, every doc, every internal user mental model — for zero capability gain. The directory's expanded scope (now containing tokens, components, assets, templates) is a documentation problem, not a naming problem.

---

## Q5. Voice/copy templates as own tier — defer to Phase 3

**Resolved.** ✅ Voice/copy templates do not get a tier in schema v1.0.

**Rationale:**
- Voice rules are already captured in `theme.md` (Phase 1, just landed) — sufficient for current consumers (`cogni-copywriting`, `cogni-narrative`, `cogni-sales`).
- Promoting copy templates ("CTA patterns," "BLUF templates," "section openers") to a structured tier is independent work that should not block schema v1.0.
- Phase 3 can add a `copy/` tier with its own schema once a concrete consumer (e.g. extended `cogni-copywriting`) actually needs structured copy templates.

**Action for #125:** schema v1.0 has no `copy` field. Document as "reserved for Phase 3" in the schema's free-form notes section.

---

## Q6. `insight-wave-pro` interaction — same picker, no carve-out

**Resolved.** ✅ `insight-wave-pro` consumes themes via the same `pick-theme` skill. No private/pro-specific theme contract.

**Rationale:**
- `pick-theme` already merges `$CLAUDE_PLUGIN_ROOT/themes/` (standard) + `$COGNI_WORKSPACE_ROOT/themes/` (workspace). Pro plugins use the same picker.
- Tier-1+ capabilities benefit pro plugins for free — they consume tier-N tokens/components without any pro-specific code.
- No carve-out keeps the architecture clean and the marketplace ecosystem coherent.

---

## Q7. Pilot consumer substitution — `render-html-slides`, not `render-big-block`

**Resolved.** ✅ The pilot consumer for #129 is `cogni-visual:render-html-slides` (the RFC's `render-big-block` was an outside guess and does not exist).

**Rationale:**
- High-visibility consumer (slides are the most common themed output).
- Exercises tokens + components + templates simultaneously — full end-to-end demonstration of the tier model.
- A successful refactor here sets the pattern for other consumers.

---

## Theme migration scope — `cogni-work` only for v1.0

**Resolved.** ✅ Only `cogni-work` migrates to the tiered structure in Phase 2.

**Rationale:**
- `deutsche-telekom` and `telekom-tsc` exist in workspace contexts but **are not present in the `insight-wave` repo**. Migrating themes that don't ship with the plugin is a non-task.
- The `cogni-work` pilot proves the model. If user-workspace themes want to opt into tiered structure later, they migrate as separate workspace-side tasks — not blocking insight-wave releases.

**Action:** no migration tickets for `deutsche-telekom` or `telekom-tsc` get queued.

---

## Pilot scope clarification — standard `cogni-work`, not workspace copy

The `cogni-work` directory at `cogni-workspace/themes/cogni-work/` (standard, ships with the plugin) is the migration target for #127. The picker's workspace-override behavior means:

- Migrating the **standard** copy benefits every install.
- Workspace copies of `cogni-work`, if any exist, continue to override per existing behavior — they're either tier-0 (work as today) or get migrated by their owners independently.

This is a strict capability addition for every install with zero migration cost imposed on users.

---

## Next step

#125 (manifest schema) is now unblocked on all schema-affecting resolutions (Q1, Q2, Q3, Q5). It can proceed.

#129 (consumer refactor) is unblocked on Q2 (copy-on-use, no live-resolution code path) and Q7 (target = `render-html-slides`).

Run `/cogni-service:service-resume` to let the pipeline pick up #125.

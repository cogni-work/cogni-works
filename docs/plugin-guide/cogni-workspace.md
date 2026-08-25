# cogni-workspace

**Plugin guide** — for canonical positioning see the [cogni-workspace README](../../cogni-workspace/README.md).

---

## Overview

cogni-workspace is the horizontal layer of the insight-wave ecosystem — it owns the shared workspace state that the vertical business plugins consume. Before any other cogni-x plugin can run reliably, it needs: a place to find the workspace root, environment variables pointing to shared resources, a theme directory, and knowledge of which other plugins are installed. cogni-workspace provides all of this through a single initialization command and a set of management skills.

In practice, most users interact with cogni-workspace twice: once when setting up a new workspace (`manage-workspace`), and occasionally when something drifts out of sync (`workspace-status`, `manage-workspace`). Theme management and Obsidian integration are optional — use them if you want visual consistency across plugin outputs or a terminal-integrated note-taking environment.

The plugin imposes no data model on the workspace. It writes four files during initialization — `.workspace-config.json`, `.workspace-env.sh`, `.claude/settings.local.json`, and output style templates — and then stays out of the way.

---

## Key Concepts

| Term | What it means |
|------|--------------|
| **Workspace** | A project directory initialized with cogni-workspace — has `.workspace-config.json` and the shared env file |
| **Plugin discovery** | The process of scanning the marketplace cache for installed cogni-x plugins and registering them in the workspace config |
| **Theme** | A markdown file containing color palettes, typography, and design principles, stored in `cogni-workspace/themes/` |
| **Theme picker** | The `pick-theme` skill — the single entry point for theme selection used by all visual plugins |
| **Output style** | A language-specific behavioral anchor file (EN/DE) that shapes how plugin outputs are formatted |
| **Session hook** | `on-session-start.sh` — sources the workspace environment and validates plugin availability each time a session opens |
| **Five-tier diagnostic** | The structure of `workspace-status` output: foundation → env vars → plugin registry → themes → dependencies |
| **Obsidian vault** | A `.obsidian/` configuration directory scaffolded by `manage-workspace` during initialization |
| **Claim** | A sourced assertion tracked for verification — carries the asserted text, its `source_url`, and `entity_ref` provenance pointing back to the plugin entity it came from |
| **Deviation** | A detected mismatch between a claim and what its cited source actually says, held for the user to review and resolve |

### Prerequisites

Before running `manage-workspace`, ensure these tools are installed:

| Dependency | Required | Purpose |
|-----------|----------|---------|
| `jq` | Yes | JSON processing in scripts |
| `python3` | Yes | Standard library only — no pip required |
| `bash 3.2+` | Yes | Script runtime |
| `curl` | Optional | Source fetching in some skills |
| `git` | Optional | Version tracking |
| `bc` | Optional | Arithmetic in diagnostic scripts |

---

## Getting Started

Initialize a new workspace:

```
Initialize a insight-wave workspace here
```

or:

```
/manage-workspace
```

What the initialization does:

1. Runs `check-dependencies.sh` and reports any missing required tools
2. Asks for your output language preference (English and German are common defaults; 16+ languages are supported — see [Supported markets & languages](../../cogni-workspace/README.md#supported-markets--languages)) and which tool integrations to enable
3. Discovers installed cogni-x plugins via `discover-plugins.sh`
4. Generates `.workspace-config.json` with plugin registry and metadata
5. Generates `.workspace-env.sh` with environment variables for each plugin
6. Generates `.claude/settings.local.json` with workspace-appropriate settings
7. Writes output style templates for EN and DE
8. Creates the `cogni-workspace/themes/` directory and installs the bundled `cogni-work` theme

After initialization, your workspace root contains:

```
.workspace-config.json     workspace metadata, plugin registry, language
.workspace-env.sh          environment variables sourced at session start
.claude/settings.local.json  Claude Code settings
cogni-workspace/themes/    shared theme storage
```

---

## Capabilities

### `manage-workspace` — Initialize or update a workspace

A single command that auto-detects whether to initialize or update. If no `.workspace-config.json` exists, it runs the full initialization flow (dependency checks, plugin discovery, preference gathering, settings generation). If one exists, it runs the update flow (backup, re-scan plugins, refresh env vars, update output styles) while preserving user customizations.

```
/manage-workspace
```

---

### `workspace-status` — Five-tier health diagnostic

Checks the workspace in five layers and reports findings with actionable fixes:

1. **Foundation** — are the required files present and well-formed?
2. **Environment variables** — does `.workspace-env.sh` define the variables plugins expect?
3. **Plugin registry** — are registered plugins still installed at their expected paths?
4. **Themes** — is at least one theme available for visual plugins?
5. **Dependencies** — are `jq`, `python3`, and bash at the required versions?

Run when something is not working and you are not sure whether it is a plugin issue or a workspace issue:

```
/workspace-status
```

```
What's the status of my workspace?
```

If the diagnostic finds issues, each finding comes with a specific fix. Infrastructure-level problems (env vars, settings) are workspace concerns; plugin-level problems (broken skills, missing references) are handled by cogni-workspace's own `troubleshoot` skill.

---

### `workspace-dashboard` — The workspace in a browser

Generates a self-contained HTML dashboard of the whole workspace configuration — installed plugins with their versions, resolved environment variables, registered themes, Obsidian integration state, and MCP server status — in one scrollable page. `workspace-status` answers "is anything broken?" on the terminal; this answers "what does my workspace actually look like?" in a form you can scan or hand to someone else.

```
/workspace-dashboard
```

### `manage-themes` — Theme extraction and management

Themes are markdown files that describe a visual identity — colors, typography, and design principles. Every rendering surface — this plugin's own `story-to-*` and `enrich-report` skills, cogni-website, and `document-skills` — reads from the same theme directory, so setting a theme here propagates to every plugin output.

Eight operations are available:

| Operation | What it does |
|-----------|-------------|
| `recommend` | Suggests themes based on your industry or audience description |
| `list` | Shows all available themes in the workspace |
| `grab from website` | Extracts colors and typography from a live URL using Chrome |
| `grab from PPTX` | Extracts a theme from an existing PowerPoint template |
| `create from preset` | Builds a theme from a named preset (e.g., corporate, minimal, vibrant) |
| `audit` | Checks a theme for contrast ratios, color harmony, and completeness |
| `generate showcase` | Renders a visual sample of how a theme looks applied to real content |
| `apply` | Registers a theme as the workspace default |

```
/manage-themes
```

```
Extract a theme from our company website and apply it to the workspace
```

The `grab from website` operation uses Chrome browser automation to read the live site — it captures computed styles, not just source HTML.

---

### `pick-theme` — Centralized theme picker

A thin coordination skill used internally by all visual plugins before generating output. When a skill needs a theme, it calls `pick-theme` rather than implementing its own discovery logic.

You can also call it directly when you want to choose a theme before starting a visual workflow:

```
/pick-theme
```

The skill scans both the plugin's bundled theme directory and your workspace themes directory, presents the available options, and returns the path to your selection.

---

### Obsidian Integration (via `manage-workspace`)

Obsidian vault setup and updates are handled as sub-steps of `manage-workspace`:

- **During initialization**: if you indicate Obsidian use, the skill scaffolds `.obsidian/` with a Terminal plugin, Tokyonight-themed terminal, and Claude Code launcher
- **During update**: if `.obsidian/` exists, the skill offers to refresh terminal profiles and launcher scripts without overwriting customizations, fixing common WSL issues

Prerequisites: Obsidian must be installed. The skill handles Terminal plugin installation automatically.

---

### `install-mcp` — MCP server installation

End-to-end MCP server installation for the ecosystem. Clones and builds git-based MCPs (Excalidraw, Pencil), detects native-app MCPs (browsermcp, claude-in-chrome), and writes the server into your own MCP config — `~/.claude.json` for Claude Code, `claude_desktop_config.json` for Claude Desktop — so rendering plugins find their tools without hand-edited JSON.

```
/install-mcp
```

Backs up the config before any write; rolls back in one command if an install breaks something. Usually invoked automatically by `manage-workspace` Step 5, but available standalone when you add a plugin that needs an MCP server.

---

### `ask` — Query the bundled insight-wave wiki

Answers questions about the insight-wave ecosystem — plugins, skills, agents, architecture, cross-cutting conventions — by reading the vendor-curated wiki bundled at `${CLAUDE_PLUGIN_ROOT}/wiki/`, not from model memory. Reads that bundled wiki directly so answers are grounded and cited with `[[wikilinks]]`; if the wiki has no page on the topic, the skill says so rather than guessing.

```
/ask how does claims propagation work across plugins?
/ask which plugin generates IS/DOES/MEANS messaging?
/ask what's the difference between the `narrative` skill and the `copywriter` skill?
```

First lookup before grepping source files — faster and doesn't pull plugin internals into your context.

---

### `cogni-issues` — File and track plugin issues on GitHub

Files bugs, feature requests, change requests and questions against any marketplace plugin through the authenticated GitHub CLI, and lists or inspects the issues already open. It deduplicates before filing — an incoming report is checked against open issues so the same defect does not get filed twice — and routes each issue to the repository that actually owns the named plugin.

```
/cogni-issues file a bug against cogni-portfolio: portfolio-scan drops the taxonomy
/cogni-issues list open issues for cogni-trends
```

Requires an authenticated `gh` CLI. Without it the skill reports the gap rather than failing silently.

---

### `manage-markets` and `audit-region-sources` — Canonical market registry

cogni-workspace owns the canonical market registry (`references/supported-markets-registry.json`) that every market-aware plugin reads through `scripts/get-market-config.py`. The full list of built-out markets, registered markets, and supported output languages lives in the [Supported markets & languages](../../cogni-workspace/README.md#supported-markets--languages) section of the cogni-workspace README — that is the single source of truth other plugin READMEs link to.

`manage-markets` is the write path: use it to check registry status or add new markets. `audit-region-sources` is read-only: it audits per-plugin region-source overlays against the registry to catch orphan domains and drift.

```
/manage-markets
/audit-region-sources
```

---

### `claims` — Verify sourced claims against their cited sources

Claim verification is a cogni-workspace capability, not a separate plugin. The `claims` skill takes assertions that other plugins produced with a citation, fetches each cited source, and reports where the claim and the source disagree. It never generates claims itself — cogni-trends, cogni-portfolio, and cogni-knowledge submit them; this skill checks them.

Determine the operating mode from intent rather than asking the user to name one:

| Mode | What triggers it | What it does |
|------|-----------------|--------------|
| `submit` | A user or plugin provides new claims with sources | Adds claims to the registry for tracking |
| `verify` | "verify", "check", "re-check", or first run after submission | Fetches sources and compares each claim against them |
| `dashboard` | "show", "status", "what claims need attention" | Displays all claims grouped by status |
| `inspect` | "inspect", "what's wrong with", "explain this deviation" + a claim ID | Deep-dives one claim's evidence |
| `resolve` | "resolve", "fix", "correct" + a claim ID | Walks the user through resolving a deviation |
| `cobrowse` | "cobrowse", "recover sources", "let's look together" | Interactive cobrowsing to recover `source_unavailable` claims |

`dashboard` is the safe default when intent is ambiguous.

```
/claims
```

Two agents do the work. `claim-verifier` runs one dispatch per unique source URL, fetching the source and detecting five deviation types — `misquotation`, `unsupported_conclusion`, `selective_omission`, `data_staleness`, and `source_contradiction` — with a severity per claim. `source-inspector` handles the cobrowse path, recovering claims whose source could not be fetched automatically.

Deviation detection is LLM-based, so findings are assessments for the user to review, not definitive judgments. The user always has the final say on how a deviation is handled.

---

### `claim-entity` — The claim data model

Claims move through a three-state lifecycle:

```
unverified ──> verified            (no deviations found)
unverified ──> deviated            (deviations detected)
unverified ──> source_unavailable  (source unreachable)
deviated   ──> resolved            (user resolves all deviations)
```

An unfetchable source yields `source_unavailable`, never `verified` — if a source cannot be read, the claim's accuracy is unknown, and recording it as verified would overstate what was checked.

The store lives under the working directory:

```
{working_dir}/cogni-claims/
├── claims.json          # Registry of all ClaimRecords
├── sources/{hash}.json  # Cached source content per URL
└── history/{id}.json    # Audit trail per claim
```

The directory keeps the name `cogni-claims/` because it holds accumulated per-project user state: renaming it would orphan every claim store already on disk. Read and write it under that name regardless of which plugin ships the skill.

### `narrative` — Shape content into an executive narrative

Absorbed from the retired cogni-narrative plugin. Takes structured input — research syntheses, portfolio entities, plain markdown — and writes `insight-summary.md`: an arc-driven executive narrative with YAML frontmatter carrying `arc_id`, `arc_display_name` and element metadata.

Eleven arc frameworks are available, each a fixed sequence of four named elements with defined rhetorical intent:

| Arc | Element flow | Best for |
|-----|--------------|----------|
| `corporate-visions` | Why Change → Why Now → Why You → Why Pay | Sales, B2B market research |
| `technology-futures` | Emerging → Converging → Possible → Required | Innovation, R&D, technology trends |
| `competitive-intelligence` | Landscape → Shifts → Positioning → Implications | Competitive analysis |
| `strategic-foresight` | Signals → Scenarios → Strategies → Decisions | Long-range planning |
| `industry-transformation` | Forces → Friction → Evolution → Leadership | Industry and regulatory analysis |
| `trend-panorama` | Forces → Impact → Horizons → Foundations | TIPS trend-scout output (theme-less) |
| `smarter-service` | Forces → Impact → Horizons → Foundations | TIPS reports with investment themes |
| `theme-thesis` | Why Change → Why Now → Why You → Why Pay | Investment theme narratives |
| `jtbd-portfolio` | Jobs → Friction → Portfolio → Invitation | Portfolio introductions, pre-sales |
| `company-credo` | Mission → Conviction → Credibility → Promise | About-Us pages |
| `engagement-model` | Principles → Process → Partnership → Outcomes | How-We-Work pages |

The skill analyses the input's structure and proposes a best-fit arc; `--arc {arc-id}` overrides it. Target length defaults to ~1,675 words, with section proportions preserved rather than sections cut.

`narrative-review` scores an existing narrative against the arc's quality gates across four dimensions — structural compliance, critical accuracy, evidence density, language — producing a 0–100 composite, an A–F grade, and the top three actionable fixes. `narrative-adapt` condenses a narrative into an executive brief, talking points, or a one-pager, condensing proportionally so the arc survives the reduction.

Commands: `/narrative`, `/narrative-review`, `/narrative-adapt`.

### `copywriter` — Polish documents for executive readability

Absorbed from the retired cogni-copywriting plugin. Applies seven messaging frameworks — BLUF, McKinsey Pyramid, SCQA, STAR, PSB, FAB, Inverted Pyramid — plus persuasion techniques (number plays, power words, rhetorical devices) to memos, briefs, reports, proposals, one-pagers and blog posts.

Two modes matter beyond ordinary polish:

- **Arc-aware preservation.** When the document carries an `arc_id` in frontmatter, the polish strengthens writing *within* each arc element without altering the skeleton — the title, subtitle, four elements in sequence, and bridge section stay intact. The arc contract it polishes against is mirrored in `skills/copywriter/references/09-preservation-modes/`, and `tests/test-arc-reference-sync.sh` keeps that mirror honest against `skills/narrative/`'s definitions.
- **Translate-then-polish.** A two-pass flow across seven languages (de/en/fr/it/pl/nl/es), every direction pivoting on English or German. Arc-element and bridge headings are *substituted* from the canonical set rather than freely translated, and only for the `corporate-visions` and `jtbd-portfolio` arcs.

`copy-reader` reviews a document through five parallel stakeholder personas and synthesises their feedback. `copy-json` is the adapter for structured data — it extracts text fields from a JSON file, polishes them through `copywriter`, and writes them back in place.

Commands: `/copywrite`, `/review-doc`.

### `story-to-slides` — Turn a narrative into a presentation brief

Absorbed from the retired cogni-visual plugin. Reads a narrative that already carries a story arc and re-architects its argument into slide-level messages: pyramid communication, one message per slide, assertion headlines, and speaker notes. The output is `presentation-brief.md`, written by default to `{source_dir}/cogni-visual/presentation-brief.md` and capped at `max_slides` (default 15), so a long narrative is consolidated rather than transcribed. The density rule is that the slide carries the anchor and the speaker notes carry the detail — content that exceeds a layout's physical capacity moves to the notes instead of being force-fit on the slide.

The skill *creates* the brief; it does not render PowerPoint. Rendering is a separate step it guides you to at the end: attach the brief and the theme file in a claude.ai chat with the Anthropic PPTX skill (currently the recommended path), or render inside Claude Code via the `document-skills:pptx` skill, which cogni-workspace's own `pptx` *agent* wraps. There is no `pptx` skill in this plugin. Briefs carry no color fields — the renderer reads the theme directly.

No slash command of its own — ask for a deck from a narrative, or invoke the skill by name.

### `render-html-slides` — Render a presentation brief as HTML slides

The no-PowerPoint rendering path for any `presentation-brief.md` that `story-to-slides` produced. Turns the brief into a **self-contained HTML deck** — one file, themed from the workspace theme, with keyboard navigation, a speaker-notes toggle, and Mermaid diagram support. After the first render it opens an interactive refinement loop: a text-only correction is edited straight into the HTML, while a structural change re-renders just the affected slide instead of the whole deck.

Reach for this instead of the PPTX path when the deck will be presented from a browser, shared as a single file, or iterated on quickly. The `html-slides` agent wraps the same skill for autonomous callers.

### `story-to-web` — Turn a narrative into a scrollable web brief

Absorbed from the retired cogni-visual plugin. Decomposes a narrative into a scroll-driven section architecture and writes `web-brief.md`, by default to `{source_dir}/cogni-visual/web-brief.md`: a selected visual style guide, one message per section, assertion headlines, scroll-optimized copy, image prompts, and a CTA proposal (`conversion_goal` defaults to `consultation`, `max_sections` to 10). Sections alternate light and dark so each message lands before the next begins.

As with `story-to-slides`, this is the briefing half only: the `web` agent renders the brief via Pencil MCP into a `.pen` file and then exports a self-contained HTML page from it, and the brief itself contains no color fields. It does not produce slides (`story-to-slides`), print storyboard posters (`story-to-storyboard`), or polished prose (`copywriter`).

No slash command of its own — ask for a web narrative or a landing page built from a narrative document.

### `story-to-infographic` — Distill a narrative into a single-page infographic

Absorbed from the retired cogni-visual plugin. Extracts the three to five most impactful data points from a narrative, selects a layout, and writes `infographic-brief.md` (default `{source_dir}/cogni-visual/infographic-brief.md`) with content blocks under strict word limits plus icon prompts. The brief routes to one of two rendering families, picked by `style_preset`:

- **Hand-drawn** — the `sketchnote` and `whiteboard` presets, rendered through `/render-infographic-handdrawn` into an `.excalidraw` scene.
- **Editorial** — the `economist`, `editorial`, `data-viz` and `corporate` presets, rendered through `/render-infographic-editorial` into a `.pen` file.

`/render-infographic` is the universal entry point: it reads the brief's `style_preset` and routes to the right family. Unlike the two skills above, this one renders by default — after writing the brief it auto-dispatches `/render-infographic` (pass `render: false` to produce the brief only). One constraint to respect: both hand-drawn render agents share a single Excalidraw MCP canvas, so hand-drawn renders must be serialized and never dispatched in parallel. Pencil-rendered editorial briefs are file-backed and can run alongside one Excalidraw render safely.

### `review-brief` — Stakeholder review of a visual brief before rendering

Reviews any brief the `story-to-*` skills produce — presentation, web, storyboard, or infographic — from three stakeholder perspectives: design quality, audience experience, and usability. Returns a structured verdict (accept / revise / reject) with prioritized improvements.

The point is where it sits in the pipeline: rendering is the expensive step, so catching a weak brief here costs one review instead of a full render-and-redo. Run it after a brief is generated, or after you have hand-edited one, before handing it to the PPTX, Excalidraw, or Pencil pipeline.

```
/review-brief
```

### `enrich-report` — Turn a finished report into a visual deliverable

Absorbed from the retired cogni-visual plugin. Post-processes an *already-written* markdown report into a self-contained themed HTML rendition — it never authors a new report from scratch, never creates slides, and never rewrites prose (that is `copywriter`). The layout follows the consulting-deliverable pattern: the report's executive summary, then a full-width editorial infographic distilled from the whole report, then the report body with sidebar navigation and sparse inline Chart.js charts and SVG concept diagrams. The infographic is where the data visualization concentrates; the body stays prose unless a visual genuinely aids a specific passage.

One run always produces both HTML layouts: a scroll version at `{source_dir}/output/{stem}-enriched.html` and a paginated flipbook alongside it as `{stem}-enriched-flipbook.html`. On request via `formats`, PDF is derived from that HTML while DOCX is converted from the original markdown to keep the document structure clean. The source markdown is never touched, and a validation gate enforces preservation — the HTML must retain at least 80% of the source word count, with H2 and citation counts matching.

Commands: `/enrich-report`.

---

## Integration Points

### Upstream — cogni-workspace requires no other plugin

cogni-workspace has no required plugin dependencies. Its scope is horizontal: the vertical business plugins consume the shared state it owns, while each keeps its own project lifecycle.

### Downstream — every visual and content plugin uses the workspace

| Plugin / skill | What it reads from the workspace |
|---------------|----------------------------------|
| All cogni-x plugins | `.workspace-env.sh` — sourced at session start via the hook |
| cogni-website | Themes via `pick-theme`; `design-variables.json` derived from the picked theme |
| document-skills | Themes via `pick-theme`; output style templates |
| cogni-consult | `discover-plugins.sh` results — to know which plugins are available for dispatch |

---

## Common Workflows

### Workflow 1: Set up a brand-new workspace

1. Install insight-wave plugins from the marketplace
2. Run `/manage-workspace` in your project directory — answer the language and integration questions
3. Run `/workspace-status` to confirm all five tiers are green
4. Run `/manage-themes` to extract your brand theme from your website or a PPTX template
5. Obsidian integration is offered during `/manage-workspace` if you indicate Obsidian use

Total time: 10–15 minutes. After this, all installed plugins can resolve themes, env vars, and plugin paths without additional configuration.

For an end-to-end onboarding example that wires workspace into a full project, see [../workflows/portfolio-to-website.md](../workflows/portfolio-to-website.md) or [../workflows/consulting-engagement.md](../workflows/consulting-engagement.md).

### Workflow 2: Diagnose why a plugin cannot find its theme

1. Run `/workspace-status` — check the themes tier specifically
2. If themes tier fails: run `/manage-themes list` to see what themes are registered
3. If the theme directory is empty: run `/manage-themes` and create or install a theme
4. If the theme directory exists but the plugin still cannot find it: check that the plugin is reading `$COGNI_WORKSPACE_ROOT/themes/` (the env var should be set by `.workspace-env.sh`)
5. If the env var is missing: run `/manage-workspace` to refresh environment variables

### Workflow 3: Update the workspace after moving the project directory

When you move a workspace to a different path, absolute paths stored in `.workspace-env.sh` and `.claude/settings.local.json` become stale:

1. Run `/manage-workspace` from the new path — it re-scans for installed plugins and regenerates env vars
2. Run `/workspace-status` to confirm the workspace resolves correctly at the new path
3. If you use Obsidian, `/manage-workspace` will offer to fix terminal launcher paths during the update (especially important on WSL)

---

## Troubleshooting

| Symptom | Likely cause | Fix |
|---------|-------------|-----|
| A plugin cannot find `.workspace-env.sh` | The session hook did not run, or the workspace was not initialized | Run `/workspace-status`; if the foundation tier fails, re-run `/manage-workspace` |
| `jq: command not found` in script output | `jq` is not installed | Install via your package manager: `brew install jq` (macOS), `apt install jq` (Debian/Ubuntu) |
| Themes directory exists but visual plugin uses wrong colors | Plugin is reading a stale theme path | Run `/pick-theme` to re-select the theme; the selection updates the workspace default |
| `workspace-status` passes but a plugin skill still fails | The failure is at plugin level, not workspace level | Run cogni-workspace's `/troubleshoot` for plugin-level diagnostics |
| Obsidian terminal profile shows a doubled path (WSL) | WSL path duplication in the profile arguments | Run `/manage-workspace` — the update flow fixes doubled paths and stale args |
| `/manage-workspace` succeeds but a newly installed plugin is not discovered | The plugin was installed after initialization | Run `/manage-workspace` to re-scan and register the new plugin |
| German umlaut characters break workspace initialization | Shell locale not set for UTF-8 | Set `LANG=de_DE.UTF-8` before running init; the script includes umlaut support from v0.2+ |

---

## Known Issues

**Chrome native messaging host conflict (KI-001):** When both Claude Desktop (Cowork) and Claude Code are installed, the `manage-themes` skill's live website theme extraction feature — which uses Chrome browser automation to capture computed styles from a URL — may not work. The Chrome extension connects to one native host and ignores the other, causing browser automation tools to silently vanish.

**Workaround:** Toggle native messaging host configs by renaming the `.json` file for the unused product in `~/Library/Application Support/Google/Chrome/NativeMessagingHosts/` and restarting Chrome. Alternatively, extract themes from a PPTX template or create one from a preset — these paths do not require browser automation. See the [Known Issues Registry](../../cogni-docs/references/known-issues.md) for detailed steps.

---

## Extending This Plugin

cogni-workspace is a contribution-friendly surface for infrastructure improvements:

- **New theme templates** — the `themes/_template/` directory defines the canonical theme format; new presets or industry templates are additive and safe
- **Platform support** — `bash/portability-utils.sh` handles macOS, Linux, WSL, and Git Bash; if you have a platform that behaves differently, extending portability-utils is the right place
- **New diagnostic checks** — the five-tier structure in `workspace-status` can be extended with additional checks; a check should return a clear finding and a specific fix action
- **New output style languages** — the `assets/output-styles/` directory currently has EN and DE; other languages follow the same format

See [CONTRIBUTING.md](../../cogni-workspace/CONTRIBUTING.md) for guidelines.

# cogni-workspace

> **Preview** (v0.x) — core skills defined but may change. Feedback welcome.

> **insight-wave readiness (Claude Code desktop)** — Claude Code desktop is the recommended interface for insight-wave today. Cowork is a secondary path and is not yet production-ready for insight-wave workflows because of context-window and Pencil-MCP fidelity gaps — see the [deployment guide](../docs/deployment-guide.md) for detail. This guidance will flip when those gaps close upstream.

The horizontal layer of the [insight-wave](https://claude.ai/cowork) ecosystem — it owns the shared workspace state that the vertical business plugins consume (environment variables, the plugin registry, theme storage, MCP and tool configuration, the supported-markets registry), and it is the one you initialize first.

## Why this exists

Every insight-wave plugin needs the same workspace state — environment variables, themes, MCP tools, knowledge of its sibling plugins. With no shared owner for that state, each plugin reinvents it, and the seams show up at the worst time:

| Problem | What happens | Impact |
|---------|-------------|--------|
| No shared config | Each plugin manages its own env vars and paths | The same path is defined three ways; one drifts and a skill reads the stale value |
| Theme fragmentation | Visual plugins each scan for themes independently | A slide deck and a dashboard render in different colors from the same project |
| Plugin drift | Nothing detects version mismatches or missing dependencies | A skill fails mid-run with a cryptic error instead of a clear "dependency missing" |
| Manual setup | Every new workspace is scaffolded by hand | 20+ minutes of boilerplate before the first real plugin runs |

The cost compounds with every plugin added and every workspace created: configuration work that should happen once is paid again and again, and the failures it causes surface as runtime errors no user can diagnose.

## What it is

cogni-workspace is the ecosystem's infrastructure-as-plugin layer: a dedicated plugin whose sole job is to own the shared state every other plugin consumes — environment variables, the plugin registry, theme storage, and tool configuration. Its scope is horizontal: it owns the workspace state and tooling that no single business plugin should own, while each vertical plugin keeps its own project lifecycle and domain work. It is also the home of the canonical supported-markets registry that every market-aware plugin reads. See `references/absorption-roadmap.md` for what belongs on each side of that line and the rationale behind each call.

## What it does

1. **Manage workspace** — initialize or update a workspace with auto-detection, dependency checks, plugin discovery, preference gathering, settings generation, backup and rollback → `references/supported-markets-registry.json` → doc-generate, doc-power, doc-hub, doc-readme-root, doc-audit
2. **Manage themes** — import a Claude Design bundle or create from presets; audit harmony and script-checked WCAG contrast; author tiered theme systems (tokens → assets → components → templates) per Theme System v2 (see [migration guide](docs/theme-system-v2-migration.md)); apply to downstream skills
3. **Pick themes** — centralized theme picker used by all visual plugins
4. **Discover plugins** — scan installed cogni-x plugins, detect versions, compute env var names
5. **Diagnose** workspace health — five-tier report (foundation, env vars, plugin registry, themes, dependencies)
6. **Install MCP servers** — clone and build git-based MCP servers, detect native app MCPs, and write the server into your own MCP config (`~/.claude.json` for Claude Code, `claude_desktop_config.json` for Claude Desktop) so rendering plugins find their tools without manual JSON editing
7. **Obsidian integration** — scaffold `.obsidian/` vault or incrementally update terminal profiles, handled as sub-steps of manage-workspace
8. **Bundled reference wiki** — a vendor-curated insight-wave reference wiki ships at `wiki/`; read it directly, starting from its `wiki/index.md`, for grounded pages on plugins, skills, agents, architecture and conventions, plus the command cheatsheet (`ecosystem-command-reference`), the plugin-selection guide (`ecosystem-plugin-selection`) and the workflow walkthroughs (`workflow-*`)
9. **File and track issues** — `cogni-issues` uses the authenticated GitHub CLI to consult, deduplicate, create, list, and inspect plugin issues with atomic labels
10. **Troubleshoot plugin failures** — `workspace-status`'s plugin-level tier diagnoses plugin integrity, cross-plugin dependencies, stale state, and common setup errors; reachable through `/troubleshoot`
11. **Verify claims against their cited sources** — `claims` runs the six-mode claim-verification lifecycle (submit, verify, dashboard, inspect, resolve, cobrowse) that cogni-trends, cogni-portfolio, cogni-consult and cogni-knowledge submit sourced assertions to; `claim-entity` is the cross-plugin data contract those plugins write against
12. **Shape content into an executive narrative** — `narrative` transforms structured input using one of 11 story arc frameworks and, with `--format`, condenses an existing narrative into executive briefs, talking points or one-pagers, and `narrative-review` scores the result against quality gates (0–100, A–F)
13. **Polish documents for executive readability** — `copywriter` applies seven messaging frameworks (BLUF, Pyramid, SCQA, STAR, PSB, FAB, Inverted Pyramid) with arc-aware preservation and EN/DE-pivot translation across seven languages; `copy-reader` runs parallel stakeholder personas over a document; `copy-json` polishes text fields inside JSON

## What it means for you

- **Set up a whole workspace in one command.** One `manage-workspace` run auto-detects mode, discovers plugins, and generates env vars, settings, themes, and output styles — replacing 20+ minutes of hand-scaffolding, and backing up first so a bad update rolls back in seconds.
- **Skip hand-editing MCP config entirely.** `install-mcp` clones, builds, and wires up git-based and native MCP servers and writes them into your own MCP config, for Claude Code or Claude Desktop — plugins find their tools without a single JSON edit.
- **Reskin everything from one file.** Slides, journey maps, web narratives, and dashboards across 5+ visual plugins inherit colors and fonts from one theme, so a rebrand is a single-file edit.
- **Catch drift before a skill breaks.** Five-tier health diagnostics surface missing deps and version mismatches as a clear report, not a cryptic mid-run failure.

## Supported markets & languages

cogni-workspace owns the **canonical market registry** (`references/supported-markets-registry.json`) that every market-aware plugin reads through `scripts/get-market-config.py`. The platform is **European-first and multilingual — not DACH-only.** This is the canonical statement other plugin READMEs link to.

**Built-out markets — bilingual research + curated authority sources.** Nine markets are wired end-to-end into the bilingual (local language + English) research and trend-discovery pipelines, each with curated institutional authority sources:

| Market | Language | Example authority sources |
|---|---|---|
| DACH / DE | German | Fraunhofer, Bitkom, VDMA, Destatis, Handelsblatt |
| FR | French | INRIA, CNRS, INSEE, Arcep, Les Echos |
| IT | Italian | CNR, ISTAT, AGCOM, Il Sole 24 Ore |
| ES | Spanish | CSIC, INE, CNMC, Expansión |
| NL | Dutch | TNO, CBS, ACM, FD |
| PL | Polish | PAN, GUS, UKE, Rzeczpospolita |
| UK · US | English | ONS, Ofcom · BLS, Census, NIST |

**Registered & pluggable markets — breadth.** Beyond the built-out set, **28 markets in total** are registered in the taxonomy and selectable per project: extended single-country (AT, CZ, SK, HU, RO, HR, GR, MK, MX, BR, CN, JP), composite regions (EU, Nordics, LATAM, NA, APAC, MEA), and Global. Many extended markets already carry registry authority domains; the composites and several extended markets are **registered and ready but not yet wired into the bilingual research/trends overlays** — they are the expansion frontier, not a built-out claim.

**Languages.** 16+ output languages with native UTF-8 encoding — German (ä/ö/ü/ß), French (é/è/ç), Italian (à/ò/ù), Polish (ą/ć/ę/ł/ż), Spanish (á/é/ñ), Dutch, Portuguese, Czech, Slovak, Hungarian, Romanian, Croatian, Greek, Macedonian, Chinese, Japanese, English — never ASCII substitutes — plus **bilingual (local + English) search** so research draws on local-language and international sources alike.

**Managing markets.** The registry is the single source of truth: add or update markets with `cogni-workspace:manage-markets`, and audit per-plugin source overlays for drift with `cogni-workspace:audit-region-sources`.

## Install

Install insight-wave via Claude Code desktop:

- **5-minute walkthrough** — [From Install to Infographic](../docs/workflows/install-to-infographic.md)
- **Full setup reference** — [Claude Code desktop](../docs/claude-code-desktop.md)
- **Enterprise / compliance setup** — [Deployment guide](../docs/deployment-guide.md)

This plugin is part of the [insight-wave ecosystem](../docs/ecosystem-overview.md).

## Quick start

```
/manage-workspace  # initialize or update a workspace
/workspace-status  # check health
/pick-theme        # select a theme interactively
/manage-themes     # import, create, audit, or apply themes
/troubleshoot      # diagnose plugin and cross-plugin failures
/cogni-workspace:cogni-issues  # file or inspect GitHub issues
```

Or describe what you want:

- "Initialize a insight-wave workspace here"
- "What's the status of my workspace?"
- "Import the theme from this Claude Design bundle"
- "Update my workspace after installing new plugins"
- "Read the bundled wiki index at `wiki/index.md` and tell me which plugin generates IS/DOES/MEANS messaging"

## Try it

Initialize a workspace in the directory where your cogni-x plugins live:

> Run `/cogni-workspace:manage-workspace`

Claude checks dependencies, discovers your installed plugins, and asks for your output language and tool integrations. It then writes the workspace into the current directory:

```
.claude/settings.local.json   # env vars + plugin registry
.workspace-env.sh             # sourced by the session-start hook
.workspace-config.json        # discovered plugins, preferences
.claude/output-styles/        # language-specific behavioral anchors
themes/                       # default cogni-work theme
```

Then confirm everything is wired up:

> Run `/cogni-workspace:workspace-status`

You'll get a five-tier report — foundation, env vars, plugin registry, themes, dependencies — each marked OK or flagged, with a clear pointer to the fix when something is off. From here every cogni-x plugin reads its configuration from the workspace instead of asking you to set it up again. Re-run `manage-workspace` any time you install a new plugin and it updates the registry in place, so the rest of the ecosystem stays wired up without touching a single config file by hand.

## How it works

cogni-workspace runs as the first link in every ecosystem session. The session-start hook (`on-session-start.sh`) sources `.workspace-env.sh` and validates plugin availability before any other skill runs, so downstream plugins always open against a known-good environment rather than discovering a missing variable mid-task.

Setup itself is a single ordered pass. `manage-workspace` runs `check-dependencies.sh` first (you can't configure tools that aren't installed), then `discover-plugins.sh` scans the marketplace cache to learn which cogni-x plugins are present and what env var names they expect. With the inventory known, `generate-settings.sh` writes the settings files, `install-mcp` clones and wires any MCP servers the discovered plugins need, and the Obsidian and theme steps follow. Each step backs up before it writes, so an interrupted or bad run is recoverable.

State lives in two layers that other plugins consume. Configuration (env vars, the plugin registry, themes) is read at runtime — `pick-theme` is the single entry point visual plugins call for theme paths, and `get-market-config.py` merges the canonical supported-markets registry with each plugin's overlay so market data is never duplicated. Health is verified on demand: `workspace-status` re-runs the five-tier check (foundation, env vars, plugin registry, themes, dependencies) so drift is located before a skill trips over it, not after. The ordering throughout is deliberate — discover before configure, configure before wire, back up before write.

## Components

| Component | Type | What it does |
|-----------|------|--------------|
| `manage-workspace` | skill | Initialize or update workspace — auto-detects mode, dependencies, discovery, preferences, settings, themes, backup and rollback |
| `manage-themes` | skill | 8 theme operations: recommend, list, create from preset, audit (script-checked WCAG contrast), author deep theme system, generate showcase, apply, import from Claude Design bundle |
| `pick-theme` | skill | Centralized theme picker — discovers themes, presents interactive selection, returns path |
| `workspace-status` | skill | Five-tier diagnostic: foundation, env vars, plugin registry, themes, dependencies |
| `install-mcp` | skill | End-to-end MCP server installation — clone and build git-based MCPs, configure native app MCPs, and write the server into the user's own config (`~/.claude.json` or `claude_desktop_config.json`) |
| `manage-markets` | skill | Write path for the canonical supported-markets registry — show status and add markets (codes, locales, authorities) |
| `audit-region-sources` | skill | Read-only sibling of manage-markets — audit per-plugin region-source overlays against the canonical registry for orphans and drift |
| `workspace-dashboard` | skill | Interactive HTML dashboard of workspace foundation, env vars, plugin registry, themes, and dependencies |
| `cogni-issues` | skill | File, deduplicate, list, and inspect plugin issues through the authenticated GitHub CLI |
| `claims` | skill | Six-mode claim-verification lifecycle — submit, verify, dashboard, inspect, resolve, cobrowse |
| `claim-entity` | skill | Cross-plugin ClaimEntity data contract — record shapes, claim types, severity levels, on-disk `cogni-claims/` store layout |
| `claim-verifier` | agent | Fetches one source URL and verifies every claim against it, returning deviation analysis as strict JSON |
| `source-inspector` | agent | Opens a source URL via claude-in-chrome and walks the user to the relevant passage (cobrowse / inspect) |
| `narrative` | skill | Transform structured input into an executive narrative using one of 11 story arc frameworks; with `--format`, condense one into an executive brief, talking points or a one-pager |
| `narrative-review` | skill | Score a narrative against story-arc quality gates — 0–100 composite with an A–F grade and the top 3 fixes |
| `copywriter` | skill | Polish, rewrite or create business documents with 7 messaging frameworks, arc-aware preservation, and EN/DE-pivot translation |
| `copy-reader` | skill | Review a document through parallel stakeholder persona Q&A, then synthesize the feedback |
| `copy-json` | skill | Adapter that polishes text fields inside JSON — extracts, polishes via `copywriter`, writes back |
| `narrative-writer` | agent | Parallel narrative generation across content sets |
| `narrative-reviewer` | agent | Quality-gate scoring and scorecard generation |
| `narrative-adapter` | agent | Parallel format adaptation across narratives |
| `copywriter` | agent | Delegation wrapper for the `copywriter` skill |
| `reader` | agent | Delegation wrapper for the `copy-reader` skill |
| `commands/claims.md` | command | Registers `/claims` as the entry point to the verification lifecycle |
| `commands/narrative.md` | command | Registers `/narrative`, with `/narrative-review` and `/narrative-adapt` alongside it |
| `commands/copywrite.md` | command | Registers `/copywrite`, with `/review-doc` alongside it |
| `commands/render-infographic.md` | command | Registers `/render-infographic`, the style-agnostic renderer entry point that auto-routes on the brief's `style_preset` |
| `commands/render-infographic-handdrawn.md` | command | Registers `/render-infographic-handdrawn` for direct sketchnote / whiteboard dispatch |
| `commands/render-infographic-editorial.md` | command | Registers `/render-infographic-editorial` for direct Pencil-backed editorial dispatch |
| `commands/render-html-slides.md` | command | Registers `/render-html-slides` — presentation brief to self-contained HTML slides |
| `commands/enrich-report.md` | command | Registers `/enrich-report` — markdown report to themed HTML with charts and diagrams |
| `commands/review-brief.md` | command | Registers `/review-brief` — stakeholder scoring of a visual brief before rendering |
| `commands/troubleshoot.md` | command | Registers `/troubleshoot` as the diagnostic entry point |
| `claims-store.sh` | script | JSON state manager for the claim store, shipped with the `claims` skill (`skills/claims/scripts/`) |
| `on-session-start.sh` | hook (SessionStart) | Sources workspace environment and validates plugin availability at session start |
| `on-session-start-language.sh` | hook (SessionStart) | Injects the language rules the built-in "# Language" system-prompt section does not carry |
| `check-dependencies.sh` | script | Returns JSON with availability/version of required and optional dependencies |
| `check-skill-names.sh` | script | Validates skill directory names against plugin.json manifest for consistency |
| `check-workspace-python-deps.sh` | script | Fail-soft health check for optional Python packages in the workspace venv; reports per-package importability (`success` stays true) |
| `discover-plugins.sh` | script | Scans marketplace cache for installed cogni-x plugins, returns JSON inventory |
| `generate-settings.sh` | script | Generates settings files; `--update` preserves custom env vars and prunes the ones it generated for plugins no longer in the list |
| `install-mcp.sh` | script | Installs a git-based MCP server into `~/.claude/mcp-servers/` (clone, build, wrapper); outputs JSON with install and wrapper paths |
| `install-workspace-deps.sh` | script | Provisions optional Python packages from `python-deps-registry.json` into an isolated venv at `~/.claude/workspace-python-venv/`; idempotent, `--force` reinstalls, JSON envelope |
| `patch-desktop-config.py` | script | Merges git-installed MCP servers into the user's Claude Code (`~/.claude.json`) or Claude Desktop config from `mcp-git-registry.json`, preserving existing entries |
| `setup-obsidian.sh` | script | Copies vault templates, downloads Terminal plugin, substitutes path placeholders |
| `update-obsidian.sh` | script | Merges profiles, fixes WSL paths, removes deprecated profiles, copies scripts |
| `portability-utils.sh` | script | Cross-platform utilities (macOS, Linux, WSL, Git Bash) |
| `story-to-slides` | skill | Turn a narrative with a story arc into a presentation brief |
| `story-to-web` | skill | Turn a narrative with a story arc into a scrollable web-narrative brief, or a printed-poster storyboard brief in `mode=storyboard` |
| `story-to-infographic` | skill | Distil a narrative into a single-page infographic brief |
| `render-html-slides` | skill | Render a presentation brief into self-contained HTML slides with speaker notes |
| `enrich-report` | skill | Turn a markdown report into a themed HTML deliverable with charts and inline SVG diagrams |
| `review-brief` | skill | Score a visual brief from three stakeholder perspectives before rendering |
| `story-to-slides` | agent | Drive the story-to-slides skill as an autonomous subprocess |
| `story-to-web` | agent | Drive the story-to-web skill as an autonomous subprocess |
| `story-to-storyboard` | agent | Drive story-to-web's storyboard mode as an autonomous subprocess |
| `story-to-infographic` | agent | Drive the story-to-infographic skill as an autonomous subprocess |
| `html-slides` | agent | Render a presentation brief into HTML slides, returning statistics |
| `pptx` | agent | Create, edit and analyse PowerPoint presentations |
| `web` | agent | Render a web brief into a .pen file and self-contained HTML page |
| `storyboard` | agent | Render a storyboard brief into a multi-poster .pen file |
| `enrich-report` | agent | Orchestrate report enrichment end to end |
| `render-infographic-pencil` | agent | Render an editorial infographic in the data-journalism tradition |
| `render-infographic-sketchnote` | agent | Render a hand-drawn infographic in the sketchnote tradition |
| `render-infographic-whiteboard` | agent | Render a hand-drawn infographic in the whiteboard tradition |
| `concept-diagram` | agent | Generate one Excalidraw concept diagram and export it as SVG |
| `concept-diagram-svg` | agent | Generate one concept diagram as clean inline SVG, no Excalidraw dependency |
| `editorial-sketch` | agent | Generate one-colour editorial line art, including cartographic outlines |
| `report-html-writer` | agent | Write the complete scroll-layout HTML for an enriched report |
| `enriched-report-reviewer` | agent | Visually review an enriched HTML report against a 10-gate rubric |
| `slides-enrichment-artist` | agent | Generate prep slides and speaker notes, then write the presentation brief |
| `brief-review-assessor` | agent | Assess brief quality from three stakeholder perspectives |
| `cartographic-outline.py` | script | Render country outlines from the vendored Natural Earth data |
| `load-theme-component.py` | script | Load a theme component for the rendering skills |
| `rasterize-sketch.py` | script | Rasterize an SVG sketch |

## Architecture

```
cogni-workspace/
├── .claude-plugin/plugin.json    Plugin manifest
├── skills/                       22 workspace and visual-rendering skills
│   ├── audit-region-sources/     Audit per-plugin region-source overlays against the registry
│   ├── claim-entity/             Cross-plugin ClaimEntity data contract and store layout
│   ├── claims/                   Claim-verification lifecycle (+ scripts/claims-store.sh)
│   ├── cogni-issues/             File and track plugin issues through the GitHub CLI
│   ├── enrich-report/            Markdown report -> themed HTML with charts and diagrams
│   ├── install-mcp/              MCP server installation and user-config patching
│   ├── manage-markets/           Write path for the canonical supported-markets registry
│   ├── manage-themes/
│   ├── manage-workspace/         Init or update workspace (includes Obsidian integration)
│   ├── pick-theme/
│   ├── render-html-slides/       Presentation brief -> self-contained HTML slides
│   ├── review-brief/             Score a visual brief from three stakeholder perspectives
│   ├── story-to-infographic/     Narrative -> single-page infographic brief
│   ├── story-to-slides/          Narrative -> presentation brief
│   ├── story-to-web/             Narrative -> scrollable web-narrative or printed-poster brief
│   ├── workspace-dashboard/      Interactive HTML workspace status dashboard
│   └── workspace-status/
│                                  narrative, narrative-review, copywriter,
│                                  copy-json and copy-reader are omitted here for brevity
├── agents/                       26 subagents (claim verification, narrative, copywriting, visual rendering)
│   ├── claim-verifier.md         Verify claims against one source URL (JSON out)
│   ├── source-inspector.md       Open a source via claude-in-chrome for cobrowse/inspect
│   ├── story-to-*.md             Four narrative -> brief drivers (slides, web, storyboard, infographic)
│   ├── render-infographic-*.md   Three infographic renderers (pencil, sketchnote, whiteboard)
│   └── concept-diagram*.md       Diagram workers (Excalidraw and inline-SVG variants)
├── libraries/                    17 layout, taxonomy and worked-example files read at render time
├── commands/                     13 slash commands
│   ├── claims.md                 Registers /claims
│   ├── narrative*.md             Registers /narrative, /narrative-review, /narrative-adapt
│   ├── copywrite.md              Registers /copywrite and /review-doc
│   ├── render-infographic*.md    Registers /render-infographic and its two direct-dispatch variants
│   ├── render-html-slides.md     Registers /render-html-slides
│   ├── enrich-report.md          Registers /enrich-report
│   ├── review-brief.md           Registers /review-brief
│   └── troubleshoot.md           Registers /troubleshoot
├── wiki/                         Bundled vendor-curated insight-wave reference wiki (read directly; start at wiki/index.md)
│   ├── .cogni-wiki/              Wiki config + lockfile
│   ├── SCHEMA.md                 Wiki page schema
│   └── wiki/                     LLM-maintained pages, index, log, overview
├── templates/                    Shared templates
│   ├── obsidian/                 Obsidian vault config templates
│   └── mcp-wrappers/             Wrapper scripts for git-based MCP servers
├── hooks/                        Session lifecycle hooks
│   ├── hooks.json
│   ├── on-session-start.sh       One-line workspace status
│   └── on-session-start-language.sh  Language rules the built-in "# Language"
│                                 system-prompt section does not carry
├── scripts/                      Utility scripts
│   ├── check-dependencies.sh
│   ├── check-skill-names.sh
│   ├── check-workspace-python-deps.sh  Health check for optional Python packages
│   ├── discover-plugins.sh
│   ├── generate-settings.sh
│   ├── get-market-config.py      Merge canonical market registry with plugin overlays
│   ├── install-mcp.sh            Clone, build, and wrap git-based MCP servers
│   ├── install-workspace-deps.sh Provision optional Python deps into an isolated venv
│   ├── patch-desktop-config.py   Merge MCP entries into the user's MCP config
│   ├── setup-obsidian.sh
│   ├── update-obsidian.sh
│   └── baselines/                Tier-0 output baselines for script contract checks
├── bash/                         Cross-platform utilities
│   └── portability-utils.sh
├── contracts/                    Script interface definitions
│   ├── setup-obsidian.yml
│   └── update-obsidian.yml
├── themes/                       Brand theme storage
│   ├── _template/                Canonical theme template
│   └── cogni-work/               Bundled brand theme + showcase
├── schemas/                      JSON schemas
│   └── examples/                 Schema usage examples
├── references/                   Reference documentation
├── tests/                        Script unit tests (check-skill-names, sanitize-theme)
├── docs/                         Developer notes (e.g. theme-system v2 migration)
└── assets/
    └── output-styles/            Language-specific behavioral anchors (EN/DE)
```

## Dependencies

| Plugin | Required | Purpose |
|--------|----------|---------|
| cogni-website | No | Referenced in manage-workspace and workspace-status for website-related workspace configuration |
| cogni-portfolio | No | install-mcp references cogni-portfolio as a consumer of excalidraw MCP in the installation plan |
| claude-in-chrome | No | The `claims` skill's cobrowse mode and `workspace-status`' MCP health check use the Chrome extension; claim verification degrades to WebFetch without it |
| cogni-trends | No | audit-region-sources and manage-markets read the trends region-authority overlay when auditing market coverage |
| cogni-knowledge | No | workspace-status and manage-workspace route knowledge-base questions to knowledge-setup / knowledge-query |

## Contributing

Contributions welcome — theme templates, platform support, diagnostic checks, and documentation. See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

## Known Limitations

| ID | Issue | Severity | Affected Skills | Workaround |
|----|-------|----------|----------------|------------|
| KI-001 | Chrome native messaging host conflict between Cowork and Claude Code | S2-major | `/claims` (cobrowse), `/cogni-issues` (browser filing) | Toggle native host configs by renaming the `.json` file for the unused product and restarting Chrome. See [Known Issues Registry](../docs/known-issues.md#ki-001) for detailed steps. |

> When both Claude Desktop (Cowork) and Claude Code are installed, their competing native messaging host configurations cause browser automation tools to silently vanish. `/claims` cobrowse verification falls back to web fetch, and `/cogni-issues` browser filing falls back to the `gh` CLI, until the conflict is resolved.

## Custom development

Need bespoke workspace configurations, custom theme infrastructure, or a new plugin built for your domain? [cogni-work.ai](https://cogni-work.ai) builds and maintains custom Claude Code automation for teams — or reach out directly at [stephan@cogni-work.ai](mailto:stephan@cogni-work.ai).

## License

[Apache-2.0](LICENSE) — see [CONTRIBUTING.md](CONTRIBUTING.md) for contribution terms.

---

Built by [cogni-work](https://cogni-work.ai) — open-source tools for consulting intelligence.

# cogni-help

> **Incubating** (v0.0.x) — skills, data formats, and workflows may change at any time.

> **insight-wave readiness (Claude Code desktop recommended)** — Claude Code desktop is the recommended interface for insight-wave today. Cowork is a secondary path and is not yet production-ready for insight-wave workflows because of context-window and Pencil-MCP fidelity gaps — see the [deployment guide](../docs/deployment-guide.md) for detail. This guidance will flip when those gaps close upstream.

The onboarding and navigation layer for the [insight-wave](https://github.com/cogni-work/insight-wave) ecosystem — the single entry point that makes 13 plugins with 110 skills behave like one coherent system.

## Why this exists

| Problem | What happens | Impact |
|---------|-------------|--------|
| 13 plugins, no map | New users don't know which plugin handles their task | Trial-and-error onboarding — first productive use takes hours |
| Disconnected workflows | Research, narrative, visual, and sales plugins work together but no guide shows how | Users run one plugin well, miss the multi-plugin pipelines that deliver 10x value |
| Silent failures | A missing dependency or stale workspace breaks skills at runtime | Cryptic errors with no diagnostic path — users blame the plugin, not the config |
| No entry point | Users learn by stumbling into slash commands | Shallow usage — power features go undiscovered |

A capable ecosystem nobody can navigate is a capability nobody uses — the cost of insight-wave's breadth is paid in every onboarding hour and every undiscovered pipeline.

## What it is

A meta-plugin for the insight-wave ecosystem, built on the canonical cross-plugin pipelines. While the other plugins produce content — research, narratives, portfolios, visuals — cogni-help is the layer that routes you to the right one and shows how they chain. It owns no domain data; it indexes the ecosystem so the other thirteen plugins read as a single system.

## What it does

1. **Guide** users to the right plugin — match natural-language task descriptions to capabilities across 13 plugins and 110 skills
2. **Chain** plugins into pipelines — 7 cross-plugin workflow templates from install-to-infographic through full consulting engagements
3. **Diagnose** plugin problems — check integrity, dependencies, workspace health, and known issues before they surface as runtime failures
4. **Summarize** any plugin — generate one-screen quick-reference cheatsheets with commands, capabilities, and tips
5. **File** GitHub issues — guided consultation to capture bugs, feature requests, and change requests against any ecosystem plugin

## What it means for you

- **Skip the memorization.** Describe your task in plain language and the guide skill routes it to the exact plugin and skill across 13 plugins and 110 skills — first productive result in under 5 minutes.
- **Collapse multi-plugin work into 3–4 steps.** Run any of 7 workflow templates to chain plugins into repeatable pipelines — research-to-report in 3 steps, portfolio-to-pitch in 4.
- **Catch failures before they surface.** Run the diagnostics to surface missing dependencies, stale configs, and integrity issues before they become cryptic runtime errors.

## Install

Install insight-wave via Claude Code desktop:

- **5-minute walkthrough** — [From Install to Infographic](../docs/workflows/install-to-infographic.md)
- **Full setup reference** — [Claude Code desktop](../docs/claude-code-desktop.md)
- **Enterprise / compliance setup** — [Deployment guide](../docs/deployment-guide.md)

This plugin is part of the [insight-wave ecosystem](../docs/ecosystem-overview.md).

## Quick start

```
/guide "I need to create a sales pitch"   # find the right plugin
/workflow research-to-report               # see a cross-plugin pipeline
/cheatsheet cogni-trends                   # quick reference for a plugin
/troubleshoot                              # run diagnostics
cogni-issues                               # file a bug or feature request (skill, no slash command)
```

Or describe what you want:

- "Which plugin should I use to verify claims?"
- "Which plugin should I start with?"
- "How do I go from research to a slide deck?"
- "Something is broken with cogni-portfolio"

## Try it

Don't know which plugin handles your task? Describe it in plain language:

> Run `/guide "I need to turn research into a slide deck"`

The guide skill matches your description against all 13 plugins and 110 skills and routes you to the pipeline, e.g.:

```
research-to-report pipeline:
  cogni-knowledge  → research a topic into a wiki
  cogni-narrative  → compose the findings into a story
  cogni-visual     → render slides from the narrative
```

Then walk the matching pipeline step by step:

> Run `/workflow research-to-report`

The template names each step's plugin and command, what it takes in and hands off, and the pitfalls that trip people up — so the multi-plugin handoffs are explicit instead of rediscovered each time. Run the commands against your own workspace and you finish with a working artifact rather than notes. If something breaks along the way, `/troubleshoot` checks plugin integrity and dependencies and points you at the fix.

## Components

| Component | Type | What it does |
|-----------|------|--------------|
| `guide` | skill | Help users find the right insight-wave plugin or skill for their task |
| `troubleshoot` | skill | Diagnose and fix common issues with insight-wave plugins |
| `workflow` | skill | Cross-plugin workflow templates for common multi-plugin pipelines |
| `cheatsheet` | skill | Generate quick-reference cards for any insight-wave plugin |
| `cogni-issues` | skill | File and track GitHub issues against insight-wave ecosystem plugins |
| `/guide` | command | Find the right insight-wave plugin or skill for your task |
| `/troubleshoot` | command | Diagnose and fix issues with insight-wave plugins |
| `/workflow` | command | Show cross-plugin workflow templates for common multi-plugin pipelines |
| `/cheatsheet` | command | Generate a quick-reference card for any insight-wave plugin |

## Workflow Templates

| Workflow | Pipeline |
|----------|----------|
| `install-to-infographic` | cogni-workspace → cogni-workspace (themes) → cogni-visual |
| `research-to-report` | cogni-knowledge → cogni-narrative → cogni-visual |
| `trends-to-solutions` | cogni-trends → cogni-portfolio → cogni-marketing |
| `portfolio-to-pitch` | cogni-portfolio → cogni-narrative → cogni-sales → cogni-visual |
| `portfolio-to-website` | cogni-portfolio → cogni-workspace → cogni-website |
| `content-pipeline` | cogni-marketing → cogni-narrative → cogni-copywriting → cogni-visual |
| `consulting-engagement` | cogni-consult (setup → scope → action fields → design-thinking → personas) |
| `docs-pipeline` | cogni-docs: doc-start → audit → generate → sync → power → claude → hub → bridge |
| `full-onboarding` | cogni-workspace → docs → workflow templates → practice |

## Data model

Issue state is stored in `cogni-issues/issues.json` in the working directory.
The plugin keeps no other state.

## How it works

cogni-help is a thin index over the ecosystem rather than a content producer, so each skill resolves a different navigation question against the same shared map. `guide` reads a plugin-capability catalog and matches a natural-language task description to the plugin and skill that owns it — discovery comes first, because a user who picks the wrong plugin never reaches the pipeline that would have worked.

Once the right entry point is known, `workflow` takes over. It returns one of the cross-plugin templates — ordered plugin chains like research-to-report or portfolio-to-pitch — so the multi-plugin handoffs are explicit instead of rediscovered each time. Each canonical template has a one-to-one tutorial companion at `docs/workflows/<id>.md`, which is where the longer-form walkthrough lives.

The remaining skills support that core loop. `troubleshoot` runs ahead of failure — it checks plugin integrity, dependencies, and workspace health (delegating infrastructure checks to cogni-workspace) so a missing dependency surfaces as a diagnostic rather than a cryptic runtime error. `cheatsheet` reads any plugin's metadata to render a one-screen reference, and `cogni-issues` files bugs and requests against the right ecosystem repo without leaving the session. Every dependency is soft: cogni-help runs without any specific plugin installed, and only the workflows that walk a given plugin require it to be present.

## Architecture

```
cogni-help/
├── .claude-plugin/plugin.json    Plugin manifest
├── skills/                       5 skills
│   ├── guide/                    Plugin discovery
│   ├── troubleshoot/             Diagnostics
│   ├── workflow/                 Pipeline templates
│   ├── cheatsheet/               Quick reference cards
│   └── cogni-issues/             GitHub issue management
└── commands/                     4 slash commands
    ├── guide.md
    ├── troubleshoot.md
    ├── workflow.md
    └── cheatsheet.md
```

## Dependencies

| Plugin | Required | Purpose |
|--------|----------|---------|
| cogni-workspace | No | troubleshoot delegates to workspace-status for infrastructure health checks |
| All ecosystem plugins | No | Required by the workflow templates that walk them, but not by guide, troubleshoot, workflow, cheatsheet, or issues |

## Contributing

Contributions welcome — workflow templates, diagnostic checks, and documentation. See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

## Known Limitations

| ID | Issue | Severity | Affected Skills | Workaround |
|----|-------|----------|----------------|------------|
| KI-001 | Chrome native messaging host conflict between Cowork and Claude Code | S2-major | `/cogni-issues` (browser filing) | Toggle native host configs by renaming the `.json` file for the unused product and restarting Chrome. See [Known Issues Registry](../docs/known-issues.md#ki-001) for detailed steps. |

> When both Claude Desktop (Cowork) and Claude Code are installed, their competing native messaging host configurations cause browser automation tools to silently vanish. The `/cogni-issues` skill falls back to `gh` CLI — issue filing still works, but interactive browser-based filing is unavailable until the conflict is resolved.

## Custom development

Need a bespoke onboarding path for your team, a new workflow template, or a plugin built for your stack? [cogni-work.ai](https://cogni-work.ai) builds and maintains custom Claude Code automation and onboarding for organizations adopting the insight-wave ecosystem.

## License

[Apache-2.0](LICENSE) — see [CONTRIBUTING.md](CONTRIBUTING.md) for contribution terms.

---

Built by [cogni-work](https://cogni-work.ai) — open-source tools for consulting intelligence.

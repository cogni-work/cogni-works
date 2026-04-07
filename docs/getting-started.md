# Getting Started with insight-wave

This guide walks you through installing the insight-wave marketplace, initializing your workspace, and running your first research report. By the end you will have all 13 plugins installed, a configured workspace, and a working research report you can take further.

---

## Prerequisites

Before installing, confirm you have the following:

| Requirement | Notes |
|-------------|-------|
| [Claude Code CLI](https://docs.anthropic.com/en/docs/claude-code/setup) or Claude Desktop / Cowork | insight-wave plugins run inside Claude Code or Cowork sessions |
| Terminal (bash / zsh) | Required for workspace initialization scripts |
| `jq` | JSON processing — used by workspace scripts |
| `python3` | Standard library only, no pip dependencies |
| `bash 3.2+` | Ships with macOS; standard on Linux |

Optional but recommended: [Obsidian](https://obsidian.md/) for browsable knowledge management. All plugin outputs write Obsidian-compatible markdown with YAML frontmatter.

### Choose your path

**Standard path: Claude Desktop / Cowork** — for consultants, sales teams, and marketing teams who want to use plugins through a visual interface:

- [Download Claude Desktop](https://claude.ai/download) (macOS, Windows)
- [Get started with Cowork](https://support.claude.com/en/articles/13345190-get-started-with-cowork) — collaborative working sessions with local file access
- [Set up MCP servers in Desktop](https://support.claude.com/en/articles/10949351-getting-started-with-local-mcp-servers-on-claude-desktop) — connect plugins to external tools
- Course: [Introduction to Claude Cowork](https://anthropic.skilljar.com/introduction-to-claude-cowork)

**Specialist path: Claude Code** — for developers and power users who want CLI access, IDE integration, and full plugin control:

- [Claude Code setup](https://docs.anthropic.com/en/docs/claude-code/setup) (CLI, VS Code, JetBrains)
- [MCP in Claude Code](https://docs.anthropic.com/en/docs/claude-code/mcp) — configure MCP servers for extended capabilities
- [Discover and install plugins](https://code.claude.com/docs/en/discover-plugins) — browse and install marketplace plugins
- Course: [Introduction to Agent Skills](https://anthropic.skilljar.com/introduction-to-agent-skills)

---

## Step 1: Add the Marketplace

In your Claude Code session, run:

```shell
/plugin marketplace add cogni-work/insight-wave
```

This registers the insight-wave marketplace so you can install any of the 13 plugins from it.

### Install plugins

Install `cogni-workspace` first — it provides the shared foundation (environment variables, theme paths, plugin discovery) that every other plugin depends on:

```shell
/plugin install cogni-workspace@insight-wave    # install first — foundation layer
/plugin install cogni-research@insight-wave
/plugin install cogni-trends@insight-wave
/plugin install cogni-portfolio@insight-wave
/plugin install cogni-narrative@insight-wave
/plugin install cogni-copywriting@insight-wave
/plugin install cogni-sales@insight-wave
/plugin install cogni-marketing@insight-wave
/plugin install cogni-visual@insight-wave
/plugin install cogni-claims@insight-wave
/plugin install cogni-consulting@insight-wave
/plugin install cogni-website@insight-wave
/plugin install cogni-help@insight-wave
```

Or browse and select interactively: open `/plugin` and go to the **Discover** tab.

### MCP servers

Some plugins extend their capabilities through [MCP servers](https://docs.anthropic.com/en/docs/build-with-claude/mcp). Claude Desktop / Cowork auto-discovers and starts required servers on install.

| MCP Server | Used by | What it enables |
|------------|---------|-----------------|
| excalidraw | cogni-visual, cogni-portfolio | Diagram and journey map rendering |
| claude-in-chrome | cogni-claims, cogni-help, cogni-website, cogni-workspace | Browser automation — claim verification, issue filing, website preview |
| pencil | cogni-visual, cogni-website | Web narrative, storyboard, and poster rendering |

The excalidraw MCP is auto-installed via plugin `.mcp.json` files (npx). The `claude-in-chrome` [Chrome extension](https://code.claude.com/docs/en/chrome) and [Pencil](https://docs.pencil.dev/getting-started/installation) desktop app require manual installation. Plugins that don't use MCP servers work without them — only install what you need.

---

## Step 2: Initialize Your Workspace

Navigate to the directory where you want your workspace (a project folder, or your home directory for a shared workspace), then run:

```
/manage-workspace
```

The skill auto-detects whether you are initializing fresh or updating an existing workspace. On first run it walks you through four steps:

1. **Dependency check** — verifies `jq`, `python3`, and `bash` are available. Reports exactly what is missing if any check fails.
2. **Plugin discovery** — scans your installed cogni-* plugins and presents them for confirmation. The list determines which environment variables get wired up.
3. **Preferences** — asks for your preferred language (EN or DE) and whether you use Obsidian.
4. **Settings generation** — creates three files in your workspace:
   - `.claude/settings.local.json` — environment variables Claude Code auto-injects at session start
   - `.workspace-env.sh` — the same variables for use outside Claude Code (Obsidian Terminal, CI)
   - `.workspace-config.json` — workspace metadata (version, language, registered plugins)

If you use Obsidian, the skill offers to scaffold the vault with a Terminal plugin and Claude Code launcher so you can work in Obsidian and launch Claude from the built-in terminal.

After initialization, run `/workspace-status` any time to check that environment variables are set correctly and all registered plugins are reachable.

When you install or remove plugins later, run `/manage-workspace` again — update mode detects the changes, shows you a diff, regenerates env vars, and backs up the previous state before touching anything.

### Enterprise deployment

For enterprise environments with security and compliance requirements — API key management, SSO, GDPR data residency (EU via AWS Bedrock or Vertex AI), audit logging, and managed settings — see the [Deployment Guide](deployment-guide.md).

---

## Step 3: Your First Report with cogni-research

Once your workspace is initialized, try a research report. Type this prompt directly:

```
Write a detailed research report on AI adoption trends in mid-market B2B software companies
```

cogni-research picks this up and runs a multi-phase pipeline:

1. Decomposes your topic into 7–10 orthogonal sub-questions
2. Dispatches one research agent per sub-question in parallel, searching the web and extracting findings
3. Aggregates and deduplicates sources across all agents
4. Writes a structured report with inline citations linking every claim to its source URL
5. Runs an automated structural review (completeness, coherence, depth, clarity)
6. Optionally verifies claims against source URLs via cogni-claims (run `/verify-report` after the draft is ready)

A `detailed` report typically completes in 5–15 minutes depending on sub-question count and web response times. The output lands in a timestamped directory under your workspace:

```
{workspace}/cogni-research/data/{slug}/
  00-sub-questions/    decomposed research questions
  01-contexts/         per-sub-question findings
  02-sources/          deduplicated source registry
  report-draft.md      the compiled report
```

All files use Obsidian-compatible YAML frontmatter — if you set up the vault integration, you can browse the full research trail in Obsidian.

**Depth options:**

| Keyword | Agents | Use when |
|---------|--------|----------|
| basic | 5–7 | Quick overview, single-topic answer |
| detailed | 7–12 | Multi-section report with sourced analysis |
| deep | 15–25 | Recursive exploration, exhaustive sourcing |

---

## Step 4: What to Try Next

Once you have a report, the typical next steps are to transform it into a deliverable. Each workflow below links to a dedicated guide.

| What you want to do | Workflow guide | Key plugins |
|---------------------|---------------|-------------|
| Turn a research report into a verified, polished narrative | [Research to Report](workflows/research-to-report.md) | cogni-research, cogni-claims, cogni-copywriting |
| Build a sales pitch for a named customer or segment | [Portfolio to Pitch](workflows/portfolio-to-pitch.md) | cogni-portfolio, cogni-sales, cogni-visual |
| Produce B2B marketing content from portfolio and trends | [Content Pipeline](workflows/content-pipeline.md) | cogni-trends, cogni-portfolio, cogni-marketing |
| Scout industry trends and model investment themes | [Trends to Solutions](workflows/trends-to-solutions.md) | cogni-trends, cogni-portfolio, cogni-visual |
| Run a consulting engagement end-to-end | [Consulting Engagement](workflows/consulting-engagement.md) | cogni-consulting, cogni-research, cogni-portfolio, cogni-visual |

### Quick commands to explore

```
/workspace-status          check workspace health
/cheatsheet                quick-reference for all installed plugins
/courses                   start the 12-course interactive curriculum
/guide cogni-research      read the full plugin guide
```

For troubleshooting, run `/troubleshoot`.

---

## See also

- [Ecosystem Overview](ecosystem-overview.md) — how the 13 plugins fit together and how data flows between them
- [er-diagram.md](er-diagram.md) — cross-plugin entity relationship diagram
- [cogni-workspace plugin guide](plugin-guide/cogni-workspace.md)
- [cogni-research plugin guide](plugin-guide/cogni-research.md)

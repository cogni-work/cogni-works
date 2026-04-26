# Workflow: Install to Infographic

**Pipeline**: cogni-workspace → cogni-workspace (themes) → cogni-visual
**Duration**: 30–60 minutes for first-run setup and a rendered infographic
**Use case**: First-run capstone — install insight-wave, pick or extract a theme, and render your first infographic to verify Pencil and Excalidraw MCP are wired up

```mermaid
graph LR
    A[/plugin marketplace add/] -->|install plugins| B[cogni-workspace]
    B -->|/manage-workspace + /install-mcp| C[Themes]
    C -->|/manage-themes + /pick-theme| D[cogni-visual]
    D -->|.excalidraw + .pen| E[Infographics]
```

## Step 1: Add the Marketplace and Install Plugins

**Command**: `/plugin marketplace add cogni-work/insight-wave` then `/plugin install <plugin>@insight-wave` for each plugin

**Input**: A working Claude Code session with subscription auth
**Output**: insight-wave plugins available as slash commands

**Tips**:
- Start with `cogni-workspace` — it's the foundation every other plugin depends on
- Enable auto-update inside `/plugin → Marketplaces → insight-wave` so new versions arrive without re-running this step
- For this workflow you minimally need `cogni-workspace` and `cogni-visual`; install the rest when you reach a follow-on workflow that needs them

## Step 2: Initialize the Workspace and Install MCP Servers

**Command**: `/manage-workspace` then `/install-mcp`

**Input**: A target directory for the workspace
**Output**: Workspace folder structure on disk; Pencil, Excalidraw, and claude-in-chrome MCP servers installed

**Tips**:
- Accept the defaults — `/install-mcp` wires up all three MCP servers in one pass
- Step 3 uses claude-in-chrome MCP to read your company website; Step 4 uses Pencil and Excalidraw to render
- Verify with `/workspace-status` — every MCP should report green before continuing

## Step 3: Build a Theme

**Command**: `/manage-themes extract https://your-company.com` then `/pick-theme`

**Input**: A public-facing company URL (or a PowerPoint template, or a preset)
**Output**: A workspace theme that every visual plugin inherits

**Tips**:
- The extractor reads the live site via claude-in-chrome MCP and pulls colors, fonts, and logo
- Sites behind a login wall — pass a PowerPoint template or pick a preset instead
- `/pick-theme` makes the theme the default for slides, infographics, dashboards, and websites

## Step 4: Render the First Infographic

**Command**: `/story-to-infographic --style=sketchnote` then `/story-to-infographic --style=economist`

**Input**: A short narrative paragraph (a 4–6 sentence story works well as the first try)
**Output**: An `.excalidraw` file (sketchnote preset, hand-drawn) and a `.pen` file (economist preset, editorial)

**Tips**:
- Run both presets — together they double as a live check that both Pencil and Excalidraw MCP are wired up correctly
- Both inherit the theme from Step 3, so colors should match your company website
- Style → renderer mapping: `sketchnote`/`whiteboard` → Excalidraw, `economist`/`editorial`/`data-viz`/`corporate` → Pencil. A blank file usually means a mismatch

## Step 5: Pick a Follow-On Workflow

The first-run workflow is complete — you have a working workspace, a branded theme, and two rendered infographics. From here, pick what you want to produce next:

- **Research a topic with verified sources** → `research-to-report`
- **Position a product for a market** → `portfolio-to-pitch`
- **Scout industry trends** → `trends-to-solutions`
- **Build multi-channel marketing content** → `content-pipeline`
- **Generate a website from your portfolio** → `portfolio-to-website`
- **Run a structured consulting engagement** → `consulting-engagement`

## Common Pitfalls

- **MCP not running.** A "Pencil MCP not available" or "Excalidraw MCP not available" error almost always means the MCP server is installed but not started. Run `/mcp` to see status, or re-run `/install-mcp <name>` and restart the Claude session.
- **Style/renderer mismatch.** The renderer dispatches off the `--style` flag. `sketchnote` produces an Excalidraw file; `economist` produces a Pencil file. Asking for a preset whose MCP isn't running fails silently — confirm both work in Step 4 before relying on either downstream.
- **Workspace not initialized.** Skipping `/manage-workspace` leaves theme extraction with nowhere to write the theme. Always run it before `/manage-themes`.

---

For the narrative tutorial — including platform-specific Claude Code setup links, screenshots, and per-error troubleshooting tables — see [`docs/workflows/install-to-infographic.md`](../../../../docs/workflows/install-to-infographic.md).

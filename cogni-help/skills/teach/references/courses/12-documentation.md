# Course 12: Documentation Pipeline

**Duration**: 45 minutes | **Modules**: 5 | **Prerequisites**: Course 2 (workspace basics)
**Plugin**: cogni-docs
**Audience**: Maintainers and contributors documenting insight-wave plugins and monorepos

---

## Module 1: Why Documentation Drifts

### Theory (3 min)

Documentation goes stale the moment code changes. A new skill is added but the README's
component table still shows the old count. A plugin description is polished in the README
but plugin.json still has the first-draft version. The `docs/` directory describes a workflow
that was restructured two sprints ago.

**cogni-docs** treats documentation as a verifiable property — like a test suite, but for prose.
It can detect drift, regenerate structural sections, and strengthen messaging, all without
overwriting the parts you wrote by hand.

**The hand-written vs. auto-generated boundary** is the core design principle:
- **Auto-generated**: Component tables, architecture trees, dependency lists, quick-start sections
- **Hand-written**: Title paragraph, "Why this exists", "What it is", "What it means for you"

cogni-docs regenerates the first group from disk and preserves the second group verbatim.
This prevents silent overwrites while keeping structural documentation accurate.

**Nine drift checks** catch misalignments across the codebase:

| Check | What it detects |
|-------|----------------|
| Components | README component table vs. actual skills/agents/commands on disk |
| Architecture | README architecture tree vs. actual directory structure |
| Descriptions | Mismatched descriptions across README, plugin.json, marketplace.json |
| Dependencies | README dependency table vs. actual cross-plugin references |
| plugin.json | Missing or outdated fields in the plugin manifest |
| CLAUDE.md | Complex plugins (5+ skills) lacking a developer guide |
| Power messaging | Weak or missing IS/DOES/MEANS messaging in hand-written sections |
| docs/ staleness | User documentation out of sync with current plugin state |
| Commercial tone | Soft-skill messaging that lacks business-impact framing |

### Demo

Walk through the drift problem:
1. Show a README with a component table — count the skills listed
2. Check the actual `skills/` directory — note any mismatch
3. Show plugin.json description vs. README first paragraph — are they identical?
4. Explain: this drift happens naturally as plugins evolve; cogni-docs automates the fix

### Exercise

Ask the user to:
1. Pick any installed insight-wave plugin
2. Read its README.md and count the skills listed in the component table
3. Check the actual `skills/` directory — do the counts match?
4. Compare the plugin description in README vs. plugin.json — are they aligned?

### Quiz

1. **Multiple choice**: What is the core design principle of cogni-docs?
   - a) It rewrites all documentation from scratch each time
   - b) It separates hand-written sections (preserved) from auto-generated sections (rebuilt from disk)
   - c) It only checks for spelling errors
   - d) It requires manual approval for every change
   **Answer**: b

2. **Multiple choice**: How many drift checks does cogni-docs perform?
   - a) 3
   - b) 5
   - c) 9
   - d) 15
   **Answer**: c

### Recap

- Documentation drifts as code evolves — cogni-docs detects and fixes this automatically
- Hand-written messaging is preserved; structural sections are regenerated from disk
- 9 drift checks cover components, architecture, descriptions, dependencies, and more

---

## Module 2: The Documentation Pipeline

### Theory (3 min)

cogni-docs has 8 skills that form a pipeline. You rarely need all 8 — most sessions use 2-3.

**The pipeline (recommended order)**:

```
doc-start → doc-audit → doc-generate → doc-sync → doc-power → doc-claude → doc-hub → doc-bridge
```

| Skill | What it does | When to use |
|-------|-------------|-------------|
| `doc-start` | Scans the repo and recommends the next action | Always start here |
| `doc-audit` | Runs 9 drift checks, produces a status dashboard | Check documentation health |
| `doc-generate` | Rebuilds auto-generated README sections from disk | Fix structural drift |
| `doc-sync` | Aligns descriptions across README, plugin.json, marketplace.json | Fix description mismatches |
| `doc-power` | Generates IS/DOES/MEANS messaging for hand-written sections | Strengthen messaging |
| `doc-claude` | Generates CLAUDE.md developer guides for complex plugins | Document complex plugins |
| `doc-hub` | Generates the `docs/` directory (plugin guides, workflows, architecture) | Create user documentation |
| `doc-bridge` | Generates a journey-based root README | Update the repo entry point |

**Common subsets** — you don't always run the full pipeline:
- **Quick health check**: `doc-start` → `doc-audit`
- **Fix stale docs**: `doc-audit` → `doc-generate` → `doc-sync`
- **Improve messaging**: `doc-audit` → `doc-power`
- **Full documentation overhaul**: all 8 steps in order

`doc-start` recommends which subset based on what it finds.

### Demo

Walk through the pipeline entry point:
1. Run `/doc-start` and observe the status dashboard
2. Show how it recommends the highest-priority action
3. Explain each pipeline stage and when it applies
4. Note: the `/workflow docs-pipeline` command provides the full step-by-step playbook

### Exercise

Ask the user to:
1. Look at the pipeline table above
2. Scenario: You added a new skill to cogni-portfolio but haven't updated any docs.
   Which pipeline subset would you run? (Answer: doc-audit → doc-generate → doc-sync)
3. Scenario: You want to improve how cogni-trends describes itself to potential users.
   Which skill handles that? (Answer: doc-power for IS/DOES/MEANS messaging)

### Quiz

1. **Multiple choice**: What should you always run first?
   - a) doc-generate
   - b) doc-start
   - c) doc-bridge
   - d) doc-power
   **Answer**: b

2. **Multiple choice**: Which subset fixes structural drift in READMEs?
   - a) doc-start → doc-power
   - b) doc-audit → doc-generate → doc-sync
   - c) doc-hub → doc-bridge
   - d) doc-claude only
   **Answer**: b

### Recap

- 8 skills form a pipeline; most sessions need 2-3
- Always start with `doc-start` — it scans and recommends
- Common paths: health check, structural fix, messaging improvement, full overhaul
- The `/workflow docs-pipeline` template has the complete step-by-step playbook

---

## Module 3: IS/DOES/MEANS Power Messaging

### Theory (3 min)

Flat plugin descriptions like "cogni-trends does trend research" don't communicate value.
The **IS/DOES/MEANS framework** (also known as FAB — Features, Advantages, Benefits)
transforms descriptions into business-impact messaging:

| Layer | Question | Example (cogni-trends) |
|-------|----------|----------------------|
| **IS** (Feature) | What is it? | Strategic trend intelligence engine |
| **DOES** (Advantage) | What does it do differently? | Scouts 60 industry-contextualized trends across 4 dimensions |
| **MEANS** (Benefit) | What does that mean for me? | You enter client meetings with foresight your competitors lack |

The key insight: **MEANS speaks to the user's world, not the tool's capabilities.**
A consultant doesn't care about "4 TIPS dimensions" — they care about walking into
a client meeting with unique insights.

**doc-power** generates IS/DOES/MEANS messaging for the hand-written README sections:
- Title paragraph (the "IS" statement)
- Problem table ("Why this exists")
- Identity section ("What it is")
- Benefits section ("What it means for you")

It shows side-by-side comparisons and never overwrites without approval.

### Demo

Walk through power messaging:
1. Show a weak plugin description: "cogni-portfolio manages product portfolios"
2. Apply IS/DOES/MEANS: IS = "Portfolio messaging platform", DOES = "Maps features to markets
   with differentiated value propositions", MEANS = "Your sales team speaks the buyer's language
   from day one"
3. Show how doc-power generates these transformations for README sections

### Exercise

Ask the user to:
1. Pick any insight-wave plugin they've used
2. Write a one-sentence description of what it does (their "before")
3. Break it into IS / DOES / MEANS:
   - IS: What is it? (identity, not features)
   - DOES: What does it do that's different? (advantage, not description)
   - MEANS: What does that mean for the user? (benefit in their language)
4. Compare their "before" and "after" — which communicates more value?

### Quiz

1. **Multiple choice**: What does the MEANS layer communicate?
   - a) Technical specifications
   - b) The benefit in the user's own language and context
   - c) The feature list
   - d) The installation instructions
   **Answer**: b

2. **Hands-on**: Transform this description using IS/DOES/MEANS:
   "cogni-claims checks if claims match their sources"

### Recap

- IS/DOES/MEANS transforms flat descriptions into business-impact messaging
- IS = identity, DOES = differentiated capability, MEANS = benefit in the user's world
- doc-power generates these for README hand-written sections
- Side-by-side comparison ensures quality; nothing is overwritten without approval

---

## Module 4: The docs/ Directory — User Documentation

### Theory (3 min)

READMEs use **pitch voice** — they sell the plugin to potential users. But once someone
is using the plugin, they need **tutorial voice** — practical guidance on how to get
things done.

**doc-hub** generates the `docs/` directory, which contains user-facing documentation
in tutorial voice:

```
docs/
├── getting-started.md          — First steps for new users
├── ecosystem-overview.md       — Plugin landscape, data flows, conventions
├── plugin-guide/               — One tutorial per plugin (12 guides)
│   ├── cogni-claims.md
│   ├── cogni-consulting.md
│   ├── cogni-copywriting.md
│   └── ... (one per plugin)
├── workflows/                  — Cross-plugin pipeline tutorials
│   ├── research-to-report.md
│   ├── portfolio-to-pitch.md
│   ├── trends-to-solutions.md
│   ├── consulting-engagement.md
│   └── content-pipeline.md
├── architecture/               — Design principles, plugin anatomy, ER diagram
│   ├── design-philosophy.md
│   ├── plugin-anatomy.md
│   └── er-diagram.md
└── contributing/
    └── plugin-development.md   — How to build a new plugin
```

Each **plugin guide** follows a standard structure:
- Overview (IS statement, ecosystem fit)
- Key Concepts (terminology table)
- Getting Started (first command, expected output)
- Capabilities (one section per skill)
- Integration Points (upstream/downstream connections)
- Common Workflows (2-3 scenarios)
- Data Model (JSON schema for entity-producing plugins)

**doc-hub reads current README state** — run it after messaging is finalized so the
tutorials reflect the polished descriptions.

### Demo

Walk through the docs/ directory:
1. Show `docs/getting-started.md` — the entry point for new users
2. Open a plugin guide (e.g., `docs/plugin-guide/cogni-trends.md`) — show the tutorial structure
3. Open a workflow guide (e.g., `docs/workflows/research-to-report.md`) — show the pipeline walkthrough
4. Compare README pitch voice vs. plugin guide tutorial voice for the same plugin
5. Note: cogni-help courses and docs/ plugin guides complement each other —
   courses teach interactively, guides serve as reference documentation

### Exercise

Ask the user to:
1. Open `docs/getting-started.md` and read the first section
2. Open the plugin guide for a plugin they learned in an earlier course
3. Compare: what does the guide cover that the course didn't? What does the course cover
   that the guide doesn't?
4. When would they reach for the guide vs. retaking the course?

### Quiz

1. **Multiple choice**: What is the difference between a README and a plugin guide in docs/?
   - a) The README is longer
   - b) The README uses pitch voice (selling); the guide uses tutorial voice (teaching)
   - c) They contain the same content
   - d) Plugin guides are auto-generated, READMEs are hand-written
   **Answer**: b

2. **Multiple choice**: When should you run doc-hub?
   - a) Before fixing any drift
   - b) After messaging is finalized, so tutorials reflect polished descriptions
   - c) Only once, when the repo is first created
   - d) doc-hub runs automatically
   **Answer**: b

### Recap

- `docs/` contains user-facing documentation in tutorial voice
- doc-hub generates plugin guides, workflow guides, architecture docs, and getting-started
- Plugin guides complement courses — guides are reference, courses are interactive learning
- Run doc-hub after messaging is finalized so tutorials reflect the current state

---

## Module 5: Root README & Full Pipeline Integration

### Theory (3 min)

**doc-bridge** generates the root README as a journey-based narrative instead of a flat
plugin list. It groups plugins by workflow stage:

```
Research → Analyze → Articulate → Sell → Visualize → Verify → Learn
```

This tells a story: "Start with research, analyze the findings, articulate them as
narratives, sell them as pitches, visualize as presentations, verify claims, and learn
through courses." Each stage links to the relevant plugins.

**doc-bridge runs last** because it reads everything else — all READMEs, all docs/ content —
to create the narrative overview.

**The full pipeline integration**:

```
doc-start (scan & recommend)
    │
    ├── doc-audit (9 drift checks)
    │
    ├── doc-generate (rebuild structural sections)
    │
    ├── doc-sync (align descriptions)
    │
    ├── doc-power (IS/DOES/MEANS messaging)
    │
    ├── doc-claude (developer guides for complex plugins)
    │
    ├── doc-hub (docs/ directory — user documentation)
    │
    └── doc-bridge (root README — journey narrative)
```

**cogni-copywriting integration**: Pass `--polish` to doc-power for additional
text polish. cogni-docs handles structure and messaging; cogni-copywriting handles
prose quality.

### Demo

Walk through the full pipeline:
1. Show the root README — is it a flat list or a journey narrative?
2. Run `/doc-start` to see the current documentation health
3. Trace the pipeline: what would each step fix or improve?
4. Show how doc-bridge groups plugins by workflow stage
5. Explain the `--polish` flag for cogni-copywriting integration

### Exercise

Ask the user to:
1. Read the current root README
2. Identify: is it a flat plugin list or a journey-based narrative?
3. If they were a new visitor to the repo, what would they learn from the README?
4. Sketch a pipeline for their documentation needs:
   - What's drifted? (audit)
   - What needs structural fixes? (generate/sync)
   - What needs better messaging? (power)
   - Does the docs/ directory need updating? (hub)
   - Does the root README need refreshing? (bridge)

### Quiz

1. **Multiple choice**: Why does doc-bridge run last?
   - a) It's the simplest skill
   - b) It reads all other documentation to create the narrative overview
   - c) It doesn't depend on anything
   - d) It only updates the version number
   **Answer**: b

2. **Hands-on**: Describe the full documentation pipeline for your workspace.
   Which steps would you run today, and which can wait?

### Recap

- doc-bridge creates a journey-based root README, not a flat list
- It runs last because it reads everything else
- The full pipeline: start → audit → generate → sync → power → claude → hub → bridge
- Most sessions use 2-3 steps, not all 8
- cogni-copywriting integration via `--polish` flag for prose quality

---

## Course Completion

You now understand:
- Why documentation drifts and how cogni-docs detects it (9 checks)
- The 8-skill pipeline and common subsets for different documentation needs
- IS/DOES/MEANS power messaging for transforming flat descriptions
- The docs/ directory structure and the difference between pitch and tutorial voice
- How doc-bridge creates a journey-based root README

**Reference documentation**: For detailed guidance on any pipeline step, check:
- `/workflow docs-pipeline` — the full step-by-step playbook
- `docs/plugin-guide/cogni-docs.md` — the plugin guide (when available)

**Next steps**:
- Run `/doc-start` on your workspace to see the current documentation health
- Pick the highest-priority action and run the relevant pipeline subset
- Use `/cheatsheet cogni-docs` for a quick command reference

**Something unclear or broken?** Tell Claude what happened — cogni-issues will help you file it.

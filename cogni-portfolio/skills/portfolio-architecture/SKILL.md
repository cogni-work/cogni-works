---
name: portfolio-architecture
description: |
  Generate a layered architecture mermaid diagram showing products, features,
  and their relationships. Use whenever the user mentions architecture diagram,
  portfolio diagram, product-feature diagram, "show me the structure",
  "visualize the portfolio", portfolio architecture, feature map, product tree,
  "how do the products relate", or wants a visual overview of how products and
  features fit together — even if they don't say "architecture" explicitly.
allowed-tools: Read, Write, Edit, Glob, Grep, Bash
---

# Portfolio Architecture Diagram

Generate a layered mermaid diagram that visualizes the product-feature hierarchy of a cogni-portfolio project. The diagram shows products as top-level groups, features nested inside (grouped by category when available), readiness states as visual styles, and cross-product bridges where products share capability categories.

The diagram renders natively in GitHub, Obsidian, and any mermaid-capable markdown viewer — making it the portable, embeddable complement to the interactive HTML dashboard.

## When This Skill Adds Value

- After defining or restructuring products — see the full hierarchy at a glance
- After shaping features — verify grouping, coverage, and category alignment
- During portfolio review — spot gaps (empty products), orphaned features, or imbalanced distribution
- When preparing documentation — embed the diagram in proposals, READMEs, or Obsidian vaults
- When other skills offer "view the architecture diagram" at review checkpoints

## Workflow

### 1. Find the Portfolio Project

Read `portfolio.json` in the current working directory or a user-specified path to locate the project. If no portfolio project is found, tell the user to run the `portfolio-setup` skill first.

### 2. Generate the Diagram

Run the generator script:

```bash
$CLAUDE_PLUGIN_ROOT/scripts/generate-architecture-diagram.sh <project-dir>
```

The script reads all `products/*.json` and `features/*.json`, then writes `output/architecture.md` containing a mermaid `flowchart TD` diagram.

### 3. Present Results

Read the generated `output/architecture.md` and present:

1. **Summary**: Product count, feature count, readiness breakdown (GA/Beta/Planned)
2. **The mermaid diagram** — render it inline so the user sees the code block
3. **Observations**: Flag any issues the diagram reveals:
   - Products with zero features (empty boxes in the diagram)
   - Unassigned features (referencing non-existent product slugs)
   - Imbalanced distribution (one product with 15 features, another with 2)
   - Cross-product bridges (shared categories that may signal overlap or intentional synergy)

### 4. Offer Next Steps

After presenting the diagram, offer options:

- **(a) Refine products** — delegate to the `products` skill if product boundaries need adjustment
- **(b) Refine features** — delegate to the `features` skill if features need restructuring
- **(c) Open the dashboard** — delegate to the `dashboard-refresher` agent for the full interactive view
- **(d) Done** — the diagram is saved at `output/architecture.md`

## Diagram Encoding

The generator uses these visual conventions:

| Element | Mermaid Representation | Meaning |
|---------|----------------------|---------|
| Product | Outer subgraph | Top-level offering (labeled with name, maturity, revenue model) |
| Category | Nested subgraph | Feature grouping within a product |
| Feature (GA) | Solid green rectangle `:::ga` | Generally available capability |
| Feature (Beta) | Rounded amber box `([...]):::beta` | Limited availability / pilot |
| Feature (Planned) | Dashed grey rectangle `:::planned` | Roadmap only |
| Cross-product bridge | Dotted line `-.-` | Products sharing a capability category |
| Empty product | Grey placeholder | Product with no features defined yet |

Features are ordered by `sort_order` within each product/category (customer-facing value at top, infrastructure at bottom).

## Important Notes

- The diagram is auto-generated — do not edit `output/architecture.md` manually; changes will be overwritten on next generation
- Products must exist before the diagram shows anything meaningful; features are optional but make the diagram useful
- **Content Language**: Read `portfolio.json` in the project root. If a `language` field is present, communicate with the user in that language. Technical terms, skill names, and CLI commands remain in English.
- Refer to `$CLAUDE_PLUGIN_ROOT/skills/portfolio-setup/references/data-model.md` for complete entity schemas

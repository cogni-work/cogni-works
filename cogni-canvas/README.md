# cogni-canvas

Lean Canvas authoring and refinement for Claude Code. Guides users through creating business model hypotheses from scratch or iteratively improving existing canvases with section-by-section critique, coherence checking, and version tracking.

## Skills

| Skill | Trigger | Purpose |
|---|---|---|
| `canvas-create` | `/cogni-canvas:canvas-create` | Guided Q&A to build a new Lean Canvas from scratch |
| `canvas-refine` | `/cogni-canvas:canvas-refine <path>` | Critique and improve an existing canvas |
| `canvas-stress-test` | `/cogni-canvas:canvas-stress-test <path>` | Multi-persona stress test (investor, customer, technical, operations) |

## Canvas Format

Canvases are markdown files with YAML frontmatter tracking version, dates, and per-section status (`filled` / `draft` / `unfilled`). The 9 standard Lean Canvas sections are followed by an evolution log that records what changed and why across versions.

## Shared References

Both skills share reference material at the plugin root:

- `references/canvas-format.md` — file format spec, frontmatter schema, versioning rules
- `references/lean-canvas-sections.md` — quality criteria, common pitfalls, and guiding questions for all 9 sections

## Integration

- **Stress-test**: Run `canvas-stress-test` to get multi-perspective feedback from investor, customer, technical, and operations viewpoints before committing resources
- **Portfolio extraction**: Use `cogni-portfolio:portfolio-canvas` to extract portfolio entities (products, features, markets) from the canvas for downstream messaging and sales workflows
- **Validation**: Use `cogni-portfolio:markets` (TAM/SAM/SOM) and `cogni-portfolio:compete` (competitive landscape) to validate canvas assumptions with real data

## License

AGPL-3.0-only

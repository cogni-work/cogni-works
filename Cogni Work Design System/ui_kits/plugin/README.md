# Plugin Workspace UI Kit

A three-pane workspace view for the insight-wave plugin ecosystem — the user-facing "app" surface that sits on top of Claude Code. This is a conceptual recreation, not a 1:1 clone of Claude Code itself (which isn't branded cogni-work).

## Layout

| Pane | File | Role |
|---|---|---|
| Left — 320px | `Sidebar.jsx` | Dark workspace switcher, 10 installed plugins, health link |
| Center — fluid | `PluginDetail.jsx` | Selected plugin overview: stats, Why Change arc progress, outputs, pipeline position |
| Right — 380px | `RunPanel.jsx` | Dark terminal-style activity log with streaming lines |

Styles in `plugin.css`; shared button/eyebrow primitives come from `../website/website.css`.

## Notable patterns demonstrated

- **Dark-light-dark triptych** — sidebar + run panel dark (`#111`), detail centered on warm white. Matches the deck's band rhythm.
- **Four-step arc** — Why Change → Why Now → Why You → Why Pay, states: `done · active · pending`, chartreuse ring on the active dot.
- **Mono numerals** — plugin counts, timings, costs use JetBrains Mono exclusively.
- **Accent-as-signal** — chartreuse marks streaming state, completed arc steps, selected plugin category, and the phases-complete chip.
- **No icons** in chrome — plugin rows are purely typographic (slug + category + skill·agent counts), matching the brand's restraint.

## Interactions

- Click any plugin in the sidebar to select (UI highlight updates; detail copy is static for this mock).
- Run panel auto-streams lines every 900ms until all 11 log entries appear, then idles with a blinking cursor.

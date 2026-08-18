# Speaker Notes Panel

The presentation includes a toggleable speaker notes panel that displays the
presentation-brief's Speaker-Notes content in a structured, readable format.

## Toggle

- Press `S` to show/hide the notes panel
- Click the hamburger button in bottom-right controls
- Press `Escape` to close if open

## Panel Design

- Fixed at bottom of viewport
- Max height: 45vh (scrollable if content exceeds)
- Dark semi-transparent background (rgba(17,17,17,0.97)) with backdrop blur
- Accent-colored top border (2px)
- Slides up from bottom with smooth 0.4s cubic-bezier transition

## Content Parsing

The Speaker-Notes field from the presentation-brief follows this format:

```
Speaker-Notes: |
  >> WAS SIE SAGEN
  [Einstieg]: "Opening line that sets the frame"
  [Kernaussage]: "Key message to emphasize"
  [Überleitung]: "Bridge to next slide"

  >> WAS SIE WISSEN MÜSSEN
  - Q: "Likely question from audience?"
    A: "Your prepared answer"
  - Internal context point
  - Source: [Citation Title](url)
```

The Python script parses this into structured HTML:

| Input Pattern | HTML Output |
|--------------|-------------|
| `>> SECTION HEADER` | `<h4 class="notes-section">` with accent left-border |
| `[Tag]: "text"` | `<p class="notes-tagged">` with bold tag prefix |
| `- bullet` | `<li>` inside `<ul class="notes-bullets">` |
| Regular text | `<p>` |

## Supported Tags

From the presentation-brief Speaker-Notes format:
- `[Opening]` / `[Einstieg]` — opening line
- `[Key point]` / `[Kernaussage]` — key message
- `[Pause]` — delivery pause marker
- `[Emphasis]` / `[Betonung]` — emphasis marker
- `[Transition]` / `[Überleitung]` — bridge to next slide
- `[Energy]` / `[Energie]` — energy shift
- `[Caution]` / `[Vorsicht]` — caution marker
- `[Provoke]` / `[Provokation]` — provocation marker

## Print Mode

In print mode (`@media print`), the notes panel:
- Renders inline (static position, no transform)
- Uses light background (#f5f5f5) with dark text
- Appears after each slide's content
- Page-break-inside: avoid (keeps notes with their slide)

## Per-Slide Notes Data

Notes are stored in hidden `<template class="slide-notes-data">` elements,
one per slide. JavaScript swaps the active notes content when navigating.
Slides without speaker notes show a muted italic placeholder.

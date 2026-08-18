# Slide Navigation & Transitions

The HTML presentation includes a complete navigation system with keyboard, mouse, touch,
and button controls. All implemented in the Python generator's JavaScript output.

## Keyboard Shortcuts

| Key | Action |
|-----|--------|
| Arrow Right / Down / Space / PageDown | Next slide |
| Arrow Left / Up / PageUp | Previous slide |
| Home | First slide |
| End | Last slide |
| S | Toggle speaker notes panel |
| F | Toggle fullscreen |
| ? or H | Show keyboard help overlay |
| Escape | Close notes panel or help overlay |

## Mouse Navigation

- Click right half of screen: next slide
- Click left half of screen: previous slide
- Links, buttons, and the notes panel are excluded from click navigation

## Touch Navigation

- Swipe left: next slide
- Swipe right: previous slide
- Threshold: 50px minimum swipe distance

## Navigation Controls

Bottom-right corner shows:
- Previous button (arrow left)
- Slide counter: "3 / 12" (tabular-nums font variant)
- Next button (arrow right)
- Notes toggle button (hamburger icon)
- Help button (?)

Controls have glass-morphism styling (white background with blur, rounded).
Hover state: accent color background with scale bump.

## Progress Bar

Thin 3px accent-colored bar at the very top of the viewport.
Width = `(current + 1) / total * 100%`.
Smooth transition on width change (0.4s cubic-bezier).

## Transitions

Three modes configured via `--transition` parameter:

### fade (default)
- Slides have `opacity: 0` by default
- Active slide gets `opacity: 1`
- Transition: 0.5s cubic-bezier(0.4, 0, 0.2, 1)

### slide
- Slides start with `opacity: 0; transform: translateX(60px)`
- Active slide: `opacity: 1; transform: translateX(0)`
- Exiting slide: `translateX(-60px)`
- Transition: 0.5s cubic-bezier

### none
- Instant switch (opacity only, no animation)

## Fullscreen

The `F` key triggers `document.documentElement.requestFullscreen()`.
Works in all modern browsers. Gracefully fails if blocked.

## Aspect Ratio

The slide content is constrained to the configured aspect ratio (16:9 or 4:3) using:
```css
width: min(100vw, {max_width_from_height});
height: min(100vh, {max_height_from_width});
aspect-ratio: {ratio};
```

This ensures slides look correct on any viewport, from ultrawide monitors to projectors.

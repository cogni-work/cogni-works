# Website UI Kit — cogni-work.ai

Pixel-hinted recreation of the marketing site for cogni-work.ai, the services + marketplace layer over the open-source **insight-wave** plugin ecosystem.

## Screens & components

`index.html` renders the single top-level marketing page, composed of:

| Component | File | Role |
|---|---|---|
| `Nav` | `Nav.jsx` | Dark sticky top nav, wordmark + links + sign-in + primary CTA |
| `Hero` | `Hero.jsx` | Full-bleed dark hero with chartreuse-grid texture, H1, lede, CTA pair, 4-stat row |
| `CapabilitySection` | `CapabilitySection.jsx` | 3×2 grid of capability cards; one dark "highlight" variant |
| `MetricsBand` | `MetricsBand.jsx` | Dark section with three hero metrics (3.2×, 47%, 5h) |
| `AudienceTabs` | `AudienceTabs.jsx` | Interactive tabs: Consulting / Sales / Marketing |
| `CTAFooter` | `CTAFooter.jsx` | Dark CTA band → warm-grey footer with 4 columns |

Shared styles live in `website.css` and reference tokens from `../../colors_and_type.css`.

## Interaction surface

- Audience tabs — click to swap panel content; active tab gets chartreuse underline.
- All CTAs, links, and nav items have live hover/active states.
- No routing — it's a single scrollable marketing page.

## Faithful to the brand

- Dark `#111` navigation and alternating dark/light content bands match the deck's "firmitas · utilitas · venustas" rhythm.
- Accent `#C8E62E` appears only on: brand hyphen, H1 single-word highlight, primary CTAs, stat numerals, check marks, tab underline, eyebrow accent.
- No gradients, no emoji, no decorative illustrations. DM Sans + JetBrains Mono only.

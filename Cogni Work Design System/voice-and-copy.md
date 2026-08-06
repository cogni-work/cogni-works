# Voice & Copy Guidelines

> *Firmitas · Utilitas · Venustas* — restrained boldness applied to language. The chartreuse is loud, so everything we write stays quiet.

Cogni Work writes like a senior consultant who has nothing to prove: short clauses, concrete verbs, real numbers, no theatre. This document is the canonical reference for anyone writing UI copy, marketing pages, decks, reports, or product surfaces in the brand.

---

## 1. Voice in five lines

| Trait | What it means | What it isn't |
|---|---|---|
| **Executive** | One idea per sentence. Front-load the point. | Hedging, scene-setting, throat-clearing. |
| **Confident** | Make claims. Stand behind them with evidence. | Bragging, hype words, exclamation marks. |
| **Methodology-driven** | Show the framework (BLUF, SCQA, Pyramid). Cite. | Vague gesturing at "best practices". |
| **Quietly European** | Wolf-Schneider clarity. Latin motto. No US-bro slang. | Dry, academic, or cold. |
| **Restrained** | One accent colour, one signature claim per surface. | Maximalism, decoration, filler. |

**One-line vibe check:** *"We know what we're doing, without trying hard."*

---

## 2. The three-register system

Every Cogni Work surface uses **exactly three typographic registers** for prose. Each register has a fixed casing and a fixed job.

| Register | Casing | Font | Job | Example |
|---|---|---|---|---|
| **Eyebrow** | `MONO UPPERCASE` + 0.12em tracking | JetBrains Mono 500 | Label the section. 1–4 words. | `THE CHALLENGE` |
| **Header** | Title Case | DM Sans Bold | State the claim. 4–10 words. | `Knowledge Workers Deserve Better Tools` |
| **Body** | Sentence case | DM Sans Regular | Carry the argument. | `Professionals spend 60% of their day on low-value coordination.` |

Inline data (metrics, code, identifiers) uses **JetBrains Mono** as a fourth register, but it carries content, not prose, so it doesn't break the rule of three.

**Why three.** Three registers give a surface visible rhythm without ornament. If you find yourself wanting a fourth (italics, ALL-CAPS in body, decorative pull quotes), the surface is doing too much — cut, don't add.

---

## 3. Person & address

- **"You"** addresses the reader. Always. *"Your reps spend 2–3 days per opportunity on research."*
- **"We"** is Cogni Work — the team, the platform, the methodology. *"We return that time to the work that matters."*
- **Never "I"**. Cogni Work doesn't have a first-person singular. The brand speaks as a collective.
- **No "users"** in product copy. Use the role: *analyst, account exec, consultant, researcher*. "Users" is faceless.
- **No "customers"** on the marketing surface either — use *teams, firms, organizations*. "Customer" is for the billing page.

---

## 4. Sentence & paragraph mechanics

| Constraint | Target | Hard limit |
|---|---|---|
| Sentence length | 15–20 words | 28 words |
| Paragraph length | 3–5 sentences | 7 sentences |
| Words per clause | 8–12 | 16 |
| Reading level | 9th–11th grade | 13th |

**Cut these phrases on sight:**
- *"In today's fast-paced world…"* — no scene-setting
- *"It's important to note that…"* — front-load the note
- *"We're excited to announce…"* — get to the announcement
- *"At Cogni Work, we believe…"* — show, don't preach
- *"Leverage", "synergy", "best-in-class", "world-class"* — bingo words
- *"Empower", "unlock", "transform", "revolutionize"* — verb inflation

**Replace with:** the concrete verb that describes what actually happens. *"Cuts deck production from 3 days to 4 hours."*

---

## 5. Numbers are heroes

A Cogni Work surface earns its weight in numbers. Decks, dashboards, and reports are built around metric callouts; marketing pages anchor every claim to one.

**Formatting rules:**

- Numerals over words for any value ≥ 2. *"3.2× faster"*, not *"three-point-two times faster"*.
- One decimal max for multipliers and ratios. *"3.2×"*, not *"3.18×"*.
- Whole percentages where honest. *"47%"*, not *"47.3%"*.
- Always pair the number with a plain-language label set in **mono micro** beneath it.
- Use `×` (multiplication sign), not `x`. Use `%`, not `percent`. Use `–` (en dash) for ranges.

**The hero pattern:**

```
60%                          ← DM Sans Bold, display size, on warm white
─────────────────────────
OF THEIR DAY ON COORDINATION ← JetBrains Mono 11/0.12em, muted
```

Three heroes per surface, maximum. More than three and they stop being heroes.

**Grounding.** Every number ships with a source — a footnote, a citation, an inline `[source]` link, or a quality gate. *We do not invent statistics.* If you can't cite it, soften it (*"most"*, *"a majority of"*) or cut it.

---

## 6. Frameworks

Cogni Work writing is structured. Pick one of three frameworks per surface and commit to it.

### BLUF — Bottom Line Up Front
Lead with the conclusion. Use for: dashboards, status updates, alerts, exec summaries, page hero subheads.

> *"Pipeline coverage dropped to 2.4× this quarter. Three deals slipped on missing case studies."*

### Pyramid — Claim → Support → Detail
State the claim, give three supports, then evidence. Use for: capability pages, product narratives, proposal sections, deck argument slides.

> **Claim:** Cogni Work returns 5 hours per analyst per week.
> **Supports:** Research drafted in 15 min · Decks generated from brief · Citations checked automatically.
> **Detail:** Methodology, sources, sample artefacts.

### SCQA — Situation, Complication, Question, Answer
Set the stage, introduce the tension, ask the question the reader is already thinking, then answer it. Use for: pitch decks, thought-leadership reports, longform.

> **S:** Knowledge teams have more data than ever.
> **C:** Most of it never reaches the deck.
> **Q:** What if the deck wrote itself from the research?
> **A:** Cogni Work.

Pick one. Don't mix. The framework is the spine — readers feel it even when they can't name it.

---

## 7. Anatomy of a copy block

The canonical Cogni Work content block is five elements deep. Use this on hero sections, deck slides, capability cards, and report sections.

```
EYEBROW          MONO UPPERCASE, 1–4 words            ← section label
Header           Title Case, 4–10 words               ← the claim
Subhead          Sentence case, ≤ 20 words            ← one-line support
Body             1–3 short paragraphs                 ← the argument
CTA              Title Case verb phrase, ≤ 4 words    ← what to do next
```

Not every block needs all five. Cut from the bottom (no CTA) or the middle (no subhead). Never cut the eyebrow — the eyebrow is the rhythm.

**Worked example:**

```
THE CHALLENGE
Knowledge Workers Deserve Better Tools
Coordination eats the day; the work that matters waits.

Professionals spend 60% of their day on low-value coordination —
emails, status updates, and searching for information across
siloed tools. Cogni Work returns that time to the work that matters.

Get Started →
```

---

## 8. Microcopy

Small surfaces. Big impact on perceived quality.

### Buttons & CTAs
- **Title Case**, verb-led, **≤ 4 words**. *"Get Started"*, *"Book a Walkthrough"*, *"Download the Brief"*.
- One primary CTA per surface. The chartreuse button is precious.
- Never *"Click here"*, *"Learn more"* (without an object), *"Submit"* (use the verb that describes what submit does — *"Send Request"*).
- Arrows: trailing `→` on text links and ghost CTAs; never on filled chartreuse buttons.

### Form labels & helpers
- Labels in **sentence case**. *"Email address"*, not *"Email Address"* and not *"EMAIL"*.
- Helper text is one sentence, optional, never ends with a period.
- Required marker is a chartreuse `*` after the label. No *"(required)"* tail.
- Placeholders show **format**, not instruction. *"name@firm.com"*, not *"Enter your email"*.

### Errors
- State the problem, then the fix. **No blame, no apology.**
- Body voice. Sentence case. Single sentence preferred.
- *"This email is already on the list — sign in instead."*
- ❌ *"Oops! Something went wrong. Please try again."* — no slang, no apology, no advice without specifics.

### Empty states
- One sentence describing the state, one sentence describing the next action, one primary CTA.
- Never *"Nothing to see here"*. State what will appear once it does.
- *"No runs yet. Start a plugin to see its history here. **Browse Plugins →**"*

### Success states
- Confirm the action in the past tense. Show the object.
- *"Brief sent to 3 reviewers."*
- No celebratory copy. No emoji (ever). No *"Awesome!"*, *"Great!"*, *"Boom!"*.

### Loading & progress
- Use mono micro for system status. *"GENERATING DECK · 4 OF 7 SLIDES"*.
- Never anthropomorphize. No *"Hang tight, we're working on it!"*.

### Tooltips
- ≤ 12 words. Sentence case. No period.
- Explain *what*, not *why*. The why belongs in the body.

---

## 9. Do / Don't — fast rewrites

| ❌ Don't | ✅ Do | Why |
|---|---|---|
| *We're excited to launch our new AI-powered assistant!* | *Cogni Work is open. Today.* | No throat-clearing. No exclamation. |
| *Empowering teams to unlock their full potential.* | *Cuts research time from 3 days to 4 hours.* | Concrete verb. Real number. |
| *Our world-class platform leverages cutting-edge AI…* | *Fourteen open-source plugins. One workspace.* | No bingo words. Show the shape. |
| *Click here to learn more about our solutions.* | *Read the methodology →* | Verb-led, specific object. |
| *Oops! Something went wrong. Please try again later.* | *Couldn't reach the server. Retry in a moment.* | State the cause. Skip the apology. |
| *Welcome aboard! 🎉 Let's get you set up.* | *You're in. Three steps to your first run.* | No celebration, no emoji. |
| *We believe knowledge workers deserve better tools.* | *Knowledge workers deserve better tools.* | Drop the throat-clearing. The claim is stronger alone. |
| *Up to 60% reduction in administrative overhead.* | *60% of their day, returned.* | Concrete and human. *Up to* is hedging. |

---

## 10. Punctuation & symbols

- **Em dash (`—`)** — used sparingly, for genuine asides. Surrounded by spaces. Two per paragraph maximum.
- **En dash (`–`)** — number ranges only. *"15–20 words"*, *"DE/EN"* (slash, not dash, for either/or).
- **Middle dot (`·`)** — separator in taglines and metadata. *"Firmitas · Utilitas · Venustas"*, *"4 min read · Methodology"*.
- **Arrow (`→`)** — trailing on links and ghost CTAs. Never decorative. Never `>`.
- **Exclamation mark** — banned in body, headers, eyebrows. Allowed in **one** place: the closing CTA on a deck (e.g. *"Ready to work smarter?"* — no, even that uses a question mark). Honestly: just don't.
- **Question marks** — fine, but each one must be a real question the reader is asking.
- **Quotes** — curly (`"…"`), never straight. Single curlies (`'…'`) for nested quotes only.
- **Ampersand (`&`)** — allowed in eyebrows and headers when space-constrained (*"Voice & Copy"*). Spell out *and* in body.
- **Slash (`/`)** — pairs and either/or. *"DE/EN"*, *"copy/paste"*. Never as a comma substitute.
- **No emoji.** Ever. Not in copy, not in commits, not in Slack-tone marketing.

---

## 11. Bilingual — EN / DE

Cogni Work ships English-first; the platform supports German. When writing German, follow **Wolf Schneider**'s school: short sentences, concrete verbs, Anglicisms only where the German word is genuinely worse.

| Principle | English | German |
|---|---|---|
| Verb up front | *Cogni Work cuts deck time by 60%.* | *Cogni Work verkürzt die Deckerstellung um 60 %.* |
| Concrete over abstract | *Drafted in 15 minutes.* | *In 15 Minuten entworfen.* |
| No nominal style | *Decks generate from briefs.* | *Decks entstehen aus Briefings.* (not *"Die Erstellung von Decks erfolgt aus Briefings"*) |
| Numbers in figures | *60% of their day* | *60 % ihres Tages* (space before `%` in DE) |

**Latin motto stays Latin** in both languages: *Firmitas · Utilitas · Venustas*.

Never machine-translate marketing copy. Decks may be machine-drafted, then revised by a native speaker. Mark untranslated strings with a `// TODO(de)` comment in code, never with placeholder German.

---

## 12. Vocabulary — words we use, words we cut

### Use
*methodology, framework, claim, evidence, ground (vb.), cite, brief, deliverable, knowledge worker, analyst, account exec, consultant, researcher, workspace, plugin, run, surface, anchor, register, accent, restraint*

### Cut
*leverage, synergy, empower, unlock, transform, revolutionize, disrupt, robust, seamless, cutting-edge, world-class, best-in-class, game-changer, journey, ecosystem (use *"platform"*), solution (use what it is), AI-powered (say what it does), user (use the role)*

### Use with care
*AI* — fine as a noun, never as a verb or hype prefix. Say *"the model"* or name the capability (*"the brief generator"*) when you can.
*Platform* — yes, but pair with a concrete object. *"The plugin platform"*, *"the research platform"*.
*Open-source* — hyphenated as a compound modifier (*"open-source ecosystem"*), unhyphenated as a predicate (*"the plugins are open source"*).

---

## 13. Naming & signatures

- **Brand name** is always two words, mixed case: **Cogni Work**. Not *CogniWork*, not *cogni-work* (that's the domain), not *COGNI WORK*.
- **Domain** is `cogni-work.ai` — lowercase, hyphenated, set in DM Sans regular weight in body copy.
- **Wordmark** is `cogni` + chartreuse hyphen + `work` + chartreuse `.ai`, DM Sans Bold, `-0.02em` tracking. Always rendered, never typed.
- **Tagline** is `Firmitas · Utilitas · Venustas` — Latin, middle-dot separated, no italics. Use verbatim.
- **Plugin names** are lowercase, hyphenated: *cogni-copywriting, cogni-portfolio, insight-wave*. Treat as proper nouns; don't expand to title case in prose.
- **Product capitalization in body:** *Cogni Work* (the brand), *insight-wave* (the ecosystem), *the plugin* (a single plugin in context).

---

## 14. Voice across surfaces

Different surfaces, same voice — different density.

| Surface | Density | Defining move |
|---|---|---|
| **Deck title slide** | One eyebrow, one header, one Latin tagline. | The header is the whole argument. |
| **Deck body slide** | Eyebrow + Title Case header + one hero number + one-line caption. | Numbers are heroes. |
| **Marketing hero** | Eyebrow + header + 1–2 sentence subhead + one CTA. | One CTA, full stop. |
| **Capability page** | Pyramid: claim, three supports, evidence. | Three supports — not four, not two. |
| **Dashboard** | Mono micro everywhere. Status in past tense. | No prose. Labels and numbers. |
| **Report / research** | SCQA. Inline citations. Methodology footer. | Cite or cut. |
| **Email** | First line is the BLUF. No greeting filler. | "Two things before Friday:" |
| **Product UI** | Sentence case. ≤ 12 words per string. | Verb-led microcopy. |

---

## 15. The 10-second checklist

Before any copy ships, read it once against this list. Cut what fails.

- [ ] One claim per sentence?
- [ ] Numbers, where present, are grounded?
- [ ] Headers Title Case, eyebrows MONO UPPERCASE, body sentence case?
- [ ] No emoji, no exclamation marks, no bingo words?
- [ ] One primary CTA?
- [ ] You / we / never I?
- [ ] Would a senior consultant nod, or wince?

If the last answer is *wince*, rewrite.

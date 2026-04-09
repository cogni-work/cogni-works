# Company Credo Story Arc

## Arc Metadata

**Arc ID:** `company-credo`
**Display Name:** Company Credo
**Display Name (German):** Unternehmens-Credo

**Elements (Ordered):**
1. Mission: Why We Exist
2. Conviction: What We Believe
3. Credibility: How You Can Trust Us
4. Promise: What You Can Expect

**Elements (German):**
1. Mission: Warum es uns gibt
2. Überzeugung: Woran wir glauben
3. Glaubwürdigkeit: Warum Sie uns vertrauen können
4. Versprechen: Was Sie erwarten können

## Word Proportions

Section lengths are expressed as proportions of the total target length. Default total: 1,400 words (About pages are typically shorter than pitches — buyers skim them before deciding whether to dig into capabilities). To compute word ranges for a given `--target-length T`: apply +/-15% band to get `[T*0.85, T*1.15]`, then multiply each proportion.

| Element | English Header | German Header | Proportion | Default Range (T=1400) |
|---------|----------------|---------------|-----------|------------------------|
| Hook | *(Founding lens)* | *(Gründungsbild)* | 10% | 119-161 |
| Mission | Mission: Why We Exist | Mission: Warum es uns gibt | 24% | 286-386 |
| Conviction | Conviction: What We Believe | Überzeugung: Woran wir glauben | 22% | 262-354 |
| Credibility | Credibility: How You Can Trust Us | Glaubwürdigkeit: Warum Sie uns vertrauen können | 26% | 310-418 |
| Promise | Promise: What You Can Expect | Versprechen: Was Sie erwarten können | 18% | 214-290 |

**Proportions sum to 100%.** Default total: 1,400 words (customizable via `--target-length`). Tolerance: +/-10% of computed section midpoint.

## Detection Configuration

### Content Type Mapping

This arc is selected when:
- `content_type: "company-credo"`
- `content_type: "about-us"`

### Content Analysis Keywords

Keywords: "about us", "our mission", "why we exist", "what we believe", "our story", "company values", "our credo", "who we are", "why us"

### Detection Threshold

Keyword density >= 12%

## Use Cases

**Best For:**
- Website "About Us" pages (the most common use)
- Company introductions at the start of proposals and sales decks
- Investor and partner relationship pages where the buyer is choosing the company before any specific offering
- Brand identity documents that need to read as a narrative, not a brochure

**Typical Input Sources:**
- `portfolio.json` — company_description, positioning, mission/vision statements
- Cross-cutting themes from all `propositions/*.json` — the MEANS layer reveals what the company believes about value
- `customers/*.json` — named logos, testimonials, case references (if available)
- Recurring differentiation claims from `competitors/*.json` — reveal what the company stands for *against*
- `cogni-claims/claims.json` — any verified credibility fact (certifications, awards, partnerships)

**Not Suitable For:**
- Capability documentation (use `corporate-visions` scoped to a capability)
- Portfolio overviews that need to showcase specific solutions (use `jtbd-portfolio`)
- Deal-specific proposals (use cogni-sales `/why-change`)
- Any content whose governing question is "what does this solution do" rather than "who is this company"

## Element Definitions

### Element 1: Mission (Why We Exist)

**Purpose:**
Answer the buyer's first unasked question: "Why does this company exist in the world?" The Mission element names the problem the company takes personally — the thing that made someone sit down and start the company rather than doing something else.

Mission is **not** a list of services and **not** a company history. It is a belief about the world that the company is unwilling to let stand, combined with an assertion that the company is uniquely placed to do something about it.

**Source Content:**
- `portfolio.json` company_description, positioning, mission/vision (primary)
- Cross-cutting MEANS statements across propositions (secondary — if the same theme of meaning recurs across 4+ propositions, that theme is part of the mission)
- Market context (the industry problem the company is pointing at)

**Transformation Approach:**
1. Find the recurring verb in the company's proposition MEANS statements ("so that buyers can finally…", "so that teams stop…"). That recurring verb is close to the mission.
2. Name the problem the company refuses to accept as normal.
3. State the company's theory of why the problem persists and why the company is placed to change that.
4. Keep it first-person ("we") — this is the one element in the customer-narrative suite where first-person voice is required rather than avoided.

**Key Techniques:**
- Contrast Structure: "The industry treats X as fixed. We don't."
- Forcing Functions: name the external pressure that makes the mission urgent now rather than five years ago.
- Buyer-adjacent framing: Mission reads like *the buyer's problem*, described by someone who has decided to do something about it.

**Constraints:**
- Mission must be first-person plural ("we").
- Mission MUST NOT list products, features, or services. It is a belief, not a catalog.
- Mission must take a position — if every company in the industry could sign the same paragraph, it's too generic.

**Pattern Reference:** `mission-patterns.md`

---

### Element 2: Conviction (What We Believe)

**Purpose:**
Translate the mission into 3–4 non-negotiable convictions that shape how the company designs, sells, and delivers. Conviction is where the buyer starts to understand *how the company thinks*, which is often what they're actually evaluating on an About page — not capabilities, but judgment.

**Source Content:**
- Recurring themes in propositions `evidence[]` (what claims the company repeatedly stands behind)
- Differentiation claims from `competitors/*.json` (what the company says it does differently — reverse-engineer the belief behind the difference)
- Cross-cutting MEANS themes that don't fit in Mission
- Any methodology, framework, or principle the company names publicly (visible in `portfolio.json.positioning` or the company description)

**Transformation Approach:**
1. Extract 3–4 convictions — each stated as a sentence that begins with a verb of belief ("We believe…", "We refuse…", "We insist…"). In German: "Wir glauben…", "Wir weigern uns…".
2. Each conviction must be something a competitor could plausibly disagree with. If everyone nods, cut it.
3. Pair each conviction with the consequence for the buyer — what the buyer experiences differently because the company holds this belief.

**Key Techniques:**
- Disagreement test: each conviction must be something at least one serious competitor does not believe.
- Consequence binding: "We believe X → which is why you will see Y when you work with us."
- Buyer-visible outcomes: convictions manifest in how the work feels, not in abstract values.

**Constraints:**
- 3–4 convictions (fewer than 3 is thin; more than 4 reads as a values wall).
- Each conviction pairs a belief sentence with a buyer-visible consequence.
- No generic corporate values ("we value integrity", "we put customers first") — these fail the disagreement test.

**Pattern Reference:** `conviction-patterns.md`

---

### Element 3: Credibility (How You Can Trust Us)

**Purpose:**
Give the buyer permission to believe the Mission and Conviction by showing receipts. Credibility is the element that most often determines whether a buyer continues into the capability pages — it is the moment where belief hardens into willingness to proceed.

**Source Content:**
- `evidence[]` arrays from propositions (primary — verified external claims)
- `customers/*.json` named accounts, testimonials, case references (secondary)
- `cogni-claims/claims.json` verified facts (tertiary — any claim with `status: verified`)
- Certifications, partnerships, awards visible in `portfolio.json` or company context

**Transformation Approach:**
1. Pick 4–6 credibility items across the dimensions the buyer cares about: track record (years, customers, projects shipped), external validation (certifications, partner status, awards), recognizable logos (if used with permission), quantified outcomes (aggregated across the portfolio), and verifiable expertise (publications, specific depth markers).
2. Group by dimension so the buyer can scan: ‹Track record›, ‹Validation›, ‹Outcomes›, ‹Expertise›.
3. Cite every quantitative claim. Uncited credibility is anti-credibility.

**Key Techniques:**
- Number Plays: specific quantities beat round numbers ("47 enterprise customers" > "dozens of customers").
- External validation: third-party sources carry more weight than self-reported claims.
- Dimensional coverage: a single dimension (e.g., only logos) reads as thin; multiple dimensions compound.

**Constraints:**
- Every quantitative claim has a citation (from `evidence[].source_url` or `claims.json`).
- Named accounts appear ONLY if the customer entity explicitly allows disclosure (check `customers/{market}.json` for a permission marker; if ambiguous, describe rather than name).
- Credibility items must be recent enough to be plausible — flag anything older than 3 years.
- No credibility inflation: "trusted by industry leaders" without names or numbers is worse than no claim at all.

**Pattern Reference:** `credibility-patterns.md`

---

### Element 4: Promise (What You Can Expect)

**Purpose:**
Close the About page by stating — in plain language — what the buyer will experience if they choose to work with the company. Promise is the handshake: a short, specific commitment that makes the rest of the website feel like a coherent offer rather than a set of loose capabilities.

**Source Content:**
- Cross-cutting engagement patterns from `solutions/*.json` (the repeating phases/cadence the company uses)
- Product `maturity` distribution (what the company commits to *today* vs. what's on the roadmap — the Promise must only commit to things in `standard`/`launch`/`preview` mode)
- Buyer-facing language from proposition DOES statements

**Transformation Approach:**
1. Identify 3 things the buyer will experience consistently regardless of which capability they hire the company for — these are the promise items.
2. Phrase each as a direct commitment ("You will…" / "Sie werden…"). No hedging.
3. End with a single, concrete invitation that links to the next step the buyer should take on the website (usually the Capabilities index or a specific persona page), not a generic "contact us".

**Key Techniques:**
- You-Phrasing (mandatory): every promise item is addressed directly to the buyer.
- Maturity discipline: Promise MUST NOT commit to anything in `announce` mode. If a promise would only be true once a concept product ships, it belongs on the roadmap, not the About page.
- Single invitation: one next step, not a menu.

**Constraints:**
- 3 promise items (fewer feels thin, more feels like a catalog).
- Every item is a You-Phrased commitment.
- Promise items must be true across the current portfolio — if a promise only holds for one product, it's a capability claim, not a company promise.
- The final invitation is a single link or CTA, not a list.

**Pattern Reference:** `promise-patterns.md`

## Narrative Flow

### Hook Construction (Founding Lens)

**Approach:**
Open with one observation about the industry or the buyer's world that makes the company's existence feel necessary. The Hook is a framing device — it positions the reader inside the problem so that the Mission lands as a response, not an announcement.

**Pattern:**
```markdown
[Specific observation about the buyer's world] + [Question or tension that the Mission will answer]

Example:
"Every European manufacturer we talk to is running three digital transformation programs in parallel — and none of them are talking to each other. Somewhere in the gap between those programs, the actual operational improvements get lost."
```

**Source:** Strongest cross-cutting observation from customer pain points or market descriptions.

**Word Target:** 10% of target length.

---

### Element Transitions

**Hook → Mission:**
- Hook sets the scene; Mission reveals the company's response to the scene.
- **Transition pattern:** "That gap is what we were started to close." / "Diese Lücke zu schließen — dafür gibt es uns."

**Mission → Conviction:**
- Mission is a single belief; Convictions are the 3–4 judgment calls that belief implies.
- **Transition pattern:** "A mission like that only works if you hold a few things as non-negotiable."

**Conviction → Credibility:**
- Convictions are claims; Credibility is evidence.
- **Transition pattern:** "Convictions are cheap. Here is what we can show for them."

**Credibility → Promise:**
- Credibility is the past; Promise is the commitment going forward.
- **Transition pattern:** "If any of this resonates, here is what working with us actually looks like."

---

### Closing Pattern

**Final Sentence:**
A single invitation that points to the next page the buyer should read. It should name the page by its buyer-facing function, not its URL.

**Examples:**
- "If you want to see what we actually do for your role, the capabilities page is where to go next."
- "Wenn Sie sehen wollen, was wir für Ihre Rolle konkret bauen, starten Sie am besten auf unserer Capabilities-Seite."

## Citation Requirements

### Citation Density

**Target:** 8–15 total citations across the narrative (fewer than portfolio-native arcs — About pages are belief-led, not evidence-dense).
**Ratio:** Approximately 1 citation per 100–150 words.

### Citation Distribution

**Hook:** 1 citation (the grounding observation).
**Mission:** 1–2 citations (the industry problem the mission names).
**Conviction:** 2–3 citations (anything a serious reader might push back on).
**Credibility:** 4–7 citations (highest density — this element exists to back claims).
**Promise:** 0–1 citations (Promise is commitment, not evidence; cite only if a specific outcome is named).

### Required Citations

- Every quantitative credibility claim (MUST)
- Every named customer or external certification (MUST)
- Conviction statements that reference market conditions (MUST)
- Hook observation if it includes a number (MUST)

## Quality Gates

### Arc Completeness

- [ ] All 4 elements present (Mission, Conviction, Credibility, Promise)
- [ ] Hook present (within hook proportion of target)
- [ ] Word counts within computed proportional ranges (+/-10% tolerance)
- [ ] Smooth transitions between elements
- [ ] Final invitation points to a specific next page (not generic "contact us")

### Company-Credo Constraints

- [ ] **First-person Mission:** Mission uses "we" voice
- [ ] **Disagreement test:** Every Conviction is something a named competitor plausibly disagrees with
- [ ] **Consequence binding:** Every Conviction pairs belief with buyer-visible consequence
- [ ] **Cited Credibility:** Every quantitative Credibility claim has a citation
- [ ] **Maturity discipline:** No Promise item depends on `announce`-mode products
- [ ] **You-Phrased Promise:** Every Promise item uses direct "you" address
- [ ] **Single invitation:** Final invitation is one link, not a menu

### Evidence Quality

- [ ] Credibility contains at least 4 distinct items across ≥2 dimensions (track record, validation, outcomes, expertise)
- [ ] No "trusted by industry leaders" type claims without specifics
- [ ] Named accounts only appear with explicit permission markers in customer entities
- [ ] No credibility item older than 3 years without a "still applies" qualifier

### Narrative Coherence

- [ ] Hook → Mission → Conviction → Credibility → Promise builds a single argument
- [ ] Convictions trace back to the Mission (not unrelated values)
- [ ] Credibility backs specifically the Mission and Convictions (not random achievements)
- [ ] Promise is consistent with the portfolio's actual maturity state

## Common Pitfalls

### Mission Pitfalls

**Mission reads as a service list:**

:x: **Bad:** "We provide consulting, platform engineering, and managed services to European enterprises."

:white_check_mark: **Good:** "We believe the reason mid-sized European manufacturers are losing ground to vertically-integrated competitors isn't strategy — it's that their operational data never reaches the people making decisions. We exist to close that gap."

---

**Mission is too generic:**

:x: **Bad:** "We help companies succeed in the digital age."

Every company could sign this. It takes no position.

:white_check_mark: **Good:** "We are built on the assumption that most 'AI transformation' projects fail because the underlying data contracts were never negotiated. Our entire portfolio is designed to fix that, in that order."

### Conviction Pitfalls

**Generic corporate values:**

:x: **Bad:** "We value integrity, customer-centricity, and innovation."

These fail the disagreement test — no company says they don't value integrity.

:white_check_mark: **Good:** "We refuse to sell software before the buyer's data contracts are in place. This makes us slower than our competitors in the first 90 days of a deal. It also means fewer of our customers have to restart their program twelve months in."

### Credibility Pitfalls

**Unbacked credibility claims:**

:x: **Bad:** "Trusted by industry leaders across Europe."

:white_check_mark: **Good:** "47 enterprise deployments across Germany, Austria, and Switzerland since 2019<sup>[1]</sup>. ISO 27001 certified since 2021<sup>[2]</sup>. Our methodology has been cited in three published case studies from Fraunhofer IAO<sup>[3][4][5]</sup>."

### Promise Pitfalls

**Promising what you haven't shipped:**

:x: **Bad:** (When the autonomous-agent product is in `concept` mode) "You will have autonomous agents managing your operations end-to-end within 90 days."

:white_check_mark: **Good:** "You will see measurable operational KPIs within 90 days — grounded in what we ship today, not a roadmap promise."

---

**Generic invitation:**

:x: **Bad:** "Contact us to learn more."

:white_check_mark: **Good:** "If you're heading a B2B sales organization and any of this sounds like your quarter, the for-CROs page is where to go next."

## Version History

- **v1.0.0:** Initial Company Credo arc definition — built for the customer-narrative About page scope in portfolio-communicate.

## See Also

- `../arc-registry.md` — Master index of all story arcs
- `mission-patterns.md` — Mission framing patterns
- `conviction-patterns.md` — Conviction extraction and disagreement-test patterns
- `credibility-patterns.md` — Credibility dimension mapping and citation patterns
- `promise-patterns.md` — Promise commitment patterns and maturity discipline

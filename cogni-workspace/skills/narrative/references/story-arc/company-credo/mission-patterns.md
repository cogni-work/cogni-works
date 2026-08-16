# Mission: Why-We-Exist Patterns

## Element Purpose

State, in first-person plural, the problem the company refuses to accept as normal and the assertion that the company is placed to do something about it. Mission is a **belief with a verb**, not a service catalog.

**Word Target:** 24% of target length.

## Source Content Mapping

Extract from:
1. **Portfolio manifest** (primary source)
   - `portfolio.json` company_description, positioning, mission, vision
   - These fields often already contain a proto-mission — the job is to sharpen it, not invent one.
2. **Recurring MEANS themes** (secondary source)
   - Load all `propositions/*.json` and scan the MEANS field. If the same verb of meaning ("so that buyers can finally decide…", "so that teams stop firefighting…") recurs in 4+ propositions, that verb is part of the mission.
3. **Market framing** (context)
   - `markets/*.json` descriptions — reveal the industry problem the company is pointing at.

## Mission Extraction Patterns

### Pattern 1: The Refusal

**When to use:** The company is defined by something it will not accept — a broken pattern, a normalized failure mode, an industry shortcut.

**Structure:**
```markdown
Observation: "Most AI transformation projects fail within 18 months because the underlying data contracts were never negotiated."
   → Mission: "We refuse to sell AI software before the buyer's data contracts are in place. That discipline is the reason our portfolio exists."
```

**Why this works:** Named refusals are inherently position-taking. They pass the disagreement test automatically — some competitor is doing the opposite.

---

### Pattern 2: The Closed Gap

**When to use:** The company exists to close a gap that the industry has tolerated for years.

**Structure:**
```markdown
Gap: "Operational data never reaches the people making operational decisions in mid-sized European manufacturers."
   → Mission: "We exist to close the gap between operational data and operational decisions. Everything we build answers that one question."
```

**Why this works:** A single named gap organises every capability into one story. The reader understands the portfolio after one paragraph.

---

### Pattern 3: The Inherited Conviction

**When to use:** The company's founding is traceable to a specific moment, insight, or experience that the team carries into every engagement.

**Structure:**
```markdown
Origin: Founders spent years watching consultancy projects ship beautiful slides and no working software.
   → Mission: "We are built on the conviction that strategy without running software is a status report in a suit. We ship the thing."
```

**Why this works:** Origin-rooted missions feel authentic rather than aspirational. The reader can tell the difference.

---

### Pattern 4: The Reframed Category

**When to use:** The company rejects the way its category is typically sold and reframes it around a different outcome.

**Structure:**
```markdown
Category framing: "B2B marketing automation sells volume: more emails, more leads, more dashboards."
   → Mission: "We don't sell volume. We sell the reduction of attention demanded from your customers. That is the category we are building."
```

**Why this works:** Category reframing is the most ambitious Mission form — done well, it changes the buyer's frame of reference before you describe a single capability.

## Presentation Structure

### Opening: The Frame Shift

Start Mission with one sentence that shifts the reader's frame from "what does this company sell" to "what does this company believe":

```markdown
The reason we exist is narrower than our capability list suggests.
```

### Body: The Belief + The Verb

Present the belief in one short paragraph, then state what the company does about it in a second paragraph. Keep both first-person plural ("we").

```markdown
[Paragraph 1 — the belief:]
We believe [named problem] is solvable but has been tolerated because [why it persists]. [One sentence of evidence from market / customer pain points.]

[Paragraph 2 — the verb:]
We were started to [specific verb phrase that describes what the company does about the belief]. Everything in the portfolio is organised around that one sentence.
```

### Closing: Handoff to Conviction

Summarize Mission as a belief that implies convictions, then hand off:

```markdown
A mission like this only works if you hold a few things as non-negotiable. The next section names them.
```

## Techniques Checklist

### First-Person Discipline

- [ ] **Entire section uses "we" / "wir"**
  - Mission is the single element where first-person company voice is required rather than avoided.
  - Third-person Mission ("The company believes…") reads as a press release and kills authenticity.

### Position-Taking

- [ ] **Mission passes the disagreement test**
  - If a named competitor could sign the same Mission paragraph without flinching, it's too generic.
  - Ask: "What is the Mission explicitly *against*?" If nothing, rewrite.

### Contrast Structure

- [ ] **Industry default vs. company stance**
  - "The industry treats X as fixed. We don't."
  - "Most companies in this space believe Y. We believe Z."
  - Contrast creates the sense that the Mission is a choice, not a slogan.

### Forcing Functions

- [ ] **Why now, not five years ago**
  - Name the external pressure that makes the Mission urgent in the current moment.
  - Regulatory shifts, market tipping points, technology availability — any external change that made the problem newly solvable.

## Quality Checkpoints

### Content Requirements

- [ ] Mission is a belief with a verb, not a service list
- [ ] First-person plural ("we") throughout
- [ ] Takes a position that some competitor could plausibly disagree with
- [ ] Rooted in a specific problem named from market / customer data
- [ ] At least 1 citation grounding the named problem

### Structure Requirements

- [ ] Opening frame-shift sentence
- [ ] Belief paragraph (the problem + why it persists)
- [ ] Verb paragraph (what the company does about it)
- [ ] Handoff to Conviction
- [ ] Word count within proportional range (+/-10%)

## Common Mistakes

### Mistake 1: Mission as Service Catalog

**Bad:**
> We provide strategic consulting, data platform engineering, and managed analytics services to mid-sized European manufacturers. Our clients include leading names in automotive, chemicals, and industrial goods.

**Why it fails:** This is the "What" page, not the "Why we exist" page. The reader still doesn't know what the company believes.

**Good:**
> We believe the reason most mid-sized European manufacturers are losing ground to vertically integrated competitors isn't strategy — it's that their operational data never reaches the people making operational decisions. We exist to close that gap.

---

### Mistake 2: Third-Person Mission

**Bad:**
> Acme Analytics was founded in 2018 to help businesses make better decisions through data.

**Why it fails:** Third-person voice turns Mission into company history. History is fine on a timeline page; Mission needs to read as a current belief spoken by the company to the reader.

**Good:**
> We don't care about "better decisions through data." We care about one specific thing: that the data your factory is already generating gets to the shift supervisor before the shift ends. That sentence is the whole company.

## Language Variations

### German Adjustments

**First-person plural:** Use "wir" consistently. Avoid passive constructions that hide the subject.

```markdown
**Mission: Warum es uns gibt**

Wir glauben, dass der Grund, warum mittelständische europäische Hersteller an Boden verlieren, nicht in der Strategie liegt — sondern darin, dass operative Daten nie bei den Menschen ankommen, die operative Entscheidungen treffen. Wir sind angetreten, um genau diese Lücke zu schließen.
```

## Related Patterns

- See `conviction-patterns.md` for extracting the 3–4 judgment calls the Mission implies
- See `credibility-patterns.md` for backing Mission claims with evidence
- See `promise-patterns.md` for the handshake that closes the arc

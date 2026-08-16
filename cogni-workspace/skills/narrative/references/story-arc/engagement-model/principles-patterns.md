# Principles: Operating-Principles Patterns

## Element Purpose

Name 3–4 operating principles that shape every engagement regardless of capability or market. Principles answer the buyer's implicit question: "Before we talk about what you do, how do you work?"

**Word Target:** 22% of target length.

## Source Content Mapping

Extract from:
1. **Solution descriptions** (primary)
   - `solutions/*.json` — phrases like "proof-first", "phased", "outcome-locked", "contract-first" that recur across multiple solutions.
2. **Portfolio positioning** (secondary)
   - `portfolio.json.positioning` often names the company's methodology.
3. **Cross-cutting MEANS themes** (tertiary)
   - Principles often operationalise a Conviction from a parallel `company-credo` output.
4. **Published methodology names** (if present)
   - Any named framework the company has externalised is already a principle.

## Principle Extraction Patterns

### Pattern 1: The Recurring Delivery Phrase

**When to use:** The same delivery phrase appears in 3+ solution descriptions.

**Structure:**
```markdown
Recurring phrase: "proof-first" appears in 4 solutions.
   → Principle: "Proof before scale. Every engagement we run proves the outcome on a narrow slice of your operation before we touch the broader scope. The first 6–8 weeks of any engagement are dedicated to making one thing measurably better in one place."
```

**Why this works:** A recurring delivery phrase is a principle the company already uses internally — the work is externalising it into buyer language.

---

### Pattern 2: The Named Methodology

**When to use:** The company has a published methodology name that embodies one of its principles.

**Structure:**
```markdown
Published name: "Contract-First Integration" — appears in 3 solutions and the portfolio positioning.
   → Principle: "Contract before code. Contract-First Integration is our name for a simple discipline: we do not write software before the data contracts between business and IT are signed. This makes us slower than competitors in week 1. It is why our projects rarely restart in month 12."
```

**Why this works:** Named methodologies are principles the company has committed to publicly — citing them gives the About / How We Work story a through-line.

---

### Pattern 3: The Inherited Conviction

**When to use:** A `company-credo` output exists or is being written alongside, and one of its Convictions is operationally visible in every engagement.

**Structure:**
```markdown
Conviction: "We believe operational software should fail loudly, not silently."
   → Principle: "Loud failures by design. Every system we deploy is instrumented so that failures page a human within 90 seconds, even at the cost of occasional false alarms. You will see this the first week we deploy anything — some buyers find it noisy. We consider the noise a feature."
```

**Why this works:** Linking Principles to Convictions creates narrative coherence across the website's main pages.

---

### Pattern 4: The Contrast Principle

**When to use:** The strongest way to state a principle is by naming what it replaces in the industry default.

**Structure:**
```markdown
Industry default: Monthly status reports.
Company approach: Weekly working demos.
   → Principle: "Weekly working demos, no status reports. Every engagement delivers a working demo every Friday, starting in week 1. We do not produce monthly status reports. Executive updates come from watching a five-minute recording of the demo — the signal-to-noise ratio is higher and the time commitment is lower."
```

**Why this works:** Contrast makes Principles easy to understand and hard to forget. The buyer remembers the thing the company does *instead*.

## Presentation Structure

### Opening: The Four-Principle Frame

Start with a short transition from the Hook:

```markdown
Here are the four principles that shape how every engagement runs. They are operational, not aspirational — each one names something we do that most of our peers don't.
```

### Body: 3–4 Named Principles

```markdown
**Principle 1: [Headline in operational language]**
[One paragraph: what this principle looks like in practice + what it replaces in the industry default + 1 citation if grounded in portfolio data.]

**Principle 2: [Headline]**
[Paragraph.]

**Principle 3: [Headline]**
[Paragraph.]

**Principle 4 (optional): [Headline]**
[Paragraph.]
```

### Closing: Handoff to Process

```markdown
The next section shows what those principles look like in the shape of a typical engagement.
```

## Techniques Checklist

### Operational Framing (mandatory)

- [ ] **Every Principle names something the company does, not something it values**
  - "We always run weekly working demos" ✅ (operational)
  - "We value transparency" ❌ (value)
  - Test: can a buyer observe the principle in the first week of an engagement? If no, rewrite.

### Contrast Structure

- [ ] **Each Principle names what it replaces**
  - "Instead of monthly status reports, we run weekly demos."
  - "Instead of fixed-scope contracts, we timebox per outcome."
  - Contrast makes Principles memorable and position-taking.

### Traceability to Process

- [ ] **Each Principle is visible in the Process element below**
  - A buyer reading Process should see the Principles in action.
  - If a Principle cannot be pointed to in Process, it is a values statement in disguise.

### Number of Principles

- [ ] **Exactly 3 or 4**
  - Fewer than 3 feels thin.
  - More than 4 turns the page into a values wall.

## Quality Checkpoints

### Content Requirements

- [ ] 3–4 principles
- [ ] Each principle is operational (observable within the first week of an engagement)
- [ ] Each principle uses contrast structure where possible
- [ ] Each principle is traceable to the Process element below
- [ ] No generic values ("customer-centric", "quality-first")

### Structure Requirements

- [ ] Opening transition framing "4 operational principles"
- [ ] Named entries with headline + paragraph
- [ ] Closing transition to Process
- [ ] Word count within proportional range (+/-10%)

## Common Mistakes

### Mistake 1: Values Dressed as Principles

**Bad:**
> **Principle 1: Customer-Centric Delivery.**
> Our customers are at the heart of everything we do. We listen carefully, respond quickly, and deliver value.

**Why it fails:** Unobservable. Every company says this. It does not survive the "what will I see in week 1" test.

**Good:**
> **Principle 1: Weekly working demos, no status reports.**
> Every engagement delivers a working demo every Friday, starting in week 1. We do not produce monthly status reports — executive updates come from watching a five-minute recording of the demo. The signal-to-noise ratio is higher and the time commitment is lower. You will see your first demo in your second week with us.

---

### Mistake 2: Principle Without Contrast

**Bad:**
> **Principle 2: Phased Delivery.**
> We work in phases.

**Why it fails:** Every services company "works in phases". Without contrast, the principle says nothing.

**Good:**
> **Principle 2: Proof before scale.**
> We never expand scope until the previous scope has shipped a measurable outcome. Where most of our peers start a multi-quarter rollout after a 4-week discovery, we make one thing measurably better first — in production, not in a slide deck — before touching anything else.

## Language Variations

### German Adjustments

```markdown
**Prinzip 1: Wöchentliche funktionierende Demos — keine Statusberichte.**
Jedes Engagement liefert freitags einen funktionierenden Demo, beginnend in Woche 1. Wir erstellen keine monatlichen Statusberichte. Executive-Updates entstehen aus einer fünfminütigen Aufzeichnung des Demos — höheres Signal-Rausch-Verhältnis, weniger Zeitaufwand. Ihren ersten Demo sehen Sie in Woche 2.

**Prinzip 2: Beweis vor Skalierung.**
Wir erweitern niemals den Umfang, bevor der vorherige Umfang ein messbares Ergebnis geliefert hat. Während die meisten Mitbewerber nach einer 4-wöchigen Discovery mit einem mehrquartalsweiten Rollout beginnen, machen wir zuerst eine Sache messbar besser — in Produktion, nicht in Folien.
```

## Related Patterns

- See `process-patterns.md` for showing Principles in action
- See `partnership-patterns.md` for what Principles require from the buyer
- See `outcomes-patterns.md` for what Principles produce as results

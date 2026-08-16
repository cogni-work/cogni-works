# Conviction: What-We-Believe Patterns

## Element Purpose

Translate the Mission into 3–4 non-negotiable convictions — judgment calls the company holds that shape how it designs, sells, and delivers. Conviction is where the reader starts to understand *how the company thinks*, which is often what they are actually evaluating on an About page.

**Word Target:** 22% of target length.

## Source Content Mapping

Extract from:
1. **Evidence arrays across propositions** (primary)
   - `propositions/*.json` evidence fields — recurring claims the company stands behind reveal underlying beliefs.
2. **Differentiation claims from competitors** (secondary)
   - `competitors/*.json` — the way the company describes its difference from each competitor often reverse-engineers a conviction.
3. **Cross-cutting MEANS themes** (tertiary)
   - Scan MEANS fields for themes that didn't fit in the Mission paragraph but recur across multiple propositions.
4. **Publicly named methodology, principle, or framework** (if present)
   - Mentioned in `portfolio.json.positioning` or the company description — these are often externalised convictions.

## Conviction Extraction Patterns

### Pattern 1: Reverse-Engineer From Differentiation

**When to use:** The company's competitor comparisons reveal what it believes by showing what it refuses to do.

**Structure:**
```markdown
Competitor claim: "Competitor X ships a pre-trained model out of the box."
Company counter-claim: "We refuse to ship a pre-trained model because every customer's operational data has different contracts."
   → Conviction: "We believe general-purpose models are a shortcut that ends up costing the buyer twelve months of rework. We insist on contract-first integration, even when it's slower."
```

**Why this works:** Differentiation is already framed as "what we don't do like them" — turning it into a belief statement is a one-step transformation.

---

### Pattern 2: The Recurring Refusal

**When to use:** The same "no" appears across multiple propositions — the company is consistently unwilling to do something its category normally does.

**Structure:**
```markdown
Recurring refusal: Four propositions independently mention refusing to start implementation until data contracts are signed.
   → Conviction: "We refuse to write software before your data contracts are signed. This makes us slower than the competition in the first 90 days. It also means fewer of our customers have to restart their program twelve months in."
```

**Why this works:** A recurring refusal is already a belief — the work is giving it language.

---

### Pattern 3: The Methodology Crystal

**When to use:** The company has a named methodology or framework that embodies its convictions.

**Structure:**
```markdown
Methodology: "Contract-First Integration" appears in 3 proposition descriptions and the company description.
   → Conviction: "We believe the first deliverable of any engagement is a data contract, not a dashboard. Contract-First Integration is the name we give that discipline."
```

**Why this works:** A named methodology is a conviction the company has already published — the About page anchors the methodology in the belief it expresses.

---

### Pattern 4: The Buyer-Visible Consequence

**When to use:** When every conviction needs to be tied to something the buyer will actually experience.

**Structure:**
```markdown
Belief statement: "We believe operational software should fail loudly, not silently."
Consequence for buyer: "This is why every system we deploy pages a human within 90 seconds of a data anomaly — even if it turns out to be a false positive."
   → Combined: "We believe operational software should fail loudly, not silently — which is why every system we deploy will page a human within 90 seconds of a data anomaly, even at the cost of occasional false alarms."
```

**Why this works:** Beliefs without consequences are slogans. Pairing each belief with a buyer-visible consequence passes the "what will I actually experience" test.

## Presentation Structure

### Opening: The Transition

Start Conviction with a short transition from Mission:

```markdown
A mission like ours only works if a few things are non-negotiable. Here are the four we hold.
```

### Body: 3–4 Convictions as Named Entries

Present each as a named entry:

```markdown
**Conviction 1: [Short headline phrasing the belief]**
We believe [belief sentence]. Which is why, when you work with us, you will [buyer-visible consequence].

**Conviction 2: [Short headline]**
We [refuse / insist / believe] [belief sentence]. [Why this is the position, grounded in a citation where possible.] For you, this shows up as [consequence].

...
```

### Closing: Handoff to Credibility

```markdown
Convictions are cheap without receipts. The next section is where we show ours.
```

## Techniques Checklist

### Disagreement Test (mandatory)

- [ ] **Every conviction is something a named competitor plausibly disagrees with**
  - Ask: could a competitor's CMO put the opposite claim on their own About page?
  - If no, the conviction is too generic ("we value customer success") and must be rewritten.

### Consequence Binding

- [ ] **Every conviction ends with a buyer-visible consequence**
  - "We believe X → which is why you will see Y when you work with us."
  - The consequence grounds the belief in something the buyer can verify during an engagement.

### Verb of Belief

- [ ] **Every conviction starts with a verb of position**
  - "We believe…", "We refuse…", "We insist…", "We assume…"
  - German: "Wir glauben…", "Wir weigern uns…", "Wir bestehen darauf…"
  - Passive constructions ("It is believed that…") strip the conviction of ownership.

### Number of Convictions

- [ ] **Exactly 3 or 4 convictions**
  - Fewer than 3: the company looks thin on judgment.
  - More than 4: the page starts reading like a values wall.

## Quality Checkpoints

### Content Requirements

- [ ] 3–4 convictions identified
- [ ] Each conviction passes the disagreement test
- [ ] Each conviction pairs belief with buyer-visible consequence
- [ ] No generic corporate values ("integrity", "customer-centricity")
- [ ] Each conviction can be traced back to Mission or portfolio evidence

### Structure Requirements

- [ ] Opening transition from Mission
- [ ] Named entries with headline + belief + consequence
- [ ] Closing transition to Credibility
- [ ] Word count within proportional range (+/-10%)

## Common Mistakes

### Mistake 1: Generic Values

**Bad:**
> **Conviction 1: Customer-Centricity**
> We put our customers at the center of everything we do.

**Why it fails:** No company says they don't put customers at the center. Fails the disagreement test immediately.

**Good:**
> **Conviction 1: We refuse to deploy software before data contracts are signed.**
> We believe that most "AI transformation" projects fail not because the models are wrong, but because the data they rely on was never contractually defined between the business and IT. This makes us slower than our competitors in the first 90 days of a deal. It also means fewer of our customers have to restart their program twelve months in<sup>[1]</sup>.

---

### Mistake 2: Belief Without Consequence

**Bad:**
> **Conviction 2: Quality First**
> We believe in delivering the highest quality solutions.

**Why it fails:** "Quality first" is a platitude. There is no buyer-visible consequence the reader can use to judge the company.

**Good:**
> **Conviction 2: A dashboard that hides a failing pipeline is worse than no dashboard at all.**
> We refuse to ship green-light UIs while the underlying data pipeline is flaky. Every dashboard we deploy carries a visible freshness indicator, and if the pipeline stalls for more than five minutes, the dashboard turns grey. You will notice this the first week we deploy anything for you — it is what working with us actually looks like.

## Language Variations

### German Adjustments

**Verb of belief in German:**
```markdown
**Überzeugung 1: Wir weigern uns, Software vor Datenverträgen auszuliefern.**
Wir glauben, dass die meisten KI-Transformationsprojekte nicht an den Modellen scheitern, sondern daran, dass die zugrundeliegenden Datenverträge zwischen Fachbereich und IT nie verhandelt wurden. Das macht uns in den ersten 90 Tagen langsamer als unsere Mitbewerber. Es bedeutet aber auch, dass deutlich weniger unserer Kunden ihr Programm nach zwölf Monaten neu aufsetzen müssen.
```

## Related Patterns

- See `mission-patterns.md` for the belief Convictions trace back to
- See `credibility-patterns.md` for backing Convictions with receipts
- See `promise-patterns.md` for translating Convictions into a forward-looking handshake

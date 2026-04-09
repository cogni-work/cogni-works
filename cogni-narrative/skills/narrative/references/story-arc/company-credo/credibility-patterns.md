# Credibility: How-You-Can-Trust-Us Patterns

## Element Purpose

Give the buyer permission to believe the Mission and Convictions by showing receipts. Credibility is the element where belief hardens into willingness to proceed — and where uncited claims do the most damage.

**Word Target:** 26% of target length (the longest element in the arc — this is where the page earns the right to make commitments).

## Source Content Mapping

Extract from:
1. **Proposition evidence arrays** (primary)
   - `propositions/*.json` evidence[] — verified external claims with `source_url`.
2. **Customer entities** (secondary)
   - `customers/*.json` — named accounts, testimonials, case references. Only use if the customer entity explicitly allows disclosure.
3. **Verified claims registry** (tertiary)
   - `cogni-claims/claims.json` — any claim with `status: "verified"` is safe to cite directly.
4. **Portfolio manifest** (context)
   - `portfolio.json` — certifications, partnerships, awards, company-level third-party validation.

## Credibility Dimension Framework

Credibility is read by the buyer along four dimensions. A strong Credibility element covers **at least two**, ideally three, dimensions. A single dimension (e.g., only logos, only numbers) reads as thin.

| Dimension | What it proves | Example markers |
|---|---|---|
| **Track record** | The company has been doing this long enough to know | Years operating, count of deployments, count of customers, longest-running engagement |
| **External validation** | Someone the buyer trusts has already vetted the company | Certifications (ISO 27001, SOC 2), partner badges, analyst mentions, awards |
| **Named outcomes** | The company has produced measurable results | Quantified improvements in specific customer situations, with permission to name |
| **Verifiable expertise** | The team has demonstrable depth | Published case studies, conference talks, contributions to standards, research output |

## Credibility Extraction Patterns

### Pattern 1: Track Record Consolidation

**When to use:** Portfolio has been active for years and has a customer base worth quantifying.

**Structure:**
```markdown
Scan: `portfolio.json.founded_year`, total customers mentioned across propositions evidence, longest-running engagement.
Consolidate: "47 enterprise deployments across Germany, Austria, and Switzerland since 2019<sup>[1]</sup>. Our longest-running customer has been on the platform for 5 years and is now in their third major expansion phase<sup>[2]</sup>."
```

**Why this works:** Specific numbers beat round numbers. "47" is more credible than "dozens". Named geographies beat "across Europe".

---

### Pattern 2: External Validation Stack

**When to use:** The company has certifications, partnerships, or third-party acknowledgements.

**Structure:**
```markdown
Extract from portfolio.json: ISO 27001 (2021), SAP Silver Partner (2022), Fraunhofer IAO case study (2023).
Present as: "ISO 27001 certified since 2021<sup>[3]</sup>. SAP Silver Partner status since 2022<sup>[4]</sup>. Our integration methodology has been cited in a published case study from Fraunhofer IAO<sup>[5]</sup>."
```

**Why this works:** Third-party validation compounds. Each additional external voice makes the buyer's internal procurement conversation easier.

---

### Pattern 3: Named-Outcome Extraction

**When to use:** At least one customer has given permission to share quantified outcomes.

**Structure:**
```markdown
Check: `customers/{market}.json` for `disclosure_permission: true` OR explicit case-study references.
Extract from proposition evidence: specific customer name + specific outcome + citation.
Present as: "At [Named Customer], we reduced the data contract negotiation cycle from 14 weeks to 3 weeks across four business units<sup>[6]</sup>. The program paid for itself inside the first quarter."
```

**Why this works:** A single named outcome carries more weight than a dozen anonymous ones.

---

### Pattern 4: Expertise Markers

**When to use:** Team members or the company have published work, spoken at conferences, or contributed to industry standards.

**Structure:**
```markdown
Extract: any published case studies, whitepapers, conference talks, standards contributions from portfolio context.
Present as: "We have published three technical case studies with Fraunhofer IAO<sup>[5]</sup>, contributed to the IDS Reference Architecture<sup>[7]</sup>, and spoken at the annual European Data Space Summit every year since 2021<sup>[8]</sup>."
```

**Why this works:** Expertise markers signal that the company has depth beyond the marketing site. They make the buyer feel safer recommending the company internally.

---

### Pattern 5: Dimensional Grouping

**When to use:** After extracting raw credibility items, group them so the buyer can scan rather than read line-by-line.

**Structure:**
```markdown
**Track record**
47 enterprise deployments since 2019<sup>[1]</sup>. Longest engagement: 5 years<sup>[2]</sup>.

**External validation**
ISO 27001 certified<sup>[3]</sup>. SAP Silver Partner<sup>[4]</sup>. Cited in Fraunhofer IAO case study<sup>[5]</sup>.

**Named outcomes**
At [Named Customer], we reduced data contract negotiation from 14 weeks to 3<sup>[6]</sup>.

**Expertise**
Contributors to IDS Reference Architecture<sup>[7]</sup>. Annual speakers at European Data Space Summit<sup>[8]</sup>.
```

**Why this works:** Dimensional grouping makes the Credibility element skimmable. Buyers do not read About pages — they scan them.

## Presentation Structure

### Opening: The Receipts Framing

Start with one sentence that sets the expectation that what follows is verifiable:

```markdown
Convictions without receipts are slogans. Here is what we can show.
```

### Body: Dimensional Groups

Present 4–6 credibility items grouped by dimension (Track record, External validation, Named outcomes, Expertise). Aim for ≥2 dimensions.

### Closing: Handoff to Promise

```markdown
If any of this makes you want to find out what working with us actually feels like, the next section is the short version of that.
```

## Techniques Checklist

### Number Plays

- [ ] **Specific beats round**
  - "47 enterprise deployments" > "dozens of deployments"
  - "5 years" > "several years"
  - Precise numbers read as verifiable; round numbers read as aspirational.

### Cited Everything Quantitative

- [ ] **Every number has a citation**
  - Uncited numbers on a Credibility page are worse than no number at all — they actively damage trust.
  - If a number cannot be cited, rephrase to remove the number.

### Permission Discipline for Named Customers

- [ ] **Named customers only with explicit permission**
  - Check the customer entity for a disclosure marker.
  - If ambiguous, describe rather than name ("at a top-3 German automotive OEM" instead of naming).
  - Getting this wrong is a legal and relationship risk, not just a stylistic one.

### Recency Discipline

- [ ] **Flag anything older than 3 years**
  - A 2019 certification is borderline in 2026 and should carry a "still valid" qualifier or be renewed.
  - An 8-year-old case study should be replaced or dropped.

### Dimensional Coverage

- [ ] **Cover ≥2 dimensions**
  - One dimension (only logos, only numbers, only awards) reads as thin.
  - Two or three dimensions compound into a coherent credibility story.

## Quality Checkpoints

### Content Requirements

- [ ] 4–6 total credibility items
- [ ] Items span at least 2 dimensions
- [ ] Every quantitative claim has a citation
- [ ] Named customers appear only with explicit permission
- [ ] No items older than 3 years without a currency qualifier
- [ ] No "trusted by industry leaders" style unbacked claims

### Structure Requirements

- [ ] Opening "receipts" framing sentence
- [ ] Dimensional grouping (bold section labels for scannability)
- [ ] Closing transition to Promise
- [ ] Word count within proportional range (+/-10%)

## Common Mistakes

### Mistake 1: The Vague Validation Paragraph

**Bad:**
> Trusted by industry leaders across Europe, our solutions have helped numerous organizations drive digital transformation and achieve significant operational improvements.

**Why it fails:** Every claim in this paragraph is unbacked. No numbers, no names, no citations, no dimensions. The paragraph is actively less credible than silence.

**Good:**
> **Track record**
> 47 enterprise deployments across Germany, Austria, and Switzerland since 2019<sup>[1]</sup>. Our longest-running customer is now in year five of continuous operation<sup>[2]</sup>.
>
> **External validation**
> ISO 27001 certified since 2021<sup>[3]</sup>. Cited in a Fraunhofer IAO case study on contract-first data integration<sup>[4]</sup>.

---

### Mistake 2: Naming a Customer Without Permission

**Bad:**
> Our customers include Siemens, BMW, and Deutsche Bahn.

**Why it fails:** Unless those names appear in customer entities with explicit disclosure permission, this is a legal and relationship risk.

**Good (when permission is ambiguous):**
> We work with 12 of the 30 largest German industrial enterprises by revenue<sup>[5]</sup>, including three DAX-listed manufacturers. Specific references are available under NDA.

---

### Mistake 3: Stale Credibility

**Bad:**
> In 2018, our methodology was featured in a major industry report.

**Why it fails:** An 8-year-old reference in 2026 looks like the company has nothing newer to show.

**Good:**
> Our methodology has been cited in three published case studies between 2023 and 2025<sup>[4][5][6]</sup>, most recently by Fraunhofer IAO.

## Language Variations

### German Adjustments

**Dimensional labels in German:**
```markdown
**Erfolgsbilanz**
47 Enterprise-Implementierungen in Deutschland, Österreich und der Schweiz seit 2019<sup>[1]</sup>.

**Externe Validierung**
ISO-27001-zertifiziert seit 2021<sup>[3]</sup>. Zitiert in einer Fallstudie des Fraunhofer IAO<sup>[4]</sup>.

**Benannte Ergebnisse**
Bei [Kundenname] haben wir den Datenvertragszyklus von 14 auf 3 Wochen verkürzt<sup>[6]</sup>.

**Nachweisbare Expertise**
Mitwirkende an der IDS-Referenzarchitektur<sup>[7]</sup>.
```

## Related Patterns

- See `mission-patterns.md` for the belief Credibility has to back
- See `conviction-patterns.md` for the positions Credibility supports
- See `promise-patterns.md` for the forward commitment Credibility enables

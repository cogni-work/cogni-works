# Promise: What-You-Can-Expect Patterns

## Element Purpose

Close the About page with a short, specific handshake — what the buyer will experience if they choose to work with the company, stated as a direct commitment in You-voice. Promise is the forward commitment the rest of the arc has earned the right to make.

**Word Target:** 18% of target length (the shortest element — the handshake at the end of a conversation).

## Source Content Mapping

Extract from:
1. **Solution engagement patterns** (primary)
   - `solutions/*.json` implementation phases — the recurring phases across solutions reveal the company's default engagement rhythm.
2. **Product maturity distribution** (critical constraint)
   - `portfolio.json` products + their `maturity` field. Promise MUST NOT commit to anything in `announce` mode.
3. **Buyer-facing DOES language** (secondary)
   - `propositions/*.json` DOES statements phrased in buyer language — reveal what outcomes the buyer can actually count on.

## Promise Construction Patterns

### Pattern 1: The Three Experiences

**When to use:** The standard form. Identify three things the buyer will experience consistently regardless of which capability they engage the company for.

**Structure:**
```markdown
Experience 1 (about how the work starts): "You will not see software from us before we have a signed data contract with your IT organization."
Experience 2 (about how the work feels): "You will see a weekly working demo, not a monthly status report."
Experience 3 (about how the work ends): "You will own the source code and the data contracts at the end of any engagement, with no license lock-in."
```

**Why this works:** Three experiences map naturally to the start, middle, and end of an engagement — they give the buyer a concrete mental model of what working with the company looks like over time.

---

### Pattern 2: The Single Anchor Promise

**When to use:** The company is small or new enough that three experiences would feel padded. Commit to one specific, high-signal experience instead.

**Structure:**
```markdown
Single promise: "You will have a working integration with your existing ERP running in production within the first 60 days of any engagement — or we don't invoice."
```

**Why this works:** A single strong promise is more memorable than three diluted ones. Use sparingly — only when the commitment is specific and high-trust.

---

### Pattern 3: The Maturity-Bound Commitment

**When to use:** The portfolio has a mix of mature and concept-stage products, and the Promise needs to carefully stay on the mature side.

**Structure:**
```markdown
Check maturity: 5 products in growth/mature, 2 in development, 1 in concept.
Promise only references what growth/mature products deliver:
"You will see measurable KPIs on your existing operations within 90 days — grounded in what we ship today, not on our roadmap."
```

**Why this works:** Explicit maturity discipline prevents the Promise from writing checks the portfolio cannot cash.

---

### Pattern 4: The Cross-Cutting Principle

**When to use:** The Convictions included a principle that applies to every engagement (e.g., contract-first, phased rollout, customer-owned code).

**Structure:**
```markdown
Conviction: "We refuse to write software before data contracts are signed."
Promise: "You will sign a data contract before you see a single line of code. This is not negotiable, and it is the reason the first 30 days of any engagement with us feel unusually slow."
```

**Why this works:** Promise reinforces Conviction — a buyer who liked the Conviction sees it operationalised into something they will actually experience.

## Presentation Structure

### Opening: The Handshake Framing

Open with a short sentence that positions the Promise as a commitment:

```markdown
If any of this makes you want to see what working with us actually looks like, here is the short version.
```

### Body: 3 Commitments in You-Voice

Present as 3 named commitments (or 1 anchor commitment in the single-anchor pattern):

```markdown
**You will [experience 1].**
[One sentence of context — why this experience matters and what it replaces in the buyer's current world.]

**You will [experience 2].**
[Context.]

**You will [experience 3].**
[Context.]
```

### Closing: The Single Invitation

End with exactly one next step. It must name a specific next page by its buyer-facing function, not by its URL.

```markdown
If you want to see what we actually build for your role, the Capabilities page is where to go next. If you're a CRO specifically, the For CROs page is a better starting point.
```

Note: offering two options (one generic, one persona-specific) is acceptable — that is still *one invitation* with a fork based on who the buyer is. What's not acceptable is a long menu ("contact sales, book a demo, download the PDF, subscribe to the newsletter, …").

## Techniques Checklist

### You-Phrasing (mandatory)

- [ ] **Every promise item starts with "You will…" / "Sie werden…"**
  - Direct address is what makes a Promise feel like a commitment rather than a statement.
  - Third-person Promise ("Customers can expect…") reads as marketing copy and breaks the handshake.

### Maturity Discipline (mandatory)

- [ ] **No Promise item depends on `announce`-mode products**
  - Walk the maturity map from Step 2.
  - If a Promise sentence only becomes true once a concept product ships, it belongs on the roadmap, not the About page.
  - Promise items that depend on `preview`-mode products must qualify with "in beta" or "currently rolling out".

### Specificity Over Aspiration

- [ ] **Every promise is concrete enough to verify within 90 days**
  - "You will own the source code" — verifiable at any point.
  - "You will see a working demo weekly" — verifiable in week 1.
  - "You will achieve digital transformation" — unverifiable. Cut it.

### Single Invitation Discipline

- [ ] **The final CTA is one link, not a menu**
  - Two options at most, and only if they fork by buyer role.
  - A menu of 4+ options signals the company doesn't know what the reader should do next.

## Quality Checkpoints

### Content Requirements

- [ ] 3 promise items (or 1 anchor promise in the single-anchor pattern)
- [ ] Every item uses You-Phrasing
- [ ] No item depends on `announce`-mode products
- [ ] Every item is verifiable within 90 days of engagement start
- [ ] Items are consistent with the Conviction element (they operationalise the Convictions)

### Structure Requirements

- [ ] Opening handshake framing
- [ ] Named You-Phrased commitments
- [ ] Single closing invitation naming a specific next page
- [ ] Word count within proportional range (+/-10%)

## Common Mistakes

### Mistake 1: Aspirational Promise

**Bad:**
> **You will achieve digital transformation across your organization.**

**Why it fails:** Unverifiable. The buyer has no way to judge whether the promise was kept. Aspirational language in Promise undoes the credibility work of the previous element.

**Good:**
> **You will own the data contracts, source code, and deployment pipeline at the end of any engagement with us.** There is no license lock-in and no "our IP" asterisk buried in the MSA. If you stop working with us, everything we built keeps running without us.

---

### Mistake 2: Promising What You Haven't Shipped

**Bad (when the autonomous-agent product is in `concept` mode):**
> **You will have autonomous agents managing your operational decisions within 90 days.**

**Why it fails:** The portfolio has autonomous agents on the roadmap but not shipping. This Promise is a commitment the company cannot keep.

**Good:**
> **You will see measurable operational KPIs on your existing systems within 90 days** — grounded in the capabilities we ship today, not a roadmap promise. What we are building next is on the Roadmap section of our homepage, clearly separated from what you can buy now.

---

### Mistake 3: Menu Invitation

**Bad:**
> Contact us to learn more — sign up for our newsletter, request a demo, download our whitepaper, book a discovery call, or follow us on LinkedIn.

**Why it fails:** A five-option menu signals that the company has no opinion about what the reader should do next. The reader does nothing.

**Good:**
> If you want to see what we actually build for your role, the Capabilities page is where to go next.

## Language Variations

### German Adjustments

**You-Phrasing in German:** Use "Sie werden" / "Sie erhalten" / "Sie sehen" as direct address.

```markdown
**Sie werden unterschreiben, bevor Sie Code sehen.**
Wir beginnen keine Softwarearbeit, bevor ein Datenvertrag zwischen Ihnen und Ihrer IT unterschrieben ist. Das macht die ersten 30 Tage ungewöhnlich langsam. Es ist der Grund, warum unsere Projekte nicht nach zwölf Monaten neu gestartet werden müssen.

**Sie werden wöchentlich einen funktionierenden Demo sehen, keinen monatlichen Statusbericht.**

**Sie werden am Ende alles besitzen: Datenverträge, Quellcode, Deployment-Pipeline.**
Kein Lizenz-Lock-in, kein "unser IP" im Kleingedruckten. Wenn Sie unsere Zusammenarbeit beenden, läuft alles weiter — ohne uns.

Wenn Sie sehen wollen, was wir für Ihre Rolle konkret bauen, starten Sie auf unserer Capabilities-Seite.
```

## Related Patterns

- See `mission-patterns.md` — Mission is the belief Promise operationalises
- See `conviction-patterns.md` — Convictions are the principles Promise makes visible
- See `credibility-patterns.md` — Credibility is the receipts Promise can draw on

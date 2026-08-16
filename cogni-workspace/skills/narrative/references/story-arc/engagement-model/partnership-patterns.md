# Partnership: What-We-Expect-From-You Patterns

## Element Purpose

Name — plainly — what the buyer needs to bring to the engagement for it to work. Partnership is the reciprocal of Promise: Promise commits the company, Partnership commits the buyer. This is the element most companies skip, which is why including it reads as unusually honest.

**Word Target:** 20% of target length.

## Source Content Mapping

Extract from:
1. **Customer buying criteria** (primary)
   - `customers/*.json` `buying_criteria` — recurring criteria across personas reveal what the company consistently expects.
2. **Solution readiness requirements** (secondary)
   - `solutions/*.json` — explicit prerequisites, input data, approvals, access rights needed to start.
3. **Documented friction points** (tertiary)
   - Portfolio context (if available) about past engagements where missing buyer input delayed or blocked work.

## Partnership Extraction Patterns

### Pattern 1: The Decision-Maker Requirement

**When to use:** The company consistently needs one buyer-side person with specific authority.

**Structure:**
```markdown
Recurring criterion across 5 customer profiles: needs access to someone with "cross-business-unit data authority".
   → Partnership expectation: "You will need one decision-maker with data authority across the business units we are instrumenting. Someone in your organization has to be able to approve data contracts across those units. If that person does not exist yet, our first phase is helping you appoint them — we do not work around this."
```

**Why this works:** Names a specific person the buyer has to identify. No ambiguity.

---

### Pattern 2: The Input-Data Prerequisite

**When to use:** Solutions consistently require specific input data to start.

**Structure:**
```markdown
Recurring requirement across solutions: read access to ERP and MES systems.
   → Partnership expectation: "You will need to arrange read access to your ERP and MES systems before Phase 2 starts. This usually requires a security review on your side. We provide a one-page technical scope to accelerate that review, but we cannot start Phase 2 without the access."
```

**Why this works:** Names the access, names the consequence, offers help — but does not promise to work around the requirement.

---

### Pattern 3: The Timebox Commitment

**When to use:** Engagements falter when buyers cannot respond within a reasonable cadence.

**Structure:**
```markdown
Pattern: Past engagements paused when approvals took longer than a week.
   → Partnership expectation: "You will need to respond to weekly demo feedback and approval requests within 5 business days. If approvals take longer, we pause the engagement rather than work around it — working around stale decisions is how programs get to month 12 and discover they are solving last quarter's problem."
```

**Why this works:** The time band is explicit, the consequence is explicit, and the reasoning is explicit.

---

### Pattern 4: The Executive Sponsor Requirement

**When to use:** The engagement needs executive cover to unblock inter-departmental frictions.

**Structure:**
```markdown
Required role: An executive sponsor with authority across business and IT.
   → Partnership expectation: "You will need one executive sponsor — someone with authority across both business and IT — who can unblock inter-departmental friction in less than 48 hours. This person does not need to attend working sessions, but they need to be reachable when we escalate. We escalate rarely. When we do, we need an answer."
```

**Why this works:** Clarifies what the sponsor does and does not need to do — keeps the expectation reasonable.

## Presentation Structure

### Opening: The Reciprocity Framing

Start by explicitly naming Partnership as the reciprocal of Promise:

```markdown
None of this works unless you bring a few things to the table. We say this directly because most services companies don't — and then the engagement grinds to a halt in month 2 over something that could have been named in week 0.
```

### Body: 3–4 Expectations

```markdown
**You will need [specific thing 1].**
[Why it matters + what happens without it + what the company offers to help, if anything.]

**You will need [specific thing 2].**
[...]

**You will need [specific thing 3].**
[...]
```

### Closing: Handoff to Outcomes

```markdown
If we both hold up our side of that, here is what you will be able to point to at the end.
```

## Techniques Checklist

### You-Phrasing (mandatory)

- [ ] **Every expectation starts with "You will need…" / "Sie werden benötigen…"**
  - Direct address is how Partnership reads as a contract rather than a complaint.

### Consequence Framing

- [ ] **Every expectation names what happens if it is missing**
  - "If this isn't available, we pause the engagement rather than work around it."
  - Reads as discipline, not obstruction.
  - Working around missing input data is how programs fail quietly.

### Constructive Tone

- [ ] **Partnership is a list of inputs, not a list of reasons the engagement could fail**
  - Tone test: would you enjoy reading this as the buyer?
  - If it reads as defensive, rewrite until it reads as honest.

### Specificity

- [ ] **Every expectation names a concrete thing**
  - A person (with authority)
  - A data source (with access type)
  - An approval (with timebox)
  - A decision authority (with scope)
  - Vague expectations ("you need executive buy-in") don't help the buyer prepare.

### Number of Expectations

- [ ] **3–4 expectations, not more**
  - Every engagement needs some buyer input — saying "nothing" is dishonest.
  - But listing 7 expectations reads as defensive and scares buyers off.

## Quality Checkpoints

### Content Requirements

- [ ] 3–4 expectations
- [ ] Each expectation names a concrete thing
- [ ] Each expectation has a consequence if missing
- [ ] Each expectation uses You-Phrasing
- [ ] Tone is constructive, not defensive
- [ ] At least one expectation offers a "how we help" reciprocal

### Structure Requirements

- [ ] Opening reciprocity framing
- [ ] Named expectations in You-voice
- [ ] Closing transition to Outcomes
- [ ] Word count within proportional range (+/-10%)

## Common Mistakes

### Mistake 1: Defensive Laundry List

**Bad:**
> We require: committed sponsors, dedicated resources, clean data, clear objectives, executive buy-in, change management capacity, stable scope, and timely decisions.

**Why it fails:** Reads as defensive. The buyer sees eight reasons the engagement could fail before it starts. Most will bounce.

**Good:**
> **You will need one decision-maker with data authority.** Someone in your organization needs to be able to approve data contracts across the business units we are instrumenting. If that person doesn't exist yet, our first phase is helping you appoint them — we don't try to work around this.
>
> **You will need to respond to weekly demo feedback within 5 business days.** If approvals take longer, we pause the engagement rather than work around it. Working around stale decisions is how programs get to month 12 and discover they are solving last quarter's problem.
>
> **You will need an executive sponsor who can unblock cross-department friction in under 48 hours.** This person doesn't need to attend working sessions, but they need to be reachable when we escalate. We escalate rarely. When we do, we need an answer.

---

### Mistake 2: Vague Expectations

**Bad:**
> **You will need executive support.**

**Why it fails:** Vague. The buyer has no idea what "executive support" means or how to prepare for it.

**Good:**
> **You will need an executive sponsor reachable in under 48 hours for escalations.** The sponsor does not need to attend working sessions. They need to be the person who can break a tie when business and IT disagree on a data contract, inside a two-day window. We escalate rarely — roughly once per quarter on a typical engagement.

## Language Variations

### German Adjustments

```markdown
**Sie werden eine entscheidungsbefugte Person mit Datenhoheit benötigen.**
Jemand in Ihrer Organisation muss Datenverträge über alle Geschäftsbereiche hinweg genehmigen können, die wir instrumentieren. Falls diese Person noch nicht existiert, ist unsere erste Phase, Sie bei der Besetzung zu unterstützen — wir arbeiten nicht daran vorbei.

**Sie werden innerhalb von fünf Arbeitstagen auf wöchentliches Demo-Feedback und Genehmigungsanfragen reagieren müssen.**
Wenn Genehmigungen länger dauern, pausieren wir das Engagement, anstatt daran vorbei zu arbeiten. An veralteten Entscheidungen vorbei zu arbeiten ist der Weg, auf dem Programme in Monat 12 feststellen, dass sie das Problem vom letzten Quartal lösen.
```

## Related Patterns

- See `principles-patterns.md` for the principles that generate these expectations
- See `process-patterns.md` for the phases where these expectations kick in
- See `outcomes-patterns.md` for what the partnership produces when both sides deliver

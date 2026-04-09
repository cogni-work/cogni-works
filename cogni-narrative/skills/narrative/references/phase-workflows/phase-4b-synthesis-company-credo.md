# Phase 4b: Arc-Specific Insight Summary (company-credo)

**Arc Framework:** Mission -> Conviction -> Credibility -> Promise
**Arc:** `company-credo` (Portfolio-native) | **Output:** `insight-summary.md` at project root (target range from `--target-length`, default ~1,400 words)

**Shared steps:** Read [shared-steps.md](shared-steps.md) for entity counting, output template, validation gates, and write instructions.

---

## Arc-Specific Headers

**English:**
- `## Mission: Why We Exist`
- `## Conviction: What We Believe`
- `## Credibility: How You Can Trust Us`
- `## Promise: What You Can Expect`

**German (if `language: de`):**
- `## Mission: Warum es uns gibt`
- `## Überzeugung: Woran wir glauben`
- `## Glaubwürdigkeit: Warum Sie uns vertrauen können`
- `## Versprechen: Was Sie erwarten können`

---

## Step 4.1.1: Load Evidence Entities

This arc is portfolio-native and answers "who is this company?" — it loads the company-shaping entities, not deal-shaping entities.

**Load:**
- Portfolio manifest from `portfolio.json` (company_description, positioning, mission/vision, founded_year, certifications, partnerships)
- All propositions from `propositions/*.json` (primary source of cross-cutting MEANS themes and verified evidence)
- All competitors from `competitors/*.json` (for reverse-engineering differentiation into convictions)
- All customers from `customers/*.json` (for named accounts — ONLY if the entity carries a `disclosure_permission: true` marker)
- Solutions from `solutions/*.json` (for the cross-cutting engagement patterns used in Promise)
- Verified claims from `cogni-claims/claims.json` (filter to `status: "verified"`)
- Product maturity distribution (from `products/*.json` maturity field — critical for Promise discipline)

**After loading, inventory what you have:**
- What does the company explicitly say about itself in `portfolio.json`? Is there a proto-mission, or only a service list?
- Which MEANS themes recur across 4+ propositions? Those are candidates for Mission or Conviction.
- Which competitors are the company's differentiation most strongly framed against? Those framings are candidates for Conviction.
- How many products are in `growth`/`mature` vs `concept`/`development`? This constrains what Promise can commit to.
- Are there customers with explicit disclosure permission? If not, Credibility must use anonymized descriptions.
- Are there certifications, partnerships, or awards in `portfolio.json`? These are the highest-value Credibility items.

---

## Step 4.1.4: Extended Thinking Sub-steps

---

### Sub-step A: Extract the Mission

Before writing, find the Mission:

1. **Read `portfolio.json` company_description, positioning, and any mission/vision field.** Look for a proto-mission — a sentence that expresses what the company refuses to accept as normal.
2. **Scan cross-cutting MEANS themes.** Load all proposition MEANS statements and find the recurring verb of meaning. If the same "so that buyers can finally…" appears in 4+ propositions, that verb is part of the mission.
3. **Name the problem.** State the named problem from market or customer data — one sentence, grounded by at least one citation.
4. **Draft the belief + verb paragraph pair.** First-person plural, position-taking, passes the disagreement test.

**Validation:**
- Mission is first-person plural ("we")
- Mission takes a position (not every competitor could sign it)
- Mission is rooted in a named problem with at least 1 citation
- Mission is NOT a service list

---

### Sub-step B: Extract 3–4 Convictions

For each conviction candidate:

1. **Reverse-engineer from competitor differentiation.** Which competitor claim does the company explicitly refuse to match? That refusal implies a belief.
2. **Identify recurring refusals across propositions.** The same "no" appearing in 4+ propositions is a conviction.
3. **Name any methodology or framework** the company externalises — these are convictions already written down.
4. **Apply the disagreement test.** Each conviction must be something a named competitor plausibly disagrees with.
5. **Bind each conviction to a buyer-visible consequence.** "We believe X → which is why you will experience Y."

**Validation:**
- 3–4 convictions selected
- Each passes the disagreement test
- Each pairs belief with buyer-visible consequence
- No generic corporate values ("integrity", "customer-centricity")
- Each is traceable to portfolio data, not invented

---

### Sub-step C: Extract Credibility Items Across Dimensions

For the Credibility element:

1. **Scan for track-record items:** years operating, deployment counts, customer counts, longest engagement.
2. **Scan for external validation:** certifications, partner statuses, analyst mentions, awards from `portfolio.json`.
3. **Scan for named outcomes:** customers with explicit disclosure permission and quantified outcomes.
4. **Scan for expertise markers:** published case studies, standards contributions, conference talks.
5. **Select 4–6 total items covering at least 2 dimensions.**
6. **Cite every quantitative claim.** Uncited numbers on Credibility are worse than no number.
7. **Flag stale items.** Anything older than 3 years needs a currency qualifier or should be dropped.

**Validation:**
- 4–6 credibility items
- Items span at least 2 dimensions (track record / validation / outcomes / expertise)
- Every quantitative claim has a citation
- Named customers ONLY with `disclosure_permission: true`
- No item older than 3 years without a currency qualifier

---

### Sub-step D: Craft Title, Hook, and Elements

**Title:** Frame as the company's positioning statement, not "About Us". Must take a position (e.g., "The Company Built on Contract-First Data Integration").

**Hook (~10% of target length):**
- One observation about the industry or the buyer's world that makes the company's existence feel necessary
- Ground with at least 1 citation
- Pattern: "[Specific observation about the buyer's world] + [Question or tension the Mission will answer]"

**D1. Mission: Why We Exist (~24% of target length)**

Write:
- First-person plural throughout ("we" / "wir")
- Belief paragraph: named problem + why it persists + 1 citation
- Verb paragraph: what the company does about it, in one specific verb phrase
- Apply Contrast Structure (industry default vs. company stance)
- Apply Forcing Functions (why now, not five years ago)
- Close with transition to Conviction

**D2. Conviction: What We Believe (~22% of target length)**

Write:
- Open with transition from Mission
- 3–4 named convictions
- Each: headline + belief sentence + buyer-visible consequence
- Apply disagreement test to every conviction before writing it
- Cite wherever a market condition is referenced
- Close with transition to Credibility

**D3. Credibility: How You Can Trust Us (~26% of target length)**

Write:
- Open with "receipts" framing sentence
- Dimensional grouping with bold labels (Track record / External validation / Named outcomes / Expertise)
- 4–6 items across ≥2 dimensions
- Cite every quantitative claim
- Close with transition to Promise

**D4. Promise: What You Can Expect (~18% of target length)**

Write:
- Open with handshake framing sentence
- 3 You-Phrased commitments (or 1 anchor promise if justified)
- Maturity discipline: no commitment depends on `announce`-mode products
- Close with a single invitation naming a specific next page by buyer-facing function (e.g., "the Capabilities page", "the For CROs page")

---

### Sub-step E: Self-Review

1. **Word count:** Within target length range? Hook ~10%, Mission ~24%, Conviction ~22%, Credibility ~26%, Promise ~18%?
2. **Arc coherence:** Mission → Conviction → Credibility → Promise builds a single argument? Each element references the previous?
3. **Company-Credo constraints:**
   - [ ] Mission in first-person plural?
   - [ ] Every Conviction passes disagreement test?
   - [ ] Every Conviction paired with buyer-visible consequence?
   - [ ] Credibility covers ≥2 dimensions?
   - [ ] Every quantitative Credibility claim cited?
   - [ ] Named customers only with `disclosure_permission: true`?
   - [ ] No Promise item depends on `announce`-mode products?
   - [ ] Every Promise item uses You-Phrasing?
   - [ ] Single invitation at close (not a menu)?
4. **Evidence:** 8–15 total citations distributed across elements? Every quantitative claim cited?
5. **Techniques applied:** Contrast Structure (Mission), Forcing Functions (Mission or Hook), disagreement test (Conviction), dimensional grouping (Credibility), You-Phrasing (Promise)?

Now proceed to validation and write steps in [shared-steps.md](shared-steps.md).

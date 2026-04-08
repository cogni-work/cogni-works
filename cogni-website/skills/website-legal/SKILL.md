---
name: website-legal
description: |
  This skill generates legally required pages (Impressum, Datenschutzerklärung, Cookie-Hinweis)
  for a cogni-website project based on the publishing jurisdiction (DE, AT, CH, EU). It captures
  the legal entity facts, fills jurisdiction-specific boilerplate templates, writes the markdown
  source files, and patches website-plan.json so the existing build pipeline renders them.
  Trigger when the user mentions "Impressum", "Datenschutz", "Datenschutzerklärung", "Cookie-Hinweis",
  "DSGVO", "GDPR", "Pflichtangaben", "rechtliche Seiten", "legal pages", "legal notice",
  "privacy policy", "compliance pages", "TMG", "ECG", "revDSG", "Rechtstexte erzeugen", or wants
  to add legally required content for Germany, Austria, Switzerland, or the EU. Requires
  website-project.json (created by website-setup).
allowed-tools: Read, Write, Edit, Glob, Bash, AskUserQuestion
---

# Website Legal

Generate jurisdiction-specific legal pages from reviewable boilerplate templates. The skill never invents legal text — all wording comes from the template bundles in `references/jurisdictions/`. Claude only fills `{{placeholders}}` with facts captured from the user.

## Disclaimer

The generated pages are templates, not legal advice. Always print the disclaimer in the final summary: **"Diese Texte sind Vorlagen. Vor der Veröffentlichung durch eine Anwältin oder einen Anwalt prüfen lassen."** Adapt the disclaimer to project language.

## Prerequisites

A `website-project.json` must exist in the working directory. If missing, redirect to `website-setup`. A `website-plan.json` is **not** required — `website-legal` can run before or after `website-plan`. If the plan does not yet exist, the skill writes the legal page entries to a queue file (`legal-pages.json`) that `website-plan` will pick up.

## Workflow

### 1. Load Project

Read `website-project.json`. Extract:

- `language` (drives all user-facing prompts and template language; default `de`)
- `company` (name, tagline, contact)
- `legal_config` (may be missing, partial, or complete)

If `legal_config` is missing, create an empty object.

### 2. Determine Jurisdiction

If `legal_config.jurisdiction` is not set, ask the user via `AskUserQuestion`:

> "In welcher Rechtsordnung wird die Website veröffentlicht?"

Options:

- **Deutschland (DE)** — TMG §5, DSGVO, Telemediengesetz
- **Österreich (AT)** — ECG §5, DSG, DSGVO
- **Schweiz (CH)** — revDSG, freiwillige Anbieterkennzeichnung
- **EU (übrige Mitgliedstaaten)** — DSGVO, ePrivacy, generischer Legal Notice

Persist the choice to `legal_config.jurisdiction`.

### 3. Capture Legal Entity Facts

Read `references/legal-config-schema.md` to learn the full field set, then check which fields are still missing for the chosen jurisdiction (see the requirement matrix in that file).

Ask only for missing fields. Adapt the questions to project language. Group questions logically — capture the legal entity in one round, then the responsible person, then VAT/registration in a third round so the user is not overwhelmed.

Required-by-jurisdiction matrix (high level — see `references/legal-config-schema.md` for exact rules):

| Field | DE | AT | CH | EU |
|-------|----|----|----|----|
| `legal_entity.legal_name` | required | required | required | required |
| `legal_entity.legal_form` | required | required | recommended | recommended |
| `legal_entity.address` | required | required | required | required |
| `legal_entity.register_court` | required (if HRB) | — | — | optional |
| `legal_entity.register_number` | required (if HRB) | required (FN) | optional (CHE) | optional |
| `legal_entity.vat_id` | required (if applicable) | required (if applicable) | optional | required (if applicable) |
| `responsible_person.name` | required (§55 RStV) | required (§24 MedienG) | recommended | recommended |
| `responsible_person.address` | required if differs from legal_entity | required if differs | optional | optional |
| `supervisory_authority` | required (if regulated) | required (if regulated) | optional | optional |
| `professional_regulations` | required (if regulated profession) | required (if regulated) | optional | optional |
| `dispute_resolution.os_platform_link` | required (EU consumer business) | required (EU consumer business) | — | required (EU consumer) |
| `contact.email` | required | required | required | required |
| `contact.phone` | required | required | recommended | recommended |
| `data_protection.controller_name` | required (DSGVO Art. 13) | required | required (revDSG) | required |
| `data_protection.dpo_contact` | required if DPO mandatory | required if DPO mandatory | optional | required if DPO mandatory |

Persist captured fields immediately to `website-project.json` → `legal_config` after each round, so a long capture session is never lost.

### 4. Validate Required Fields

Before generating templates, run a completeness check against the matrix. If required fields for the chosen jurisdiction are still missing, list them and ask the user one more time. If the user explicitly says "use placeholder for now", insert a literal `«TODO: <field>»` marker — never invent values.

### 5. Select Template Bundle

Pick the bundle directory from `${CLAUDE_PLUGIN_ROOT}/skills/website-legal/references/jurisdictions/`:

| Jurisdiction | Bundle path | Page slugs |
|--------------|-------------|------------|
| `de` | `references/jurisdictions/de/` | `impressum`, `datenschutz`, `cookies` |
| `at` | `references/jurisdictions/at/` | `impressum`, `datenschutz`, `cookies` |
| `ch` | `references/jurisdictions/ch/` | `impressum`, `datenschutz`, `cookies` |
| `eu` | `references/jurisdictions/eu/` | `legal-notice`, `privacy-policy`, `cookies` |

Each bundle contains three files: an imprint/legal-notice template, a privacy template, and a cookies template, all with the `.md.tmpl` extension.

### 6. Render Templates

For each template file in the bundle:

1. Read the template content with the `Read` tool.
2. Substitute every `{{placeholder}}` token with the corresponding value from `legal_config`, `company`, or the current date. Supported placeholder paths are documented in `references/placeholder-schema.md`.
3. If a placeholder has no value, insert the literal string `«TODO: <placeholder>»` so the gap is visible in the rendered HTML.
4. Replace `{{generated_at}}` with the current date in ISO format and `{{generated_at_human}}` with the localized form (e.g. "8. April 2026" for `de`).
5. Write the result to `content/legal/{slug}.md` in the project directory. Create the `content/legal/` directory if it does not exist.

The output is markdown, not HTML. The existing `page-generator` agent renders these markdown files to HTML during `website-build` using the legal page templates from `${CLAUDE_PLUGIN_ROOT}/libraries/legal-pages.md`.

### 7. Patch website-plan.json (if it exists)

If `website-plan.json` exists in the project directory:

1. Read it.
2. Remove any existing legal page entries (page IDs starting with `legal-`) so re-runs are idempotent.
3. Append three new page entries — one per generated legal page — using the structure from `${CLAUDE_PLUGIN_ROOT}/libraries/EXAMPLE_WEBSITE_PLAN.md` (legal section). Each entry has:
   - `id`: `legal-imprint`, `legal-privacy`, `legal-cookies`
   - `type`: `legal-imprint` | `legal-privacy` | `legal-cookies`
   - `slug`: `pages/impressum` | `pages/datenschutz` | `pages/cookies` (or `legal-notice`/`privacy-policy` for EU)
   - `title`: localized page title — site title
   - `meta_description`: short SEO description (e.g. "Impressum gemäß § 5 TMG")
   - `source_files`: `["content/legal/{slug}.md"]`
   - `sections`: `["legal-header", "legal-body"]`
   - `footer_only`: `true` — exclude from primary nav, include in footer legal column
4. Add or replace the top-level `legal_links` array with:
   ```json
   [
     { "label": "Impressum",   "href": "/pages/impressum.html" },
     { "label": "Datenschutz", "href": "/pages/datenschutz.html" },
     { "label": "Cookies",     "href": "/pages/cookies.html" }
   ]
   ```
   Labels and slugs adapt to language and jurisdiction.
5. Write the updated plan back atomically.

If `website-plan.json` does **not** yet exist, write the entries and the `legal_links` array to `legal-pages.json` in the project directory. The `website-plan` skill will merge `legal-pages.json` into the plan it generates (see the page-type-registry for details).

### 8. Print Summary

```
Rechtliche Seiten erstellt für Rechtsordnung: {jurisdiction_name}

  Generierte Seiten:
    ✓ content/legal/impressum.md     ({n} Wörter)
    ✓ content/legal/datenschutz.md   ({n} Wörter)
    ✓ content/legal/cookies.md       ({n} Wörter)

  Konfiguration:
    Rechtsträger:    {legal_entity.legal_name}
    Anschrift:       {legal_entity.address.city}
    Verantwortlich:  {responsible_person.name}
    USt-IdNr.:       {legal_entity.vat_id}

  Offene Platzhalter: {n}    ← bitte vor Veröffentlichung füllen
  Plan aktualisiert:  ja|nein (legal-pages.json zwischengespeichert)

⚠ Diese Texte sind Vorlagen. Vor der Veröffentlichung durch eine Anwältin oder
   einen Anwalt prüfen lassen.

Nächster Schritt: /website-build — Seiten generieren (oder /website-plan, falls
                  noch nicht ausgeführt).
```

If any `«TODO: ...»` placeholders are still present, list them explicitly so the user can fix them before building.

## Re-running the Skill

The skill is idempotent. Re-running it:

- Re-reads `legal_config` from `website-project.json`
- Asks only for fields that are still missing
- Overwrites `content/legal/*.md` with freshly rendered templates
- Replaces existing `legal-*` page entries in `website-plan.json` (no duplication)

If the user wants to switch jurisdictions, ask them to confirm — switching deletes the old templates and writes new ones. Old captured facts in `legal_config` are preserved where the new jurisdiction needs the same fields.

## Output Language

All user-facing text and template output use the project `language` field. Default `de`. Each jurisdiction bundle currently ships with German templates (DE/AT/CH) and an English template (EU). When the project language differs from the bundle language, render the templates as-is and warn the user.

## Reference Files

- `${CLAUDE_PLUGIN_ROOT}/skills/website-legal/references/legal-config-schema.md` — full schema and per-jurisdiction requirement rules
- `${CLAUDE_PLUGIN_ROOT}/skills/website-legal/references/placeholder-schema.md` — list of supported `{{placeholders}}` and their source paths
- `${CLAUDE_PLUGIN_ROOT}/skills/website-legal/references/jurisdictions/{de,at,ch,eu}/` — boilerplate templates
- `${CLAUDE_PLUGIN_ROOT}/libraries/legal-pages.md` — HTML/CSS pattern for legal page rendering
- `${CLAUDE_PLUGIN_ROOT}/libraries/EXAMPLE_WEBSITE_PLAN.md` — reference for the legal page entries and `legal_links` array

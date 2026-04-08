# legal_config schema

The `legal_config` block lives inside `website-project.json` next to `company`, `sources`, and `build_options`. It captures the legal-entity facts the `website-legal` skill needs to render jurisdiction-specific compliance pages (Impressum, Datenschutzerklärung, Cookies).

## Full schema

```json
{
  "legal_config": {
    "jurisdiction": "de",
    "site_audience": "b2b",
    "legal_entity": {
      "legal_name": "SmartFactory Solutions GmbH",
      "legal_form": "GmbH",
      "address": {
        "street": "Beispielstraße 12",
        "postal_code": "80331",
        "city": "München",
        "country": "Deutschland"
      },
      "register_court": "Amtsgericht München",
      "register_number": "HRB 123456",
      "vat_id": "DE123456789",
      "tax_id": null
    },
    "responsible_person": {
      "name": "Maria Mustermann",
      "role": "Geschäftsführerin",
      "address_same_as_entity": true,
      "address": null
    },
    "supervisory_authority": {
      "name": null,
      "address": null,
      "url": null
    },
    "professional_regulations": {
      "title": null,
      "awarded_in": null,
      "rules_url": null
    },
    "contact": {
      "email": "kontakt@smartfactory.example",
      "phone": "+49 89 12345678"
    },
    "data_protection": {
      "controller_name": "SmartFactory Solutions GmbH",
      "controller_contact": "datenschutz@smartfactory.example",
      "dpo_required": false,
      "dpo_name": null,
      "dpo_contact": null,
      "uses_analytics": false,
      "uses_marketing_cookies": false,
      "uses_external_fonts": false,
      "uses_external_embeds": false
    },
    "dispute_resolution": {
      "os_platform_link": "https://ec.europa.eu/consumers/odr",
      "willing_to_participate": false
    },
    "generated_at": "2026-04-08",
    "template_version": "1.0.0"
  }
}
```

## Field reference

### `jurisdiction` (string, required)

One of: `de`, `at`, `ch`, `eu`. Drives template bundle selection.

### `site_audience` (string, optional)

One of: `b2b`, `b2c`, `mixed`. Default: `b2b`. Affects whether the EU dispute-resolution clause is rendered (consumer-facing only).

### `legal_entity`

Identifies the operator of the website. The Impressum names this entity as the responsible party.

| Field | Type | Notes |
|-------|------|-------|
| `legal_name` | string | Full registered name including legal form suffix |
| `legal_form` | string | `GmbH`, `AG`, `UG`, `GmbH & Co. KG`, `Einzelunternehmen`, `e.U.`, `OG`, `KG`, `AG` (CH), `Sàrl`, `LLC`, `Ltd.`, etc. |
| `address.street` | string | Street and number |
| `address.postal_code` | string | |
| `address.city` | string | |
| `address.country` | string | Full country name in project language |
| `register_court` | string \| null | E.g. "Amtsgericht München" (DE), "Landesgericht Wien" (AT), "Handelsregisteramt Zürich" (CH) |
| `register_number` | string \| null | DE: HRB-Nummer; AT: FN-Nummer; CH: CHE-Nummer (UID) |
| `vat_id` | string \| null | EU VAT ID — DE: USt-IdNr.; AT: UID; CH: CHE-...-MWST |
| `tax_id` | string \| null | National tax number (only render if user explicitly provides) |

### `responsible_person`

The natural person responsible for content under §55 RStV (DE) / §24 MedienG (AT). Without it, German Impressum is incomplete for sites with editorial content.

| Field | Type | Notes |
|-------|------|-------|
| `name` | string | Full name |
| `role` | string | E.g. "Geschäftsführer", "Inhaber", "Verantwortlich i.S.d. §55 RStV" |
| `address_same_as_entity` | boolean | If true, the Impressum reuses `legal_entity.address` |
| `address` | object \| null | Same shape as `legal_entity.address`. Only set if different |

### `supervisory_authority`

Required only for regulated industries (financial services, healthcare, legal services, real estate, etc.). Set to `null`-objects for unregulated B2B SaaS.

### `professional_regulations`

Required only for regulated professions (lawyers, doctors, architects, tax advisors, etc.).

### `contact`

| Field | Type | Notes |
|-------|------|-------|
| `email` | string | Primary contact email — must be a real, monitored address |
| `phone` | string | International format `+49 ...` |

### `data_protection`

Drives the Datenschutzerklärung sections.

| Field | Type | Notes |
|-------|------|-------|
| `controller_name` | string | Verantwortlicher i.S.d. DSGVO Art. 4 Nr. 7. Usually `legal_entity.legal_name` |
| `controller_contact` | string | Email for data subject requests |
| `dpo_required` | boolean | True if a DPO is required (e.g. ≥20 employees regularly processing personal data in DE) |
| `dpo_name` | string \| null | Data Protection Officer name |
| `dpo_contact` | string \| null | DPO contact email |
| `uses_analytics` | boolean | Hint for the cookie page — drives whether the analytics paragraph is rendered |
| `uses_marketing_cookies` | boolean | Hint for the cookie page |
| `uses_external_fonts` | boolean | True if Google Fonts or similar — affects DSGVO §3 statement |
| `uses_external_embeds` | boolean | True if YouTube, Vimeo, Maps embeds present |

### `dispute_resolution`

Required for EU consumer-facing sites (EU Regulation 524/2013).

| Field | Type | Notes |
|-------|------|-------|
| `os_platform_link` | string | Always `https://ec.europa.eu/consumers/odr` |
| `willing_to_participate` | boolean | Whether the entity is willing to participate in OS dispute resolution. Most B2B sites set this to false and explicitly state so |

### `generated_at`, `template_version`

Bookkeeping. `template_version` lets future versions of `website-legal` detect outdated `legal_config` blocks.

## Per-jurisdiction requirement matrix

The `website-legal` skill validates this matrix in step 4 before rendering templates. **req** = required, **rec** = recommended, **opt** = optional, **—** = not applicable, **cond** = conditional (see notes).

| Field | DE | AT | CH | EU |
|-------|----|----|----|----|
| `legal_entity.legal_name` | req | req | req | req |
| `legal_entity.legal_form` | req | req | rec | rec |
| `legal_entity.address.*` | req | req | req | req |
| `legal_entity.register_court` | cond¹ | — | — | opt |
| `legal_entity.register_number` | cond¹ | req | opt | opt |
| `legal_entity.vat_id` | cond² | cond² | opt | cond² |
| `responsible_person.name` | req³ | req | rec | rec |
| `responsible_person.role` | req³ | req | rec | rec |
| `supervisory_authority.*` | cond⁴ | cond⁴ | opt | opt |
| `professional_regulations.*` | cond⁵ | cond⁵ | opt | opt |
| `contact.email` | req | req | req | req |
| `contact.phone` | req | req | rec | rec |
| `data_protection.controller_name` | req | req | req | req |
| `data_protection.controller_contact` | req | req | req | req |
| `data_protection.dpo_contact` | cond⁶ | cond⁶ | opt | cond⁶ |
| `dispute_resolution.os_platform_link` | cond⁷ | cond⁷ | — | cond⁷ |

**Notes:**

1. Required if the entity is registered in the commercial register (HRB). Sole proprietors (Einzelunternehmen) without HRB skip both fields.
2. Required if the entity is VAT-registered. Small-business (Kleinunternehmer §19 UStG) entities skip.
3. Required for sites with editorial content (any blog, news, opinions). German TMG/RStV reads this strictly — practically every company website needs it.
4. Required if the business activity is regulated (financial, healthcare, legal, real estate, gambling, etc.).
5. Required if a regulated profession is practiced (Rechtsanwalt, Steuerberater, Arzt, Architekt, etc.).
6. Required if a Data Protection Officer is mandatory under DSGVO Art. 37.
7. Required if the site targets EU consumers (`site_audience` is `b2c` or `mixed`).

## Validation in `website-legal`

Step 4 of the skill walks the matrix for the chosen jurisdiction and lists all `req`/active-`cond` fields that are still null or empty. The user can either fill them or accept `«TODO: <field>»` markers in the rendered output.

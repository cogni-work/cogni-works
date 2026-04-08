# Placeholder schema

The legal templates in `references/jurisdictions/*/` use `{{dot.path}}` placeholders that the `website-legal` skill substitutes during rendering. This file lists every supported placeholder, its source path inside `website-project.json`, and the fallback behaviour when the source is missing.

## Substitution rules

1. Placeholders are surrounded by double curly braces: `{{path.to.field}}`.
2. The path is dot-separated and resolved against a merged context object built from `website-project.json` plus a few synthetic fields (`generated_at`, `generated_at_human`, `current_year`).
3. If the resolved value is `null`, empty, or missing, the renderer inserts the literal string `«TODO: {{path}}»` so the gap shows up in the rendered HTML.
4. Boolean fields use the `{{#if path}}…{{/if}}` block form to gate optional sections (see "Conditional blocks" below).
5. The renderer never invents values. If a placeholder is unresolved, the human reviewer must fix it before publishing.

## Supported placeholders

### Company

| Placeholder | Source path |
|-------------|-------------|
| `{{company.name}}` | `company.name` |
| `{{company.tagline}}` | `company.tagline` |
| `{{company.description}}` | `company.description` |

### Legal entity

| Placeholder | Source path |
|-------------|-------------|
| `{{legal_entity.legal_name}}` | `legal_config.legal_entity.legal_name` |
| `{{legal_entity.legal_form}}` | `legal_config.legal_entity.legal_form` |
| `{{legal_entity.address.street}}` | `legal_config.legal_entity.address.street` |
| `{{legal_entity.address.postal_code}}` | `legal_config.legal_entity.address.postal_code` |
| `{{legal_entity.address.city}}` | `legal_config.legal_entity.address.city` |
| `{{legal_entity.address.country}}` | `legal_config.legal_entity.address.country` |
| `{{legal_entity.address.full}}` | computed: `street, postal_code city, country` |
| `{{legal_entity.register_court}}` | `legal_config.legal_entity.register_court` |
| `{{legal_entity.register_number}}` | `legal_config.legal_entity.register_number` |
| `{{legal_entity.vat_id}}` | `legal_config.legal_entity.vat_id` |
| `{{legal_entity.tax_id}}` | `legal_config.legal_entity.tax_id` |

### Responsible person

| Placeholder | Source path |
|-------------|-------------|
| `{{responsible_person.name}}` | `legal_config.responsible_person.name` |
| `{{responsible_person.role}}` | `legal_config.responsible_person.role` |
| `{{responsible_person.address.full}}` | computed; falls back to `legal_entity.address.full` if `address_same_as_entity` is true |

### Contact

| Placeholder | Source path |
|-------------|-------------|
| `{{contact.email}}` | `legal_config.contact.email` |
| `{{contact.phone}}` | `legal_config.contact.phone` |

### Supervisory authority (regulated industries only)

| Placeholder | Source path |
|-------------|-------------|
| `{{supervisory_authority.name}}` | `legal_config.supervisory_authority.name` |
| `{{supervisory_authority.address}}` | `legal_config.supervisory_authority.address` |
| `{{supervisory_authority.url}}` | `legal_config.supervisory_authority.url` |

### Professional regulations (regulated professions only)

| Placeholder | Source path |
|-------------|-------------|
| `{{professional_regulations.title}}` | `legal_config.professional_regulations.title` |
| `{{professional_regulations.awarded_in}}` | `legal_config.professional_regulations.awarded_in` |
| `{{professional_regulations.rules_url}}` | `legal_config.professional_regulations.rules_url` |

### Data protection

| Placeholder | Source path |
|-------------|-------------|
| `{{data_protection.controller_name}}` | `legal_config.data_protection.controller_name` |
| `{{data_protection.controller_contact}}` | `legal_config.data_protection.controller_contact` |
| `{{data_protection.dpo_name}}` | `legal_config.data_protection.dpo_name` |
| `{{data_protection.dpo_contact}}` | `legal_config.data_protection.dpo_contact` |

### Dispute resolution (EU consumer-facing)

| Placeholder | Source path |
|-------------|-------------|
| `{{dispute_resolution.os_platform_link}}` | `legal_config.dispute_resolution.os_platform_link` |

### Generated metadata

| Placeholder | Source |
|-------------|--------|
| `{{generated_at}}` | ISO date `YYYY-MM-DD` of the render run |
| `{{generated_at_human}}` | Localized date string (e.g. "8. April 2026" for `de`) |
| `{{current_year}}` | Four-digit year |
| `{{language}}` | Project language code |

## Conditional blocks

Some sections only apply under certain conditions (DPO present, regulated profession, EU consumer business, analytics in use). Templates use this syntax for conditional inclusion:

```
{{#if data_protection.dpo_required}}
## Datenschutzbeauftragter

{{data_protection.dpo_name}}
{{data_protection.dpo_contact}}
{{/if}}
```

The renderer evaluates the path. The block is rendered if the value is truthy (non-null, non-empty, non-`false`, non-`0`).

Supported condition paths:

- `data_protection.dpo_required`
- `data_protection.uses_analytics`
- `data_protection.uses_marketing_cookies`
- `data_protection.uses_external_fonts`
- `data_protection.uses_external_embeds`
- `responsible_person.address_same_as_entity` (used in negated form: `{{#unless responsible_person.address_same_as_entity}}…{{/unless}}`)
- `professional_regulations.title`
- `supervisory_authority.name`
- `legal_entity.register_number`
- `legal_entity.vat_id`
- `dispute_resolution.os_platform_link` (combined with `site_audience != "b2b"`)

## Implementation note

The `website-legal` skill performs substitution by reading each template, walking its content, resolving placeholders against the merged context, and writing the result. It does **not** call out to a third-party templating engine — substitution is a deliberate, plain string replacement so the user can audit it line by line.

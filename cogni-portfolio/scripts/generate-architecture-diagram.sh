#!/bin/bash
# Generate a layered mermaid architecture diagram from products and features.
# Reads products/*.json and features/*.json, writes output/architecture.md.
# Usage: generate-architecture-diagram.sh <project-dir>
# Exit codes: 0 = generated, 1 = no entities found, 2 = usage error
set -euo pipefail

PROJECT_DIR="${1:-}"

if [ -z "$PROJECT_DIR" ] || [ ! -d "$PROJECT_DIR" ]; then
  echo '{"error": "Usage: generate-architecture-diagram.sh <project-dir>"}' >&2
  exit 2
fi

if [ ! -f "$PROJECT_DIR/portfolio.json" ]; then
  echo '{"error": "No portfolio.json found in project directory"}' >&2
  exit 2
fi

python3 -c "
import json, os, sys, re
from datetime import date
from collections import defaultdict

project_dir = sys.argv[1]

# Read portfolio.json for company name
with open(os.path.join(project_dir, 'portfolio.json')) as f:
    portfolio = json.load(f)

company = portfolio.get('company', {})
if isinstance(company, str):
    company_name = company
else:
    company_name = company.get('name', 'Portfolio')

# Read all products
products = {}
products_dir = os.path.join(project_dir, 'products')
if os.path.isdir(products_dir):
    for fname in sorted(os.listdir(products_dir)):
        if fname.endswith('.json'):
            with open(os.path.join(products_dir, fname)) as f:
                p = json.load(f)
                products[p['slug']] = p

# Read all features
features = []
features_dir = os.path.join(project_dir, 'features')
if os.path.isdir(features_dir):
    for fname in sorted(os.listdir(features_dir)):
        if fname.endswith('.json'):
            with open(os.path.join(features_dir, fname)) as f:
                features.append(json.load(f))

if not products and not features:
    print(json.dumps({'status': 'empty', 'reason': 'No products or features found'}))
    sys.exit(1)

# Group features by product_slug, then by category
features_by_product = defaultdict(list)
for f in features:
    features_by_product[f.get('product_slug', '_unassigned')].append(f)

# Sort features within each group by sort_order
for slug in features_by_product:
    features_by_product[slug].sort(key=lambda x: (x.get('sort_order', 9999), x.get('slug', '')))

# Track categories across products for cross-product bridges
category_products = defaultdict(set)  # category -> set of product slugs
for f in features:
    cat = f.get('category')
    ps = f.get('product_slug', '_unassigned')
    if cat:
        category_products[cat].add(ps)

# Escape special characters for mermaid labels
def esc(text):
    # Replace characters that break mermaid syntax
    text = text.replace('\"', '#quot;')
    text = text.replace('(', '#40;')
    text = text.replace(')', '#41;')
    text = text.replace('[', '#91;')
    text = text.replace(']', '#93;')
    text = text.replace('{', '#123;')
    text = text.replace('}', '#125;')
    text = text.replace('<', '#lt;')
    text = text.replace('>', '#gt;')
    return text

# Sanitize ID for mermaid (only alphanumeric and hyphens)
def sanitize_id(text):
    return re.sub(r'[^a-zA-Z0-9-]', '-', text)

# Build mermaid diagram
lines = []
lines.append('flowchart TD')
lines.append('')

# Class definitions for readiness styling
lines.append('    %% Readiness styles')
lines.append('    classDef ga fill:#4ade80,stroke:#166534,color:#000')
lines.append('    classDef beta fill:#fbbf24,stroke:#92400e,color:#000')
lines.append('    classDef planned fill:#d1d5db,stroke:#6b7280,color:#000,stroke-dasharray: 5 5')
lines.append('    classDef empty fill:#f3f4f6,stroke:#9ca3af,color:#6b7280')
lines.append('')

# Sort products by name for consistent output
sorted_products = sorted(products.values(), key=lambda p: p.get('name', p['slug']))

for prod in sorted_products:
    ps = prod['slug']
    pid = sanitize_id(ps)
    maturity = prod.get('maturity', '')
    revenue = prod.get('revenue_model', '')

    # Build product label with metadata badges
    label_parts = [esc(prod.get('name', ps))]
    badges = []
    if maturity:
        badges.append(maturity)
    if revenue:
        badges.append(revenue)
    if badges:
        label_parts.append(f'#40;{', '.join(badges)}#41;')
    product_label = ' '.join(label_parts)

    lines.append(f'    subgraph {pid}[\"{product_label}\"]')
    lines.append(f'        direction TB')

    prod_features = features_by_product.get(ps, [])

    if not prod_features:
        # Empty product placeholder
        empty_id = f'{pid}--empty'
        lines.append(f'        {empty_id}[\"no features defined\"]:::{\"empty\"}')
    else:
        # Group by category
        by_category = defaultdict(list)
        uncategorized = []
        for feat in prod_features:
            cat = feat.get('category')
            if cat:
                by_category[cat].append(feat)
            else:
                uncategorized.append(feat)

        # Render categorized features in sub-subgraphs
        for cat in sorted(by_category.keys()):
            cat_id = sanitize_id(f'{ps}-{cat}')
            lines.append(f'        subgraph {cat_id}[\"{esc(cat)}\"]')
            for feat in by_category[cat]:
                fid = sanitize_id(feat['slug'])
                fname = esc(feat.get('name', feat['slug']))
                readiness = feat.get('readiness', 'ga')
                if readiness == 'beta':
                    lines.append(f'            {fid}([\"{fname}\"]):::{readiness}')
                elif readiness == 'planned':
                    lines.append(f'            {fid}[\"{fname}\"]:::{readiness}')
                else:
                    lines.append(f'            {fid}[\"{fname}\"]:::ga')
            lines.append(f'        end')

        # Render uncategorized features directly in product subgraph
        for feat in uncategorized:
            fid = sanitize_id(feat['slug'])
            fname = esc(feat.get('name', feat['slug']))
            readiness = feat.get('readiness', 'ga')
            if readiness == 'beta':
                lines.append(f'        {fid}([\"{fname}\"]):::{readiness}')
            elif readiness == 'planned':
                lines.append(f'        {fid}[\"{fname}\"]:::{readiness}')
            else:
                lines.append(f'        {fid}[\"{fname}\"]:::ga')

    lines.append(f'    end')
    lines.append('')

# Handle unassigned features (features referencing non-existent products)
unassigned = features_by_product.get('_unassigned', [])
if unassigned:
    lines.append('    subgraph _unassigned[\"Unassigned Features\"]')
    lines.append('        direction TB')
    for feat in unassigned:
        fid = sanitize_id(feat['slug'])
        fname = esc(feat.get('name', feat['slug']))
        readiness = feat.get('readiness', 'ga')
        lines.append(f'        {fid}[\"{fname}\"]:::{readiness}')
    lines.append('    end')
    lines.append('')

# Cross-product bridges: dotted links between products sharing categories
bridge_pairs = set()
for cat, prod_slugs in category_products.items():
    slugs = sorted(prod_slugs)
    if len(slugs) >= 2:
        for i in range(len(slugs)):
            for j in range(i + 1, len(slugs)):
                pair = (slugs[i], slugs[j])
                if pair not in bridge_pairs:
                    bridge_pairs.add(pair)
                    cat_id_a = sanitize_id(f'{slugs[i]}-{cat}')
                    cat_id_b = sanitize_id(f'{slugs[j]}-{cat}')
                    lines.append(f'    {cat_id_a} -.-|{esc(cat)}| {cat_id_b}')

if bridge_pairs:
    lines.append('')

mermaid_code = '\\n'.join(lines)

# Build the output markdown
today = date.today().isoformat()
product_count = len(products)
feature_count = len(features)

# Readiness breakdown
readiness_counts = defaultdict(int)
for f in features:
    readiness_counts[f.get('readiness', 'ga')] += 1

legend_items = []
legend_items.append(f'- **Products**: {product_count}')
legend_items.append(f'- **Features**: {feature_count}')
if readiness_counts:
    parts = []
    for r in ['ga', 'beta', 'planned']:
        if readiness_counts[r]:
            labels = {'ga': 'GA (green)', 'beta': 'Beta (amber)', 'planned': 'Planned (grey, dashed)'}
            parts.append(f'{readiness_counts[r]} {labels.get(r, r)}')
    legend_items.append(f'- **Readiness**: {', '.join(parts)}')
if bridge_pairs:
    legend_items.append(f'- **Cross-product bridges**: {len(bridge_pairs)} (shared categories shown as dotted links)')

legend = '\\n'.join(legend_items)

md = f'''# Portfolio Architecture

> Auto-generated on {today}. Do not edit manually — regenerated by the portfolio-architecture skill.

## {esc(company_name)} — Product & Feature Map

{legend}

\x60\x60\x60mermaid
{mermaid_code}
\x60\x60\x60

## Legend

| Symbol | Meaning |
|--------|---------|
| Solid green box | Feature — Generally Available (GA) |
| Rounded amber box | Feature — Beta / Pilot |
| Dashed grey box | Feature — Planned / Roadmap |
| Dotted line | Cross-product bridge (shared capability category) |
| Outer box | Product (with maturity and revenue model) |
| Inner box | Feature category grouping |
'''

# Ensure output directory exists
output_dir = os.path.join(project_dir, 'output')
os.makedirs(output_dir, exist_ok=True)

output_path = os.path.join(output_dir, 'architecture.md')
with open(output_path, 'w') as f:
    f.write(md)

print(json.dumps({
    'status': 'ok',
    'path': output_path,
    'products': product_count,
    'features': feature_count,
    'readiness': dict(readiness_counts)
}))
" "$PROJECT_DIR"

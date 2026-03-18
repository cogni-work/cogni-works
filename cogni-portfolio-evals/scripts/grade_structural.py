#!/usr/bin/env python3
"""Grade portfolio eval outputs against structural assertions.

Usage:
    python grade_structural.py <outputs_dir> [--type features|propositions|customers|compete|markets]

Reads all .json files in <outputs_dir> and checks structural assertions.
Writes grading.json to the parent of outputs_dir (the run directory).
"""

import json
import re
import sys
from pathlib import Path


def count_words(text: str) -> int:
    """Count words in a string, handling German compound words correctly."""
    if not text:
        return 0
    return len(text.split())


def check_outcome_verbs(text: str) -> list[str]:
    """Check for outcome verbs that don't belong in IS-layer descriptions."""
    outcome_patterns = [
        r'\breduc\w+', r'\benabl\w+', r'\bensur\w+', r'\bdamit\b',
        r'\breduzier\w+', r'\bermöglich\w+', r'\bsicher\w*stell\w+',
        r'\boptimier\w+', r'\bverbess\w+', r'\bsteiger\w+',
        r'\bsav\w+\s+(?:time|cost|money)', r'\bimprov\w+',
    ]
    found = []
    for pat in outcome_patterns:
        matches = re.findall(pat, text, re.IGNORECASE)
        if matches:
            found.extend(matches)
    return found


def check_parity_adjectives(text: str) -> list[str]:
    """Check for meaningless parity adjectives."""
    parity_patterns = [
        r'\brobust\w*\b', r'\binnovativ\w*\b', r'\bcutting[- ]edge\b',
        r'\bbest[- ]in[- ]class\b', r'\bstate[- ]of[- ]the[- ]art\b',
        r'\bleading\b', r'\bweltwei\w*\s+führend\w*\b', r'\bmodernst\w*\b',
        r'\bnahtlos\w*\b', r'\bseamless\w*\b', r'\bumfassend\w*\b',
        r'\bholistic\w*\b', r'\bganzheitlich\w*\b',
    ]
    found = []
    for pat in parity_patterns:
        matches = re.findall(pat, text, re.IGNORECASE)
        if matches:
            found.extend(matches)
    return found


def check_vendor_centric(text: str) -> list[str]:
    """Check for vendor-centric language in DOES statements."""
    vendor_patterns = [
        r'\bunsere?\s+(?:Lösung|Plattform|Service)\b',
        r'\bour\s+(?:solution|platform|service)\b',
        r'\bit\s+provides\b', r'\bwe\s+(?:offer|deliver|enable)\b',
        r'\bwir\s+(?:bieten|liefern|ermöglichen)\b',
        r'\bdie\s+(?:Lösung|Plattform)\s+(?:bietet|ermöglicht|liefert)\b',
    ]
    found = []
    for pat in vendor_patterns:
        matches = re.findall(pat, text, re.IGNORECASE)
        if matches:
            found.extend(matches)
    return found


def check_quantification(text: str) -> bool:
    """Check if MEANS contains quantification signals."""
    quant_patterns = [
        r'\d+', r'%', r'€', r'\bEUR\b', r'\bMio\b', r'\bMillionen\b',
        r'\bprozent\b', r'\bpercent\b', r'\bhalbier\w+\b', r'\bverdoppel\w+\b',
        r'\bdrittel\b', r'\bviertel\b', r'\breduc\w+\s+by\b',
        r'\breduzier\w+\s+um\b', r'\bsenk\w+\s+um\b',
    ]
    for pat in quant_patterns:
        if re.search(pat, text, re.IGNORECASE):
            return True
    return False


# Region → default currency mapping (from regions.json)
REGION_CURRENCIES = {
    'de': 'EUR', 'dach': 'EUR', 'eu': 'EUR', 'uk': 'GBP',
    'nordics': 'EUR', 'us': 'USD', 'na': 'USD', 'cn': 'CNY',
    'apac': 'USD', 'jp': 'JPY', 'latam': 'USD', 'mea': 'USD',
    'global': 'USD',
}

VALID_REGIONS = set(REGION_CURRENCIES.keys())
VALID_PRIORITIES = {'beachhead', 'expansion', 'aspirational'}


def grade_market(market: dict) -> list[dict]:
    """Grade a single market against structural assertions."""
    results = []

    slug = market.get('slug', '')
    name = market.get('name', '')
    region = market.get('region', '')
    desc = market.get('description', '')
    segmentation = market.get('segmentation', {})
    priority = market.get('priority', '')
    tam = market.get('tam', {})
    sam = market.get('sam', {})
    som = market.get('som', {})

    # M-01: Required fields
    required = ['slug', 'name', 'region', 'description']
    missing = [f for f in required if not market.get(f)]
    results.append({
        'text': 'All required fields present (slug, name, region, description)',
        'passed': len(missing) == 0,
        'evidence': f'Missing: {missing}' if missing else 'All present'
    })

    # M-02: Valid region code
    results.append({
        'text': f'Valid region code (actual: {region})',
        'passed': region in VALID_REGIONS,
        'evidence': f'region="{region}"'
    })

    # M-03: Slug ends with -{region}
    slug_ok = slug.endswith(f'-{region}') if region else False
    results.append({
        'text': 'Slug ends with -{region}',
        'passed': slug_ok,
        'evidence': f'slug="{slug}", region="{region}"'
    })

    # M-04: Description is 1 sentence (5-30 words)
    desc_wc = count_words(desc)
    sentence_ends = len(re.findall(r'[.!?]', desc))
    results.append({
        'text': f'Description is 1 sentence, 5-30 words (actual: {desc_wc} words, {sentence_ends} sentence-enders)',
        'passed': 5 <= desc_wc <= 30 and sentence_ends <= 1,
        'evidence': f'"{desc[:100]}"'
    })

    # M-05: Valid priority (skip if absent)
    if priority:
        results.append({
            'text': f'Priority is beachhead/expansion/aspirational (actual: {priority})',
            'passed': priority in VALID_PRIORITIES,
            'evidence': f'priority="{priority}"'
        })

    # M-06: Currency matches region default
    expected_currency = REGION_CURRENCIES.get(region, '')
    for label, sizing in [('TAM', tam), ('SAM', sam), ('SOM', som)]:
        currency = sizing.get('currency', '')
        if currency:
            results.append({
                'text': f'{label} currency matches region default ({expected_currency})',
                'passed': currency == expected_currency,
                'evidence': f'{label}.currency="{currency}", expected="{expected_currency}"'
            })

    # M-07: SAM/TAM ratio < 50%
    tam_val = tam.get('value', 0)
    sam_val = sam.get('value', 0)
    som_val = som.get('value', 0)
    if tam_val > 0 and sam_val > 0:
        ratio = sam_val / tam_val
        results.append({
            'text': f'SAM/TAM ratio < 50% (actual: {ratio:.1%})',
            'passed': ratio < 0.5,
            'evidence': f'SAM={sam_val:,.0f} / TAM={tam_val:,.0f} = {ratio:.1%}'
        })

    # M-08: SOM/SAM ratio < 20%
    if sam_val > 0 and som_val > 0:
        ratio = som_val / sam_val
        results.append({
            'text': f'SOM/SAM ratio < 20% (actual: {ratio:.1%})',
            'passed': ratio < 0.2,
            'evidence': f'SOM={som_val:,.0f} / SAM={sam_val:,.0f} = {ratio:.1%}'
        })

    # M-09: Normalized segmentation fields
    if segmentation:
        norm_fields = ['employees_min', 'employees_max', 'vertical_codes']
        norm_missing = [f for f in norm_fields if f not in segmentation]
        results.append({
            'text': 'Segmentation has normalized fields (employees_min/max, vertical_codes)',
            'passed': len(norm_missing) == 0,
            'evidence': f'Missing: {norm_missing}' if norm_missing else 'All normalized fields present'
        })

    return results


def grade_feature(feature: dict) -> list[dict]:
    """Grade a single feature against structural assertions."""
    results = []
    desc = feature.get('description', '')
    wc = count_words(desc)

    # F-01: Word count 20-35
    results.append({
        'text': f'Feature description word count 20-35 (actual: {wc})',
        'passed': 20 <= wc <= 35,
        'evidence': f'"{desc[:80]}..." ({wc} words)'
    })

    # F-02: Required fields
    required = ['slug', 'product_slug', 'name', 'description']
    missing = [f for f in required if not feature.get(f)]
    results.append({
        'text': 'All required fields present (slug, product_slug, name, description)',
        'passed': len(missing) == 0,
        'evidence': f'Missing: {missing}' if missing else 'All present'
    })

    # F-04: taxonomy_mapping
    tm = feature.get('taxonomy_mapping', {})
    tm_fields = ['dimension', 'category_id', 'category_name']
    tm_missing = [f for f in tm_fields if not tm.get(f)]
    results.append({
        'text': 'taxonomy_mapping present with dimension, category_id, category_name',
        'passed': len(tm_missing) == 0,
        'evidence': f'Missing: {tm_missing}' if tm_missing else f'Mapped to {tm.get("category_name", "?")}'
    })

    # F-05: readiness enum
    readiness = feature.get('readiness', '')
    results.append({
        'text': 'readiness is one of ga, beta, planned',
        'passed': readiness in ('ga', 'beta', 'planned'),
        'evidence': f'readiness="{readiness}"'
    })

    # F-06: No outcome verbs
    outcome_verbs = check_outcome_verbs(desc)
    results.append({
        'text': 'No outcome verbs in description',
        'passed': len(outcome_verbs) == 0,
        'evidence': f'Found: {outcome_verbs}' if outcome_verbs else 'Clean'
    })

    # F-07: No parity adjectives
    parity = check_parity_adjectives(desc)
    results.append({
        'text': 'No parity adjectives in description',
        'passed': len(parity) == 0,
        'evidence': f'Found: {parity}' if parity else 'Clean'
    })

    return results


def grade_proposition(prop: dict) -> list[dict]:
    """Grade a single proposition against structural assertions."""
    results = []

    is_stmt = prop.get('is_statement', '')
    does_stmt = prop.get('does_statement', '')
    means_stmt = prop.get('means_statement', '')

    is_wc = count_words(is_stmt)
    does_wc = count_words(does_stmt)
    means_wc = count_words(means_stmt)

    # P-01: DOES word count
    results.append({
        'text': f'DOES statement 15-30 words (actual: {does_wc})',
        'passed': 15 <= does_wc <= 30,
        'evidence': f'"{does_stmt[:80]}..."'
    })

    # P-02: MEANS word count
    results.append({
        'text': f'MEANS statement 15-30 words (actual: {means_wc})',
        'passed': 15 <= means_wc <= 30,
        'evidence': f'"{means_stmt[:80]}..."'
    })

    # P-03: IS word count
    results.append({
        'text': f'IS statement 20-35 words (actual: {is_wc})',
        'passed': 20 <= is_wc <= 35,
        'evidence': f'"{is_stmt[:80]}..."'
    })

    # P-06: Slug convention
    slug = prop.get('slug', '')
    feature_slug = prop.get('feature_slug', '')
    market_slug = prop.get('market_slug', '')
    expected_slug = f'{feature_slug}--{market_slug}'
    results.append({
        'text': 'Slug follows {feature}--{market} convention',
        'passed': slug == expected_slug,
        'evidence': f'slug="{slug}", expected="{expected_slug}"'
    })

    # P-07: DOES not vendor-centric
    vendor = check_vendor_centric(does_stmt)
    results.append({
        'text': 'DOES is not vendor-centric',
        'passed': len(vendor) == 0,
        'evidence': f'Found: {vendor}' if vendor else 'Clean'
    })

    # P-08: MEANS quantification
    has_quant = check_quantification(means_stmt)
    results.append({
        'text': 'MEANS contains quantification signal',
        'passed': has_quant,
        'evidence': f'"{means_stmt[:80]}..."'
    })

    # P-09: Evidence non-empty
    evidence = prop.get('evidence', [])
    results.append({
        'text': 'Evidence array is non-empty',
        'passed': len(evidence) > 0,
        'evidence': f'{len(evidence)} evidence entries'
    })

    return results


def grade_customer(cust: dict) -> list[dict]:
    """Grade a customer file against structural assertions."""
    results = []

    profiles = cust.get('profiles', [])
    results.append({
        'text': f'2-4 buyer profiles present (actual: {len(profiles)})',
        'passed': 2 <= len(profiles) <= 4,
        'evidence': f'{len(profiles)} profiles: {[p.get("role", "?") for p in profiles]}'
    })

    # C-02: Required profile fields
    required_fields = ['role', 'pain_points', 'buying_criteria', 'decision_role']
    all_have_fields = True
    missing_details = []
    for p in profiles:
        missing = [f for f in required_fields if not p.get(f)]
        if missing:
            all_have_fields = False
            missing_details.append(f'{p.get("role", "?")} missing: {missing}')
    results.append({
        'text': 'Each profile has role, pain_points, buying_criteria, decision_role',
        'passed': all_have_fields,
        'evidence': '; '.join(missing_details) if missing_details else 'All fields present'
    })

    # C-03: Pain points max 5
    over_limit = []
    for p in profiles:
        pp = p.get('pain_points', [])
        if len(pp) > 5:
            over_limit.append(f'{p.get("role", "?")}: {len(pp)} pain points')
    results.append({
        'text': 'Pain points max 5 items per profile',
        'passed': len(over_limit) == 0,
        'evidence': '; '.join(over_limit) if over_limit else 'All within limit'
    })

    # C-05: Named customers
    named = cust.get('named_customers', [])
    results.append({
        'text': f'3+ named customers present (actual: {len(named)})',
        'passed': len(named) >= 3,
        'evidence': f'{[n.get("name", "?") for n in named]}'
    })

    # C-06: Named customer required fields
    nc_required = ['name', 'fit_score', 'fit_rationale']
    nc_missing = []
    for n in named:
        missing = [f for f in nc_required if not n.get(f)]
        if missing:
            nc_missing.append(f'{n.get("name", "?")}: {missing}')
    results.append({
        'text': 'Each named customer has name, fit_score, fit_rationale',
        'passed': len(nc_missing) == 0,
        'evidence': '; '.join(nc_missing) if nc_missing else 'All fields present'
    })

    # C-08: Source URLs
    no_urls = [n.get('name', '?') for n in named if not n.get('source_urls')]
    results.append({
        'text': 'Source URLs present for named customers',
        'passed': len(no_urls) == 0,
        'evidence': f'Missing URLs: {no_urls}' if no_urls else 'All have URLs'
    })

    return results


def grade_competitor(comp: dict) -> list[dict]:
    """Grade a competitor file against structural assertions."""
    results = []

    competitors = comp.get('competitors', [])
    results.append({
        'text': f'3-5 competitors present (actual: {len(competitors)})',
        'passed': 3 <= len(competitors) <= 5,
        'evidence': f'{[c.get("name", "?") for c in competitors]}'
    })

    # K-02: Required fields
    required = ['positioning', 'strengths', 'weaknesses', 'differentiation']
    missing_details = []
    for c in competitors:
        missing = [f for f in required if not c.get(f)]
        if missing:
            missing_details.append(f'{c.get("name", "?")}: {missing}')
    results.append({
        'text': 'Each has positioning, strengths, weaknesses, differentiation',
        'passed': len(missing_details) == 0,
        'evidence': '; '.join(missing_details) if missing_details else 'All fields present'
    })

    # K-03: Strengths/weaknesses count
    count_issues = []
    for c in competitors:
        s = len(c.get('strengths', []))
        w = len(c.get('weaknesses', []))
        if not (2 <= s <= 5):
            count_issues.append(f'{c.get("name", "?")}: {s} strengths')
        if not (2 <= w <= 5):
            count_issues.append(f'{c.get("name", "?")}: {w} weaknesses')
    results.append({
        'text': 'Strengths and weaknesses 2-5 items each',
        'passed': len(count_issues) == 0,
        'evidence': '; '.join(count_issues) if count_issues else 'All within range'
    })

    # K-04: Trap questions
    trap_qs = comp.get('trap_questions', [])
    results.append({
        'text': f'2-4 trap questions present (actual: {len(trap_qs)})',
        'passed': 2 <= len(trap_qs) <= 4,
        'evidence': f'{len(trap_qs)} trap questions'
    })

    return results


def main():
    if len(sys.argv) < 2:
        print('Usage: python grade_structural.py <outputs_dir> [--type features|propositions|customers|compete]')
        sys.exit(1)

    outputs_dir = Path(sys.argv[1])
    entity_type = None
    if '--type' in sys.argv:
        idx = sys.argv.index('--type')
        entity_type = sys.argv[idx + 1]

    if not outputs_dir.exists():
        print(f'Directory not found: {outputs_dir}')
        sys.exit(1)

    # Exclude known non-entity files (assessment summaries, metrics, etc.)
    exclude_names = {'assessment.json', 'metrics.json', 'feature-summary.json'}
    json_files = sorted(f for f in outputs_dir.glob('*.json') if f.name not in exclude_names)
    if not json_files:
        print(f'No JSON files found in {outputs_dir}')
        sys.exit(1)

    all_results = []
    total_passed = 0
    total_checks = 0

    for jf in json_files:
        with open(jf) as f:
            data = json.load(f)

        # Auto-detect type if not specified
        file_type = entity_type
        if not file_type:
            if 'is_statement' in data or 'does_statement' in data:
                file_type = 'propositions'
            elif 'profiles' in data or 'named_customers' in data:
                file_type = 'customers'
            elif 'competitors' in data:
                file_type = 'compete'
            elif 'assessments' in data:
                # This is a features assessment summary, grade individual assessments
                file_type = 'features-assessment'
            elif 'region' in data and 'product_slug' not in data and 'is_statement' not in data:
                file_type = 'markets'
            elif 'description' in data and 'product_slug' in data:
                file_type = 'features'
            else:
                print(f'Cannot detect type for {jf.name}, skipping')
                continue

        if file_type == 'markets':
            checks = grade_market(data)
        elif file_type == 'features':
            checks = grade_feature(data)
        elif file_type == 'features-assessment':
            # Grade each feature in the assessment
            for feat in data.get('assessments', []):
                checks = grade_feature(feat)
                for c in checks:
                    c['entity'] = feat.get('slug', jf.stem)
                    total_checks += 1
                    if c['passed']:
                        total_passed += 1
                all_results.extend(checks)
            continue
        elif file_type == 'propositions':
            checks = grade_proposition(data)
        elif file_type == 'customers':
            checks = grade_customer(data)
        elif file_type == 'compete':
            checks = grade_competitor(data)
        else:
            continue

        for c in checks:
            c['entity'] = data.get('slug', jf.stem)
            total_checks += 1
            if c['passed']:
                total_passed += 1

        all_results.extend(checks)

    # Write grading.json
    run_dir = outputs_dir.parent
    grading = {
        'total_checks': total_checks,
        'passed': total_passed,
        'failed': total_checks - total_passed,
        'pass_rate': round(total_passed / total_checks, 3) if total_checks > 0 else 0,
        'expectations': all_results
    }

    grading_path = run_dir / 'grading.json'
    with open(grading_path, 'w') as f:
        json.dump(grading, f, indent=2, ensure_ascii=False)

    print(f'Graded {total_checks} checks: {total_passed} passed, {total_checks - total_passed} failed ({grading["pass_rate"]:.1%})')
    print(f'Results written to {grading_path}')

    # Print failures
    failures = [r for r in all_results if not r['passed']]
    if failures:
        print(f'\nFailures ({len(failures)}):')
        for f in failures:
            print(f'  [{f.get("entity", "?")}] {f["text"]}: {f["evidence"]}')


if __name__ == '__main__':
    main()

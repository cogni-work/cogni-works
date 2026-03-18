#!/usr/bin/env python3
"""Grade portfolio-scan eval outputs against structural assertions.

Usage:
    python grade_scan.py <outputs_dir> [--min-domains N] [--min-features N] [--categories-json PATH]

Reads the scan outputs directory containing:
  - *-portfolio.md (the portfolio report)
  - scan-output.json (scan metadata)
  - features/*.json (imported feature files)

Writes grading.json to the parent of outputs_dir (the run directory).
"""

import json
import re
import sys
from pathlib import Path
from urllib.parse import urlparse


VALID_STATUSES = {"Confirmed", "Not Offered", "Emerging", "Extended"}
VALID_READINESS = {"ga", "beta", "planned"}

# Default valid category IDs (b2b-ict template, 57 categories)
DEFAULT_VALID_IDS = {
    "0.1", "0.2", "0.3", "0.4", "0.5", "0.6",
    "1.1", "1.2", "1.3", "1.4", "1.5", "1.6", "1.7",
    "2.1", "2.2", "2.3", "2.4", "2.5", "2.6", "2.7", "2.8", "2.9", "2.10",
    "3.1", "3.2", "3.3", "3.4", "3.5", "3.6", "3.7",
    "4.1", "4.2", "4.3", "4.4", "4.5", "4.6", "4.7", "4.8",
    "5.1", "5.2", "5.3", "5.4", "5.5", "5.6", "5.7",
    "6.1", "6.2", "6.3", "6.4", "6.5", "6.6", "6.7",
    "7.1", "7.2", "7.3", "7.4", "7.5",
}


def load_categories(categories_path: str | None) -> set[str]:
    """Load valid category IDs from categories.json or use defaults."""
    if categories_path and Path(categories_path).exists():
        with open(categories_path) as f:
            cats = json.load(f)
        return {c["id"] for c in cats}
    return DEFAULT_VALID_IDS


def find_report(outputs_dir: Path) -> Path | None:
    """Find the portfolio report markdown file."""
    for p in outputs_dir.glob("*-portfolio.md"):
        return p
    for p in outputs_dir.glob("*.md"):
        return p
    return None


def grade_report_structure(report_text: str) -> list[dict]:
    """Grade S-01 through S-03: dimension/category/status coverage."""
    results = []

    # S-01: All 8 dimensions (## 0. or ## 0 -- through ## 7.)
    dim_headers = re.findall(r'^##\s+(\d+)[\.\s]', report_text, re.MULTILINE)
    dims_found = sorted(set(dim_headers))
    expected_dims = [str(i) for i in range(8)]
    missing_dims = [d for d in expected_dims if d not in dims_found]
    results.append({
        "text": f"All 8 dimensions present in report (found {len(set(dim_headers))})",
        "passed": len(missing_dims) == 0,
        "evidence": f"Missing dimensions: {missing_dims}" if missing_dims else f"All 8 present: {dims_found}"
    })

    # S-02: All 57 categories (### X.Y)
    cat_headers = re.findall(r'^###\s+(\d+\.\d+)', report_text, re.MULTILINE)
    cats_found = set(cat_headers)
    missing_cats = DEFAULT_VALID_IDS - cats_found
    results.append({
        "text": f"All 57 categories present in report (found {len(cats_found)})",
        "passed": len(cats_found) >= 57,
        "evidence": f"Missing: {sorted(missing_cats)}" if missing_cats else "All 57 present"
    })

    # S-03: Every category has a discovery status tag
    status_tags = re.findall(r'\[Status:\s*([\w\s]+?)\]', report_text)
    valid_tags = [s.strip() for s in status_tags if s.strip() in VALID_STATUSES]
    cats_without_status = len(cats_found) - len(valid_tags)
    results.append({
        "text": f"Every category has discovery status tag ({len(valid_tags)} of {len(cats_found)})",
        "passed": len(valid_tags) >= len(cats_found) and len(valid_tags) > 0,
        "evidence": f"{len(valid_tags)} valid status tags for {len(cats_found)} categories"
    })

    return results


def grade_scan_metadata(metadata: dict) -> list[dict]:
    """Grade S-04: status totals from scan-output.json."""
    results = []
    summary = metadata.get("status_summary", {})
    total = sum(summary.get(k, 0) for k in ["confirmed", "not_offered", "emerging", "extended"])
    results.append({
        "text": f"scan-output.json status totals = 57 (actual: {total})",
        "passed": total == 57,
        "evidence": json.dumps(summary)
    })
    return results


def grade_evidence_quality(report_text: str, metadata: dict, min_domains: int) -> list[dict]:
    """Grade S-08 through S-10: evidence quality assertions."""
    results = []
    domains_analyzed = metadata.get("domains_analyzed", [])

    # S-08: Every confirmed offering has a Link field
    # Look for markdown table rows and check for links
    # Table rows look like: | Name | Description | Domain | [Link](url) | ...
    table_rows = re.findall(r'^\|(?:[^|]+\|)+\s*$', report_text, re.MULTILINE)
    empty_links = 0
    total_offerings = 0
    for row in table_rows:
        cells = [c.strip() for c in row.split("|")[1:-1]]
        if len(cells) >= 4 and cells[0] and cells[0] != "Name" and cells[0] != "---" and not cells[0].startswith("-"):
            total_offerings += 1
            # Check if any cell contains a markdown link
            has_link = any(re.search(r'\[.*?\]\(https?://[^\)]+\)', c) or re.match(r'https?://', c) for c in cells)
            if not has_link:
                empty_links += 1

    results.append({
        "text": f"Every confirmed offering has a Link field ({total_offerings - empty_links}/{total_offerings})",
        "passed": empty_links == 0 or total_offerings == 0,
        "evidence": f"{empty_links} offerings missing links out of {total_offerings} total"
    })

    # S-09: All Links from discovered domains
    all_urls = re.findall(r'https?://([^/\)\s]+)', report_text)
    analyzed_domains = set()
    for d in domains_analyzed:
        analyzed_domains.add(d.lower())
        # Also add common subdomains
        parts = d.lower().split(".")
        if len(parts) >= 2:
            base = ".".join(parts[-2:])
            analyzed_domains.add(base)

    foreign_domains = set()
    for url_domain in all_urls:
        url_domain = url_domain.lower()
        is_known = False
        for ad in analyzed_domains:
            if url_domain == ad or url_domain.endswith("." + ad):
                is_known = True
                break
        if not is_known:
            foreign_domains.add(url_domain)

    results.append({
        "text": f"All offering Links from discovered domains ({len(foreign_domains)} foreign)",
        "passed": len(foreign_domains) == 0,
        "evidence": f"Foreign domains: {sorted(foreign_domains)[:10]}" if foreign_domains else f"All from {sorted(analyzed_domains)}"
    })

    # S-10: Minimum domains analyzed
    results.append({
        "text": f"At least {min_domains} domain(s) analyzed (actual: {len(domains_analyzed)})",
        "passed": len(domains_analyzed) >= min_domains,
        "evidence": f"Domains: {domains_analyzed}"
    })

    return results


def grade_features(features_dir: Path, valid_ids: set[str], min_features: int) -> list[dict]:
    """Grade S-13 through S-16: feature import quality."""
    results = []
    feature_files = sorted(features_dir.glob("*.json"))

    if not feature_files:
        results.append({"text": f"Feature count >= {min_features} (actual: 0)", "passed": False, "evidence": "No feature files found"})
        results.append({"text": "Features have taxonomy_mapping with category_id", "passed": False, "evidence": "No features to check"})
        results.append({"text": "category_id matches valid category", "passed": False, "evidence": "No features to check"})
        results.append({"text": "Feature readiness is ga/beta/planned", "passed": False, "evidence": "No features to check"})
        return results

    # S-16: Feature count
    results.append({
        "text": f"Feature count >= {min_features} (actual: {len(feature_files)})",
        "passed": len(feature_files) >= min_features,
        "evidence": f"{len(feature_files)} feature files"
    })

    # Grade each feature
    missing_tm = []
    invalid_ids = []
    invalid_readiness = []

    for ff in feature_files:
        with open(ff) as f:
            feat = json.load(f)
        slug = feat.get("slug", ff.stem)

        # S-13: taxonomy_mapping.category_id exists
        tm = feat.get("taxonomy_mapping", {})
        cat_id = tm.get("category_id", "")
        if not cat_id:
            missing_tm.append(slug)

        # S-14: category_id is valid
        if cat_id and cat_id not in valid_ids:
            invalid_ids.append(f"{slug}: {cat_id}")

        # S-15: readiness enum
        readiness = feat.get("readiness", "")
        if readiness not in VALID_READINESS:
            invalid_readiness.append(f"{slug}: {readiness}")

    results.append({
        "text": f"Features have taxonomy_mapping with category_id ({len(feature_files) - len(missing_tm)}/{len(feature_files)})",
        "passed": len(missing_tm) == 0,
        "evidence": f"Missing: {missing_tm[:5]}" if missing_tm else "All present"
    })

    results.append({
        "text": f"category_id matches valid category ({len(feature_files) - len(invalid_ids)}/{len(feature_files)})",
        "passed": len(invalid_ids) == 0,
        "evidence": f"Invalid: {invalid_ids[:5]}" if invalid_ids else "All valid"
    })

    results.append({
        "text": f"Feature readiness is ga/beta/planned ({len(feature_files) - len(invalid_readiness)}/{len(feature_files)})",
        "passed": len(invalid_readiness) == 0,
        "evidence": f"Invalid: {invalid_readiness[:5]}" if invalid_readiness else "All valid"
    })

    return results


def main():
    if len(sys.argv) < 2:
        print("Usage: python grade_scan.py <outputs_dir> [--min-domains N] [--min-features N] [--categories-json PATH]")
        sys.exit(1)

    outputs_dir = Path(sys.argv[1])
    min_domains = 1
    min_features = 10
    categories_path = None

    args = sys.argv[2:]
    i = 0
    while i < len(args):
        if args[i] == "--min-domains" and i + 1 < len(args):
            min_domains = int(args[i + 1])
            i += 2
        elif args[i] == "--min-features" and i + 1 < len(args):
            min_features = int(args[i + 1])
            i += 2
        elif args[i] == "--categories-json" and i + 1 < len(args):
            categories_path = args[i + 1]
            i += 2
        else:
            i += 1

    if not outputs_dir.exists():
        print(f"Directory not found: {outputs_dir}")
        sys.exit(1)

    valid_ids = load_categories(categories_path)
    all_results = []

    # Find and grade the portfolio report
    report_path = find_report(outputs_dir)
    if report_path:
        report_text = report_path.read_text()
        all_results.extend(grade_report_structure(report_text))
    else:
        all_results.append({"text": "Portfolio report found", "passed": False, "evidence": "No *-portfolio.md found"})

    # Grade scan-output.json
    metadata_path = outputs_dir / "scan-output.json"
    metadata = {}
    if metadata_path.exists():
        with open(metadata_path) as f:
            metadata = json.load(f)
        all_results.extend(grade_scan_metadata(metadata))
    else:
        all_results.append({"text": "scan-output.json found", "passed": False, "evidence": "File not found"})

    # Grade evidence quality (needs both report + metadata)
    if report_path and metadata:
        all_results.extend(grade_evidence_quality(report_path.read_text(), metadata, min_domains))

    # Grade imported features
    features_dir = outputs_dir / "features"
    if features_dir.exists():
        all_results.extend(grade_features(features_dir, valid_ids, min_features))
    else:
        all_results.append({"text": f"Feature count >= {min_features}", "passed": False, "evidence": "features/ directory not found"})

    # Aggregate
    total_checks = len(all_results)
    total_passed = sum(1 for r in all_results if r["passed"])

    grading = {
        "total_checks": total_checks,
        "passed": total_passed,
        "failed": total_checks - total_passed,
        "pass_rate": round(total_passed / total_checks, 3) if total_checks > 0 else 0,
        "expectations": all_results,
    }

    run_dir = outputs_dir.parent
    grading_path = run_dir / "grading.json"
    with open(grading_path, "w") as f:
        json.dump(grading, f, indent=2, ensure_ascii=False)

    print(f"Graded {total_checks} checks: {total_passed} passed, {total_checks - total_passed} failed ({grading['pass_rate']:.1%})")
    print(f"Results written to {grading_path}")

    failures = [r for r in all_results if not r["passed"]]
    if failures:
        print(f"\nFailures ({len(failures)}):")
        for f_ in failures:
            print(f"  {f_['text']}: {f_['evidence']}")


if __name__ == "__main__":
    main()

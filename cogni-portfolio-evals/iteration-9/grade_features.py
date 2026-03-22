#!/usr/bin/env python3
"""Grade feature outputs against density assertions."""
import json, glob, re, sys, os

def grade_features(features_dir):
    """Grade all feature JSON files in a directory."""
    files = glob.glob(os.path.join(features_dir, "*.json"))
    features = []
    for f in files:
        with open(f) as fh:
            features.append(json.load(fh))

    if not features:
        return {"error": "No feature files found", "features": []}

    results = {
        "feature_count": len(features),
        "features": [],
        "assertions": {}
    }

    # Per-feature analysis
    long_slugs = []
    dense_descriptions = []
    word_count_violations = []
    outcome_language = []

    for feat in features:
        slug = feat.get("slug", "unknown")
        desc = feat.get("description", "")
        name = feat.get("name", "")

        # Slug length
        segments = slug.split("-")
        slug_len = len(segments)

        # Word count
        words = desc.split()
        wc = len(words)

        # Density: count comma-separated parallel components
        # Simple heuristic: count commas in description
        comma_count = desc.count(",")
        # Also count "und"/"and" as potential list separators
        und_count = len(re.findall(r'\bund\b|\band\b', desc))
        parallel_items = comma_count + und_count

        # Outcome language check
        outcome_verbs = re.findall(
            r'\b(enables?|reduces?|ensures?|hilft|ermöglicht|verbessert|steigert|optimiert|damit)\b',
            desc, re.IGNORECASE
        )

        feat_result = {
            "slug": slug,
            "name": name,
            "description": desc,
            "slug_segments": slug_len,
            "word_count": wc,
            "comma_count": comma_count,
            "parallel_items_estimate": parallel_items,
            "outcome_verbs_found": outcome_verbs
        }
        results["features"].append(feat_result)

        if slug_len > 3:
            long_slugs.append(slug)
        if parallel_items >= 3:
            dense_descriptions.append(slug)
        if wc < 20 or wc > 35:
            word_count_violations.append({"slug": slug, "wc": wc})
        if outcome_verbs:
            outcome_language.append({"slug": slug, "verbs": outcome_verbs})

    # Assertion results
    results["assertions"] = {
        "no-long-slugs": {
            "passed": len(long_slugs) == 0,
            "evidence": f"Long slugs (>3 segments): {long_slugs}" if long_slugs else "All slugs ≤3 segments"
        },
        "no-density": {
            "passed": len(dense_descriptions) == 0,
            "evidence": f"Dense descriptions (3+ parallel items): {dense_descriptions}" if dense_descriptions else "No dense descriptions found"
        },
        "word-count": {
            "passed": len(word_count_violations) == 0,
            "evidence": f"Word count violations: {word_count_violations}" if word_count_violations else "All descriptions 20-35 words"
        },
        "no-outcome-language": {
            "passed": len(outcome_language) == 0,
            "evidence": f"Outcome language found: {outcome_language}" if outcome_language else "No outcome language found"
        }
    }

    passed = sum(1 for a in results["assertions"].values() if a["passed"])
    total = len(results["assertions"])
    results["pass_rate"] = f"{passed}/{total}"

    return results

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: grade_features.py <features_dir>")
        sys.exit(1)

    result = grade_features(sys.argv[1])
    print(json.dumps(result, indent=2, ensure_ascii=False))

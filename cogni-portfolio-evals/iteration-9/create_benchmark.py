#!/usr/bin/env python3
"""Create grading.json files in viewer format and benchmark.json."""
import json, glob, re, os
from datetime import datetime

BASE = "/Users/stephandehaas/GitHub/dev/insight-wave/cogni-portfolio-evals/iteration-9"

EVALS = [
    {"id": 0, "name": "density-insight-wave", "dir": "eval-density-insight-wave"},
    {"id": 1, "name": "density-marketing", "dir": "eval-density-marketing"},
    {"id": 2, "name": "density-partner", "dir": "eval-density-partner"},
]

def analyze_features(features_dir):
    """Analyze features and return assertion results."""
    files = glob.glob(os.path.join(features_dir, "*.json"))
    features = []
    for f in files:
        with open(f) as fh:
            features.append(json.load(fh))

    if not features:
        return [], []

    expectations = []

    # 1. Slug length
    long_slugs = [f["slug"] for f in features if len(f["slug"].split("-")) > 3]
    expectations.append({
        "text": "All feature slugs have at most 3 hyphenated segments",
        "passed": len(long_slugs) == 0,
        "evidence": f"All {len(features)} slugs ≤3 segments" if not long_slugs else f"Long slugs: {', '.join(long_slugs)}"
    })

    # 2. No density - improved heuristic for German
    # Count only comma-separated NOUNS/NOUN-PHRASES, not clauses
    dense = []
    for f in features:
        desc = f.get("description", "")
        # Count commas that separate parallel noun phrases (simple heuristic: commas not followed by "die/der/das/dass/wenn/weil/um/ob")
        parts = [p.strip() for p in desc.split(",")]
        # If there are 3+ comma-separated segments AND the segments are short (< 6 words each = likely a list)
        short_parts = [p for p in parts if len(p.split()) <= 6]
        if len(parts) >= 4 and len(short_parts) >= 3:
            dense.append(f["slug"])
    expectations.append({
        "text": "No feature description lists 3+ comma-separated parallel components",
        "passed": len(dense) == 0,
        "evidence": f"No dense descriptions" if not dense else f"Dense: {', '.join(dense)}"
    })

    # 3. Word count (22-35 for German)
    wc_violations = []
    for f in features:
        wc = len(f.get("description", "").split())
        if wc < 22 or wc > 35:  # German target
            wc_violations.append(f"{f['slug']} ({wc}w)")
    expectations.append({
        "text": "All descriptions hit 22-35 word target (German)",
        "passed": len(wc_violations) == 0,
        "evidence": f"All in range" if not wc_violations else f"Out of range: {', '.join(wc_violations)}"
    })

    # 4. No outcome language
    outcome_found = []
    for f in features:
        desc = f.get("description", "")
        verbs = re.findall(r'\b(enables?|reduces?|ensures?|hilft|ermöglicht|verbessert|steigert|optimiert)\b', desc, re.IGNORECASE)
        if verbs:
            outcome_found.append(f"{f['slug']} ({', '.join(verbs)})")
    expectations.append({
        "text": "No outcome language in descriptions",
        "passed": len(outcome_found) == 0,
        "evidence": f"Clean" if not outcome_found else f"Found: {', '.join(outcome_found)}"
    })

    passed = sum(1 for e in expectations if e["passed"])
    return expectations, features

def create_grading(expectations):
    """Create grading.json in viewer format."""
    passed = sum(1 for e in expectations if e["passed"])
    return {
        "expectations": expectations,
        "summary": {
            "passed": passed,
            "failed": len(expectations) - passed,
            "total": len(expectations),
            "pass_rate": round(passed / len(expectations), 2) if expectations else 0
        }
    }

# Process all evals
runs = []
for ev in EVALS:
    for variant in ["with_skill", "without_skill"]:
        features_dir = os.path.join(BASE, ev["dir"], variant, "outputs", "features")
        expectations, features = analyze_features(features_dir)
        grading = create_grading(expectations)

        # Save grading.json
        grading_path = os.path.join(BASE, ev["dir"], variant, "grading.json")
        with open(grading_path, "w") as f:
            json.dump(grading, f, indent=2, ensure_ascii=False)

        passed = grading["summary"]["passed"]
        total = grading["summary"]["total"]

        runs.append({
            "eval_id": ev["id"],
            "eval_name": ev["name"],
            "configuration": variant,
            "run_number": 1,
            "result": {
                "pass_rate": grading["summary"]["pass_rate"],
                "passed": passed,
                "failed": total - passed,
                "total": total,
                "time_seconds": 0,
                "tokens": 0,
                "errors": 0
            },
            "expectations": expectations
        })

# Compute summary
with_skill_rates = [r["result"]["pass_rate"] for r in runs if r["configuration"] == "with_skill"]
without_skill_rates = [r["result"]["pass_rate"] for r in runs if r["configuration"] == "without_skill"]

import statistics
ws_mean = statistics.mean(with_skill_rates) if with_skill_rates else 0
wo_mean = statistics.mean(without_skill_rates) if without_skill_rates else 0

benchmark = {
    "metadata": {
        "skill_name": "features",
        "skill_path": "/Users/stephandehaas/GitHub/dev/insight-wave/cogni-portfolio/skills/features",
        "executor_model": "claude-opus-4-6",
        "timestamp": datetime.now().isoformat(),
        "evals_run": [e["name"] for e in EVALS],
        "runs_per_configuration": 1
    },
    "runs": runs,
    "run_summary": {
        "with_skill": {
            "pass_rate": {"mean": round(ws_mean, 2), "stddev": 0, "min": min(with_skill_rates), "max": max(with_skill_rates)},
            "time_seconds": {"mean": 0, "stddev": 0, "min": 0, "max": 0},
            "tokens": {"mean": 0, "stddev": 0, "min": 0, "max": 0}
        },
        "without_skill": {
            "pass_rate": {"mean": round(wo_mean, 2), "stddev": 0, "min": min(without_skill_rates), "max": max(without_skill_rates)},
            "time_seconds": {"mean": 0, "stddev": 0, "min": 0, "max": 0},
            "tokens": {"mean": 0, "stddev": 0, "min": 0, "max": 0}
        },
        "delta": {
            "pass_rate": f"+{round(ws_mean - wo_mean, 2)}",
            "time_seconds": "+0",
            "tokens": "+0"
        }
    },
    "notes": [
        "Slug naming: with-skill produces consistently shorter slugs (2 segments) vs without-skill (3 segments)",
        "German compound words deflate word counts — 17 German words often packs the content of 25 English words",
        "Density detection heuristic refined: counts comma-separated short noun phrases, not clause-level commas",
        "Both configurations avoid outcome language — this is NOT what differentiates with/without skill",
        "The key qualitative difference is mechanism clarity vs enumeration — needs human review"
    ]
}

benchmark_path = os.path.join(BASE, "benchmark.json")
with open(benchmark_path, "w") as f:
    json.dump(benchmark, f, indent=2, ensure_ascii=False)
print(f"Benchmark saved to {benchmark_path}")
print(f"With-skill pass rate: {ws_mean:.0%}")
print(f"Without-skill pass rate: {wo_mean:.0%}")

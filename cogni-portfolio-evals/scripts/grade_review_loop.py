#!/usr/bin/env python3
"""Grade propositions through a closed CSO/CDO review loop with auto-rewrite.

This script orchestrates the review loop as a grading tool — it reads pre-generated
reviewer JSON files and proposition JSONs, scores them, and produces grading.json
compatible with the eval viewer.

The actual agent invocations (CSO reviewer, CDO reviewer, quality-enricher) are
handled by the eval runner (subagent) that calls this script between iterations.
This script focuses on scoring, convergence detection, and feedback synthesis.

Usage:
    # Score a single iteration's reviews
    python grade_review_loop.py score <run_dir>
        --cso-review <cso-review.json>
        --cdo-review <cdo-review.json>
        --threshold-avg 4.0
        --threshold-min-dim 3

    # Synthesize rewrite instructions for failing propositions
    python grade_review_loop.py synthesize <run_dir>
        --cso-review <cso-review.json>
        --cdo-review <cdo-review.json>
        --threshold-avg 4.0
        --threshold-min-dim 3

    # Check convergence across iterations
    python grade_review_loop.py converge <run_dir>
        --iterations-dir <reviews_dir>
        --max-iterations 3

    # Full grading (structural + review-loop assertions)
    python grade_review_loop.py grade <run_dir>
        --cso-review <cso-review.json>
        --cdo-review <cdo-review.json>
"""

import json
import sys
from pathlib import Path
from typing import Optional


# --- Dimension mapping: stakeholder → quality-assessor format ---

CSO_TO_QUALITY = {
    "quota_impact": [("means", "outcome_specificity")],
    "pipeline_acceleration": [("does", "status_quo_contrast"), ("means", "emotional_resonance")],
    "objection_handling": [("does", "differentiation"), ("means", "quantification")],
    "competitive_win_ability": [("does", "differentiation")],
    "account_team_usability": [("does", "conciseness"), ("means", "conciseness")],
    "deal_qualification_signal": [("does", "market_specificity")],
}

CDO_TO_QUALITY = {
    "pain_point_accuracy": [("does", "market_specificity")],
    "buying_vision": [("does", "buyer_centricity"), ("means", "escalation")],
    "credibility": [("means", "quantification")],
    "decision_support": [("means", "outcome_specificity")],
    "language_fit": [("does", "conciseness"), ("means", "conciseness")],
}

CSO_DIMENSIONS = [
    "quota_impact", "pipeline_acceleration", "objection_handling",
    "competitive_win_ability", "account_team_usability", "deal_qualification_signal",
]

CDO_DIMENSIONS = [
    "pain_point_accuracy", "buying_vision", "credibility",
    "decision_support", "language_fit",
]
# trap_question_effectiveness excluded from scoring (only for compete entities)


def load_json(path: Path) -> dict:
    with open(path) as f:
        return json.load(f)


def save_json(path: Path, data: dict):
    with open(path, "w") as f:
        json.dump(data, f, indent=2, ensure_ascii=False)


def score_proposition(cso_review: dict, cdo_review: dict) -> dict:
    """Score a proposition based on both reviewer outputs."""
    cso_scores = cso_review.get("dimension_scores", {})
    cdo_scores = cdo_review.get("dimension_scores", {})

    cso_vals = [cso_scores[d]["score"] for d in CSO_DIMENSIONS if d in cso_scores]
    cdo_vals = [
        cdo_scores[d]["score"]
        for d in CDO_DIMENSIONS
        if d in cdo_scores and cdo_scores[d]["score"] is not None
    ]

    cso_avg = sum(cso_vals) / len(cso_vals) if cso_vals else 0
    cdo_avg = sum(cdo_vals) / len(cdo_vals) if cdo_vals else 0
    combined_avg = (cso_avg + cdo_avg) / 2

    all_scores = cso_vals + cdo_vals
    min_dim = min(all_scores) if all_scores else 0

    return {
        "cso_avg": round(cso_avg, 2),
        "cdo_avg": round(cdo_avg, 2),
        "combined_avg": round(combined_avg, 2),
        "min_dim": min_dim,
        "cso_scores": {d: cso_scores[d]["score"] for d in CSO_DIMENSIONS if d in cso_scores},
        "cdo_scores": {
            d: cdo_scores[d]["score"]
            for d in CDO_DIMENSIONS
            if d in cdo_scores and cdo_scores[d]["score"] is not None
        },
        "would_take_meeting": cdo_review.get("would_take_meeting", False),
        "would_forward_to_cio": cdo_review.get("would_forward_to_cio", False),
        "would_use_in_pitch_deck": cso_review.get("would_use_in_pitch_deck", False),
    }


def proposition_passes(scores: dict, threshold_avg: float, threshold_min_dim: int) -> bool:
    """Check if a proposition meets all thresholds."""
    return (
        scores["cso_avg"] >= threshold_avg
        and scores["cdo_avg"] >= threshold_avg
        and scores["min_dim"] >= threshold_min_dim
        and scores["would_take_meeting"]
        and scores["would_use_in_pitch_deck"]
    )


def synthesize_feedback(
    slug: str, cso_review: dict, cdo_review: dict, scores: dict, threshold_min_dim: int
) -> dict:
    """Synthesize CSO + CDO feedback into quality-enricher format.

    Returns a quality assessment dict that the quality-enricher agent can consume.
    """
    cso_scores = cso_review.get("dimension_scores", {})
    cdo_scores = cdo_review.get("dimension_scores", {})

    # Collect issues from both reviewers for this proposition
    cso_issues = [
        i for i in cso_review.get("top_issues", []) if i.get("entity_slug") == slug
    ]
    cdo_issues = [
        i for i in cdo_review.get("top_issues", []) if i.get("entity_slug") == slug
    ]

    # Build quality-assessor format with merged feedback
    does_dims = {}
    means_dims = {}

    def score_to_quality(score_val: int, threshold: int) -> str:
        if score_val >= 4:
            return "pass"
        elif score_val >= threshold:
            return "warn"
        else:
            return "fail"

    def add_note(layer_dims: dict, dim_name: str, score_str: str, note: str):
        if dim_name in layer_dims:
            # Merge: take worse score, combine notes
            existing = layer_dims[dim_name]
            scores_order = {"fail": 0, "warn": 1, "pass": 2}
            if scores_order.get(score_str, 2) < scores_order.get(existing["score"], 2):
                existing["score"] = score_str
            if note and existing["note"]:
                existing["note"] += f"; {note}"
            elif note:
                existing["note"] = note
        else:
            layer_dims[dim_name] = {"score": score_str, "note": note}

    # Map CSO dimensions
    for cso_dim, mappings in CSO_TO_QUALITY.items():
        if cso_dim not in cso_scores:
            continue
        raw_score = cso_scores[cso_dim]["score"]
        quality = score_to_quality(raw_score, threshold_min_dim)
        rationale = cso_scores[cso_dim].get("rationale", "")
        note = f"[CSO {cso_dim}={raw_score}] {rationale}" if quality != "pass" else ""

        for layer, dim_name in mappings:
            target = does_dims if layer == "does" else means_dims
            add_note(target, dim_name, quality, note)

    # Map CDO dimensions
    for cdo_dim, mappings in CDO_TO_QUALITY.items():
        if cdo_dim not in cdo_scores or cdo_scores[cdo_dim]["score"] is None:
            continue
        raw_score = cdo_scores[cdo_dim]["score"]
        quality = score_to_quality(raw_score, threshold_min_dim)
        rationale = cdo_scores[cdo_dim].get("rationale", "")
        note = f"[CDO {cdo_dim}={raw_score}] {rationale}" if quality != "pass" else ""

        for layer, dim_name in mappings:
            target = does_dims if layer == "does" else means_dims
            add_note(target, dim_name, quality, note)

    # Ensure all standard dimensions exist
    for dim in ["buyer_centricity", "market_specificity", "differentiation", "status_quo_contrast", "conciseness"]:
        if dim not in does_dims:
            does_dims[dim] = {"score": "pass", "note": ""}
    for dim in ["outcome_specificity", "escalation", "quantification", "emotional_resonance", "conciseness"]:
        if dim not in means_dims:
            means_dims[dim] = {"score": "pass", "note": ""}

    # Determine overall
    def layer_overall(dims: dict) -> str:
        fail_count = sum(1 for d in dims.values() if d["score"] == "fail")
        warn_count = sum(1 for d in dims.values() if d["score"] == "warn")
        if fail_count >= 2:
            return "fail"
        elif fail_count == 1 or warn_count > 0:
            return "warn"
        return "pass"

    does_overall = layer_overall(does_dims)
    means_overall = layer_overall(means_dims)

    # Add top issues as additional context
    issue_notes = []
    for issue in cso_issues:
        issue_notes.append(f"[CSO] {issue['issue']}")
        if issue.get("suggested_fix"):
            issue_notes.append(f"  Fix: {issue['suggested_fix']}")
    for issue in cdo_issues:
        issue_notes.append(f"[CDO] {issue['issue']}")
        if issue.get("suggested_fix"):
            issue_notes.append(f"  Fix: {issue['suggested_fix']}")

    return {
        "slug": slug,
        "does_assessment": {
            "overall": does_overall,
            "dimensions": does_dims,
        },
        "means_assessment": {
            "overall": means_overall,
            "dimensions": means_dims,
        },
        "stakeholder_issues": issue_notes,
        "scores": scores,
    }


def cmd_score(run_dir: Path, cso_path: Path, cdo_path: Path, threshold_avg: float, threshold_min_dim: int):
    """Score propositions and write per-proposition results."""
    cso = load_json(cso_path)
    cdo = load_json(cdo_path)

    scores = score_proposition(cso, cdo)
    passes = proposition_passes(scores, threshold_avg, threshold_min_dim)

    result = {
        "scores": scores,
        "passes": passes,
        "threshold_avg": threshold_avg,
        "threshold_min_dim": threshold_min_dim,
    }

    out_path = run_dir / "review-scores.json"
    save_json(out_path, result)
    print(f"CSO avg: {scores['cso_avg']}, CDO avg: {scores['cdo_avg']}, combined: {scores['combined_avg']}")
    print(f"Min dimension: {scores['min_dim']}")
    print(f"Would take meeting: {scores['would_take_meeting']}")
    print(f"Would use in pitch deck: {scores['would_use_in_pitch_deck']}")
    print(f"Overall: {'PASS' if passes else 'FAIL'}")
    return result


def cmd_synthesize(run_dir: Path, cso_path: Path, cdo_path: Path, threshold_avg: float, threshold_min_dim: int):
    """Synthesize rewrite instructions for failing propositions."""
    cso = load_json(cso_path)
    cdo = load_json(cdo_path)

    scores = score_proposition(cso, cdo)
    passes = proposition_passes(scores, threshold_avg, threshold_min_dim)

    if passes:
        print("All propositions pass — no rewrites needed.")
        return []

    # For now, treat the whole review as one entity (future: per-proposition)
    # Use the top_issues from both reviewers to find slugs that need work
    failing_slugs = set()
    for issue in cso.get("top_issues", []) + cdo.get("top_issues", []):
        if issue.get("severity") in ("high", "critical"):
            slug = issue.get("entity_slug", "")
            if slug:
                failing_slugs.add(slug)

    # Also flag based on low dimension scores
    for dim in CSO_DIMENSIONS:
        if dim in cso.get("dimension_scores", {}) and cso["dimension_scores"][dim]["score"] < threshold_min_dim:
            # Can't determine exact slug from aggregate review, flag all
            pass

    rewrite_instructions = []
    for slug in failing_slugs:
        feedback = synthesize_feedback(slug, cso, cdo, scores, threshold_min_dim)
        rewrite_instructions.append(feedback)

    out_path = run_dir / "rewrite-instructions.json"
    save_json(out_path, rewrite_instructions)
    print(f"Generated rewrite instructions for {len(rewrite_instructions)} propositions: {list(failing_slugs)}")
    return rewrite_instructions


def cmd_converge(run_dir: Path, iterations_dir: Path, max_iterations: int):
    """Check convergence across iterations."""
    iteration_scores = []
    for i in range(max_iterations):
        scores_path = iterations_dir / f"iteration-{i}" / "review-scores.json"
        if scores_path.exists():
            data = load_json(scores_path)
            iteration_scores.append({
                "iteration": i,
                "combined_avg": data["scores"]["combined_avg"],
                "cso_avg": data["scores"]["cso_avg"],
                "cdo_avg": data["scores"]["cdo_avg"],
                "min_dim": data["scores"]["min_dim"],
                "passes": data["passes"],
            })

    if len(iteration_scores) < 2:
        print("Not enough iterations to check convergence.")
        return {"converged": False, "reason": "insufficient_iterations", "iterations": iteration_scores}

    latest = iteration_scores[-1]
    previous = iteration_scores[-2]

    converged = latest["passes"]
    stalled = latest["combined_avg"] <= previous["combined_avg"] and not converged

    result = {
        "converged": converged,
        "stalled": stalled,
        "reason": "passed" if converged else ("stalled" if stalled else "in_progress"),
        "iterations": iteration_scores,
    }

    out_path = run_dir / "convergence.json"
    save_json(out_path, result)

    if converged:
        print(f"Converged at iteration {latest['iteration']} (combined avg: {latest['combined_avg']})")
    elif stalled:
        print(f"Stalled at iteration {latest['iteration']} — no improvement ({latest['combined_avg']} <= {previous['combined_avg']})")
    else:
        delta = latest["combined_avg"] - previous["combined_avg"]
        print(f"Iteration {latest['iteration']}: combined_avg={latest['combined_avg']} (delta: {delta:+.2f})")

    return result


def cmd_grade(run_dir: Path, cso_path: Path, cdo_path: Path, threshold_avg: float = 4.0, threshold_min_dim: int = 3):
    """Generate grading.json with review-loop assertions (RL-* format)."""
    cso = load_json(cso_path)
    cdo = load_json(cdo_path)

    scores = score_proposition(cso, cdo)
    expectations = []

    # RL-01: CSO combined avg >= threshold
    expectations.append({
        "text": f"CSO combined avg >= {threshold_avg} (actual: {scores['cso_avg']})",
        "passed": scores["cso_avg"] >= threshold_avg,
        "evidence": f"CSO avg: {scores['cso_avg']}, dims: {scores['cso_scores']}",
    })

    # RL-02: CDO combined avg >= threshold
    expectations.append({
        "text": f"CDO combined avg >= {threshold_avg} (actual: {scores['cdo_avg']})",
        "passed": scores["cdo_avg"] >= threshold_avg,
        "evidence": f"CDO avg: {scores['cdo_avg']}, dims: {scores['cdo_scores']}",
    })

    # RL-03: No dimension below threshold_min_dim
    low_dims = []
    for dim, val in scores["cso_scores"].items():
        if val < threshold_min_dim:
            low_dims.append(f"CSO.{dim}={val}")
    for dim, val in scores["cdo_scores"].items():
        if val < threshold_min_dim:
            low_dims.append(f"CDO.{dim}={val}")
    expectations.append({
        "text": f"No dimension below {threshold_min_dim} from either reviewer",
        "passed": len(low_dims) == 0,
        "evidence": f"Low dims: {low_dims}" if low_dims else "All dimensions >= threshold",
    })

    # RL-04: CDO would_take_meeting
    expectations.append({
        "text": "CDO would_take_meeting is true",
        "passed": scores["would_take_meeting"],
        "evidence": f"would_take_meeting: {scores['would_take_meeting']}",
    })

    # RL-05: CSO would_use_in_pitch_deck
    expectations.append({
        "text": "CSO would_use_in_pitch_deck is true",
        "passed": scores["would_use_in_pitch_deck"],
        "evidence": f"would_use_in_pitch_deck: {scores['would_use_in_pitch_deck']}",
    })

    # Check for convergence data
    convergence_path = run_dir / "convergence.json"
    if convergence_path.exists():
        conv = load_json(convergence_path)
        expectations.append({
            "text": "Loop converged within max_iterations",
            "passed": conv.get("converged", False),
            "evidence": f"Reason: {conv.get('reason', 'unknown')}, iterations: {len(conv.get('iterations', []))}",
        })

    # Check if any rewrite happened
    rewrite_path = run_dir / "rewrite-instructions.json"
    if rewrite_path.exists():
        rewrites = load_json(rewrite_path)
        expectations.append({
            "text": "At least one proposition was rewritten (loop exercised)",
            "passed": len(rewrites) > 0,
            "evidence": f"{len(rewrites)} propositions rewritten",
        })

    total = len(expectations)
    passed = sum(1 for e in expectations if e["passed"])

    grading = {
        "total_checks": total,
        "passed": passed,
        "failed": total - passed,
        "pass_rate": round(passed / total, 3) if total > 0 else 0,
        "expectations": expectations,
        "review_scores": scores,
    }

    grading_path = run_dir / "grading-review-loop.json"
    save_json(grading_path, grading)
    print(f"Review loop grading: {passed}/{total} passed ({grading['pass_rate']:.1%})")

    failures = [e for e in expectations if not e["passed"]]
    if failures:
        print(f"\nFailures ({len(failures)}):")
        for f in failures:
            print(f"  {f['text']}: {f['evidence']}")

    return grading


def main():
    if len(sys.argv) < 3:
        print(__doc__)
        sys.exit(1)

    command = sys.argv[1]
    run_dir = Path(sys.argv[2])

    # Parse optional args
    args = {}
    i = 3
    while i < len(sys.argv):
        if sys.argv[i].startswith("--"):
            key = sys.argv[i].lstrip("-").replace("-", "_")
            if i + 1 < len(sys.argv) and not sys.argv[i + 1].startswith("--"):
                args[key] = sys.argv[i + 1]
                i += 2
            else:
                args[key] = True
                i += 1
        else:
            i += 1

    cso_path = Path(args.get("cso_review", "")) if "cso_review" in args else None
    cdo_path = Path(args.get("cdo_review", "")) if "cdo_review" in args else None
    threshold_avg = float(args.get("threshold_avg", 4.0))
    threshold_min_dim = int(args.get("threshold_min_dim", 3))

    if command == "score":
        if not cso_path or not cdo_path:
            print("score requires --cso-review and --cdo-review")
            sys.exit(1)
        cmd_score(run_dir, cso_path, cdo_path, threshold_avg, threshold_min_dim)

    elif command == "synthesize":
        if not cso_path or not cdo_path:
            print("synthesize requires --cso-review and --cdo-review")
            sys.exit(1)
        cmd_synthesize(run_dir, cso_path, cdo_path, threshold_avg, threshold_min_dim)

    elif command == "converge":
        iterations_dir = Path(args.get("iterations_dir", str(run_dir / "reviews")))
        max_iterations = int(args.get("max_iterations", 3))
        cmd_converge(run_dir, iterations_dir, max_iterations)

    elif command == "grade":
        if not cso_path or not cdo_path:
            print("grade requires --cso-review and --cdo-review")
            sys.exit(1)
        cmd_grade(run_dir, cso_path, cdo_path, threshold_avg, threshold_min_dim)

    else:
        print(f"Unknown command: {command}")
        print("Available: score, synthesize, converge, grade")
        sys.exit(1)


if __name__ == "__main__":
    main()

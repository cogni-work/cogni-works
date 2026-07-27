#!/usr/bin/env python3
"""check-version-bump.py — deterministic guard on plugin `version` lines.

Two independent assertions, both anchored on `.claude-plugin/marketplace.json`
as the single enumeration source of truth:

  1. MIRROR INVARIANT (every plugin, every mode, always).
     Each plugin's `<source>/.claude-plugin/plugin.json` `version` must equal the
     mirrored `version` on its root `marketplace.json` entry. Claude Desktop reads
     the marketplace copy for update detection, so advancing one without the other
     ships an invisible update. This check needs no git history, so it still runs
     (and still fails the build) when the git-anchored check below degrades.

  2. TOUCH / INCREMENT (git-anchored, mode-dependent).

     * `pr` mode (default) — a feature branch must NOT touch the version of any
       plugin whose files it changes. The bump is applied post-merge by
       `.github/workflows/cogni-version-bump.yml`, per plugin actually touched.

       Why the inversion. When every PR bumped the version at authoring time, that
       single line was the canonical merge-conflict class: the instant one PR
       merged, main's version advanced and every other open PR's version line
       became a textual conflict — a stale-below-main value or a same-value sibling
       collision. N-1 of N in-flight PRs were structurally guaranteed to conflict,
       and each merge cascaded into the next. Moving the bump post-merge removes
       the line the PRs fought over; this gate enforces that at PR time.

     * `post-merge` mode — restores the strict-greater assertion so the bump
       workflow can verify its own freshly written increment before pushing:
       `version-not-incremented` when equal, `version-regressed` when lower.

Both git references are fork-point relative, on purpose:

  * WHICH plugins to check — the touched set, from the three-dot diff
    `git diff --name-only <base>...HEAD`.
  * WHAT to compare against — the version at the MERGE-BASE, via
    `git show $(git merge-base <base> HEAD):<source>/.claude-plugin/plugin.json`.

Anchoring on the merge-base rather than the base ref TIP is what makes "untouched"
drift-immune. Main's version now advances on every merge, so a legitimately
untouched PR that forked earlier sits BELOW the current tip — a tip anchor would
false-flag it as `version-touched`. The fork point is the value the PR's own diff
is measured against, so head == fork-point is exactly "this branch did not touch
the version". In post-merge mode HEAD descends straight from the base tip, so the
merge-base and the tip coincide and the strict-greater assertion is unaffected.

Plugins are enumerated ONLY from `marketplace.json` `plugins[].source` — never a
glob. Stale `plugin.json` copies live under `.claude/worktrees/**`, and a
glob-based scan would read those.

Degradation is deliberate. An unresolvable base ref (offline runner, shallow
clone — git exits 128) yields `status: "degraded"` and exit 0 for the git-anchored
half. A guard that hard-failed when it cannot see the baseline would block every
legitimate PR on a constrained runner, which is worse than not checking. The cost
is that a degraded run provides no touch signal at all, so CALLERS MUST ASSERT
`data.status != "degraded"` themselves — `.github/workflows/lint.yml` does exactly
that, which is what keeps `fetch-depth: 0` from being silently droppable.

Usage:
    python3 scripts/check-version-bump.py [--root DIR] [--mode pr|post-merge]
                                          [--base-ref REF]

    --root defaults to the repo containing this script.
    VERSION_BUMP_BASE_REF  overrides --base-ref (default: origin/main).
    VERSION_BUMP_MODE      overrides --mode.
    VERSION_BUMP_BRANCH    overrides the branch name used for the ^bump/ exemption.

stdlib only; runs under any python3. Exit 0 = clean (or git-degraded with no
mirror violation), 1 = violation(s) found, 2 = script error.
"""

import argparse
import json
import os
import subprocess
import sys
from pathlib import Path

METRIC_VERSION = "1"
DEFAULT_BASE_REF = "origin/main"

# Human-readable remediation per violation code, printed to stderr so a failing
# CI job tells the contributor what to do without a round-trip to the docs.
FIX_HINTS = {
    "version-touched": (
        "Revert the version line — feature branches must not touch it. The "
        "post-merge cogni-version-bump workflow applies the patch bump on merge."
    ),
    "version-mirror-desync": (
        "plugin.json and marketplace.json disagree. Set both to the same value; "
        "they are mirrored for Claude Desktop update detection."
    ),
    "version-not-incremented": (
        "post-merge: the auto-bump did not advance this plugin's version."
    ),
    "version-regressed": (
        "post-merge: the auto-bump decreased this plugin's version."
    ),
    "version-unparseable": "Version value is not a comparable dot-separated string.",
    "manifest-missing": "plugin.json is absent despite changed files under the plugin.",
    "manifest-invalid": "plugin.json does not parse as JSON.",
}


def git(repo_root, *args):
    """Run a git command in repo_root. Returns (exit_code, stdout, stderr)."""
    proc = subprocess.run(
        ["git", "-C", str(repo_root), *args],
        capture_output=True,
        text=True,
    )
    return proc.returncode, proc.stdout, proc.stderr


def parse_version(raw):
    """Dot-separated version -> comparable tuple.

    Numeric components compare numerically; a non-numeric component falls back to
    a string compare at that position. Returns None for an unusable value.
    """
    if not isinstance(raw, str) or not raw.strip():
        return None
    parts = []
    for comp in raw.strip().split("."):
        if comp.isdigit():
            parts.append((0, int(comp), ""))
        else:
            parts.append((1, 0, comp))
    return tuple(parts)


def compare(head, base):
    """-1 / 0 / 1 for head vs base, padding to equal length. None if unparseable."""
    h, b = parse_version(head), parse_version(base)
    if h is None or b is None:
        return None
    pad = max(len(h), len(b))
    h = h + ((0, 0, ""),) * (pad - len(h))
    b = b + ((0, 0, ""),) * (pad - len(b))
    return (h > b) - (h < b)


def read_version(path):
    """(version, error_code) from a plugin.json path."""
    if not path.is_file():
        return None, "manifest-missing"
    try:
        return json.loads(path.read_text(encoding="utf-8")).get("version"), None
    except (json.JSONDecodeError, OSError):
        return None, "manifest-invalid"


def current_branch(repo_root):
    """Branch name for the ^bump/ exemption: explicit override, else the Actions
    PR source branch, else the checked-out branch. Empty when detached/unknown."""
    override = os.environ.get("VERSION_BUMP_BRANCH") or os.environ.get("GITHUB_HEAD_REF")
    if override:
        return override.strip()
    rc, out, _ = git(repo_root, "rev-parse", "--abbrev-ref", "HEAD")
    return out.strip() if rc == 0 else ""


def fail(msg):
    print(json.dumps({"success": False, "data": None, "error": msg},
                     indent=2, ensure_ascii=False))
    return 2


def emit(data):
    """Print the JSON envelope to stdout and a human summary to stderr."""
    violations = data["violations"]
    print(json.dumps({"success": not violations, "data": data, "error": ""},
                     indent=2, ensure_ascii=False), flush=True)

    print(
        "\nversion-bump gate [{}] mode={}: {} plugin(s) scanned, {} touched, "
        "{} violation(s) vs {}".format(
            data["status"], data["mode"], data["plugins_scanned"],
            len(data["plugins_touched"]), data["count"], data["base_ref"]),
        file=sys.stderr,
    )
    if data["status"] == "degraded":
        print("  degraded: {}".format(data.get("degraded_reason", "")), file=sys.stderr)
    if violations:
        print("\nFAIL: {} version violation(s):".format(len(violations)), file=sys.stderr)
        for v in violations:
            print("  {} [{}] {}".format(v["path"], v["check"], v["detail"]), file=sys.stderr)
        print("\nFix:", file=sys.stderr)
        for code in sorted({v["check"] for v in violations}):
            print("  {}: {}".format(code, FIX_HINTS.get(code, "")), file=sys.stderr)
    return 1 if violations else 0


def main(argv):
    parser = argparse.ArgumentParser(
        description="Guard plugin version lines: mirror invariant plus a "
                    "git-anchored touch (pr) or increment (post-merge) check.")
    parser.add_argument("--root", default=None,
                        help="Repo root holding .claude-plugin/marketplace.json "
                             "(default: the repo containing this script).")
    parser.add_argument("--mode", choices=("pr", "post-merge"), default=None,
                        help="pr (default): versions must be untouched vs the fork "
                             "point. post-merge: versions must be strictly greater.")
    parser.add_argument("--base-ref", default=None,
                        help="Ref to compare against (default: origin/main).")
    args = parser.parse_args(argv)

    mode =(args.mode or os.environ.get("VERSION_BUMP_MODE") or "pr").strip().lower()
    if mode not in ("pr", "post-merge"):
        mode = "pr"
    base_ref = (args.base_ref or os.environ.get("VERSION_BUMP_BASE_REF")
                or DEFAULT_BASE_REF)

    repo_root = Path(args.root).resolve() if args.root \
        else Path(__file__).resolve().parent.parent

    manifest_path = repo_root / ".claude-plugin" / "marketplace.json"
    if not manifest_path.is_file():
        return fail("marketplace manifest not found at {}".format(manifest_path))
    try:
        manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
    except (json.JSONDecodeError, OSError) as exc:
        return fail("marketplace.json does not parse as JSON: {}".format(exc))

    plugins = manifest.get("plugins") or []
    violations = []

    # --- 1. Mirror invariant (no git required, so it survives degradation) ----
    for entry in plugins:
        source = (entry.get("source") or "").lstrip("./")
        if not source:
            continue
        name = entry.get("name") or source
        rel_manifest = "{}/.claude-plugin/plugin.json".format(source)
        plugin_version, err = read_version(repo_root / rel_manifest)
        market_version = entry.get("version")
        if err:
            violations.append({
                "plugin": name, "path": rel_manifest,
                "head_version": None, "base_version": None, "check": err,
                "detail": "{} could not be read for the mirror check".format(rel_manifest),
            })
            continue
        if plugin_version != market_version:
            violations.append({
                "plugin": name, "path": ".claude-plugin/marketplace.json",
                "head_version": plugin_version, "base_version": market_version,
                "check": "version-mirror-desync",
                "detail": "{} is {} but its marketplace.json entry says {}".format(
                    rel_manifest, plugin_version, market_version),
            })

    def envelope(status, touched, degraded_reason=None):
        data = {
            "clean": not violations,
            "status": status,
            "mode": mode,
            "count": len(violations),
            "violations": violations,
            "plugins_scanned": len(plugins),
            "plugins_touched": touched,
            "base_ref": base_ref,
            "metric_version": METRIC_VERSION,
        }
        if degraded_reason:
            data["degraded_reason"] = degraded_reason
        return data

    # --- 2. Git-anchored touch / increment check -----------------------------
    rc, _, err = git(repo_root, "rev-parse", "--verify", "--quiet",
                     "{}^{{commit}}".format(base_ref))
    if rc != 0:
        return emit(envelope(
            "degraded", [],
            "base ref '{}' not available (offline, shallow clone, or unfetched)"
            .format(base_ref)))

    # ^bump/-branch exemption (pr mode only). A branch whose whole purpose is to
    # touch the version is exempt; in post-merge mode we run on main and want the
    # assertion, so the exemption is deliberately pr-only.
    if mode == "pr":
        branch = current_branch(repo_root)
        if branch.startswith("bump/"):
            data = envelope("ok", [])
            data["exempt_branch"] = branch
            return emit(data)

    rc, out, err = git(repo_root, "diff", "--name-only", "{}...HEAD".format(base_ref))
    if rc != 0:
        return emit(envelope(
            "degraded", [],
            "could not diff against '{}': {}".format(base_ref, (err or "").strip()[:200])))
    changed = [line.strip() for line in out.splitlines() if line.strip()]

    rc, mb_out, _ = git(repo_root, "merge-base", base_ref, "HEAD")
    compare_ref = mb_out.strip() if rc == 0 and mb_out.strip() else base_ref

    touched = []
    for entry in plugins:
        source = (entry.get("source") or "").lstrip("./")
        if not source:
            continue
        name = entry.get("name") or source
        rel_manifest = "{}/.claude-plugin/plugin.json".format(source)

        # A plugin with no changed files is a no-op. This is what keeps a
        # legitimately untouched plugin (head == base) from being read as the
        # illegitimate same-value sibling collision (also head == base).
        if not any(p == source or p.startswith("{}/".format(source)) for p in changed):
            continue
        touched.append(name)

        head_version, err = read_version(repo_root / rel_manifest)
        if err:
            continue  # already recorded by the mirror pass

        rc, base_text, _ = git(repo_root, "show", "{}:{}".format(compare_ref, rel_manifest))
        if rc != 0:
            # Absent at the fork point => a brand-new plugin. Nothing to compare
            # against, so it cannot have been touched or regressed.
            continue
        try:
            base_version = json.loads(base_text).get("version")
        except json.JSONDecodeError:
            continue

        cmp = compare(head_version, base_version)
        if cmp is None:
            violations.append({
                "plugin": name, "path": rel_manifest,
                "head_version": head_version, "base_version": base_version,
                "check": "version-unparseable",
                "detail": "cannot compare version '{}' against '{}'".format(
                    head_version, base_version),
            })
        elif mode == "post-merge":
            if cmp == 0:
                violations.append({
                    "plugin": name, "path": rel_manifest,
                    "head_version": head_version, "base_version": base_version,
                    "check": "version-not-incremented",
                    "detail": "post-merge: version {} equals {} — the auto-bump did "
                              "not advance {}/'s version.".format(
                                  head_version, base_ref, source),
                })
            elif cmp < 0:
                violations.append({
                    "plugin": name, "path": rel_manifest,
                    "head_version": head_version, "base_version": base_version,
                    "check": "version-regressed",
                    "detail": "post-merge: version {} is BELOW {}'s {} — the "
                              "auto-bump decreased it.".format(
                                  head_version, base_ref, base_version),
                })
        elif cmp != 0:
            violations.append({
                "plugin": name, "path": rel_manifest,
                "head_version": head_version, "base_version": base_version,
                "check": "version-touched",
                "detail": "version changed from {} to {} on this branch, but feature "
                          "branches must not touch {}/'s version — the post-merge "
                          "cogni-version-bump workflow owns the bump. Revert the "
                          "version line to {} (in plugin.json and marketplace.json)."
                          .format(base_version, head_version, source, base_version),
            })

    return emit(envelope("ok", touched))


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))

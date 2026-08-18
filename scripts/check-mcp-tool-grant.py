#!/usr/bin/env python3
"""MCP agent-grant guard: an agent body may only call MCP servers its own
frontmatter grants a tool of, and a plugin holding such a grant must be listed
in that server's registry `required_by`.

The check is SERVER-level, not tool-level: both sides are reduced to the
namespace between the doubled underscores, so an agent granted any
`mcp__pencil__*` tool may name any other `mcp__pencil__*` tool in its body. That
is the invariant the acceptance bar asks for, and it is the one with no
false-positive surface. A tool-level tightening (the granted TOOL must match the
called tool) would catch a strictly larger set and reports zero additional
violations on the tree today — worth considering, but it is a different and
stricter contract than this guard claims, so the claim here is kept honest
rather than the selector quietly widened.

Why this exists. An agent's frontmatter `tools:` list and its body are written
at different times, and nothing at runtime reconciles them. When the body walks
an MCP flow the frontmatter never granted, the documented path is simply
unreachable: the agent silently takes whatever fallback it defines, every run
degrades, and nothing errors. The failure is invisible precisely because a
missing grant and a working fallback look identical from outside. The registry
half is the same class one layer down — a grant the server's `required_by` does
not mention is inert on any install that does not also pull in some other
plugin requiring that server, so the tools are granted but the server is never
provisioned.

Detection is an AFFIRMATIVE CALL SITE, not a prose match. A prose heuristic
("<server> MCP" appearing in the body) is sound only inside a plugin whose
agents never talk about a server they deliberately do not use. Repo-wide it is
not: several agents DISCLAIM a server in exactly that phrasing — cogni-visual
and cogni-workspace both ship a `concept-diagram-svg` agent whose body says "no
Excalidraw MCP", and cogni-knowledge's `source-curator` says "no
claude-in-chrome MCP tools". Those sentences carry no `mcp__<ns>__<tool>`
token, so requiring a literal token is what makes the guard safe at this scope.
The complementary prose detector therefore stays plugin-scoped in
cogni-website/tests/test-mcp-tool-grant.sh, where it is calibrated and green,
and where it still covers the one shape an affirmative detector structurally
cannot see: an agent that documents driving a server in prose alone.

The namespace token class admits HYPHENS. Real namespaces here are spelled
`claude-in-chrome`, and an `[A-Za-z0-9_]`-only class matches nothing at all in
`mcp__claude-in-chrome__navigate` — it would make this guard blind to two
agents and an entire namespace while every case stayed green, which is the very
invisible-absence class the guard exists to close.

Scope is decided by the discovery glob and by the registry's own contents —
there is NO exclusion list, allowlist, baseline or skip marker, and none should
be added: the invariant is a clean zero, not a ratchet. Two skips exist and
both are semantic rather than exemptions: an agent with no `tools:` key inherits
unrestricted tools (so a body call site is genuinely reachable and not an
offender), and a namespace absent from the registry is outside the `required_by`
arm by construction (those servers are installed by other means).

Zero discovery — of agent files or of registry servers — is a failure, never a
silent clean zero: an absence result must mean "looked and found nothing wrong",
not "looked at nothing".

stdlib only; runs under any python3. Exit 0 = clean, 1 = violation(s),
2 = script error.
"""

import argparse
import glob
import json
import os
import re
import sys

REGISTRY_REL = os.path.join(
    "cogni-workspace", "references", "mcp-git-registry.json"
)

# Namespace and tool segments both admit hyphens: `mcp__claude-in-chrome__navigate`
# is a real token in this tree, and an underscore-only class matches none of it.
MCP_TOKEN_RE = re.compile(r"mcp__([A-Za-z0-9_-]+?)__[A-Za-z0-9_-]+")

# The single anchor for YAML block-list item lines. 15 agents declare `tools:`
# this way, and 6 of the 7 agents carrying a real body call site are among them,
# so a reader that misses this form reports those 6 as false offenders.
# The indent is `\s*`, not `\s+`: a block list written flush-left under `tools:`
# is valid YAML and the host accepts it, so requiring indentation would read
# those grants as absent — the agent would silently drop out of the required_by
# arm and any body call site it grew would become a false offender.
BLOCK_ITEM_RE = re.compile(r"^\s*-\s+(.*?)\s*$")

TOOLS_KEY_RE = re.compile(r"^tools:(.*)$")
FENCE = "---"


def repo_root_default():
    return os.path.dirname(os.path.dirname(os.path.abspath(__file__)))


def discover(root):
    """Every plugin-level agent definition.

    Non-recursive on purpose: `*/agents/*.md` is three path segments, so
    snapshot copies parked deeper (cogni-portfolio-evals/skill-snapshots/*/
    agents/) are out of the population by shape rather than by an exclusion,
    and dot-directories are skipped by glob itself.
    """
    pattern = os.path.join(root, "*", "agents", "*.md")
    return sorted(
        os.path.relpath(p, root) for p in glob.glob(pattern) if os.path.isfile(p)
    )


def split_frontmatter(text):
    """Return (frontmatter_lines, body_text).

    The body is everything after the SECOND fence, so a `description:` naming a
    server is excluded from call-site detection by construction.
    """
    lines = text.split("\n")
    if not lines or lines[0].strip() != FENCE:
        return [], text
    for i in range(1, len(lines)):
        if lines[i].strip() == FENCE:
            return lines[1:i], "\n".join(lines[i + 1:])
    return [], text


def extract_tools(fm_lines):
    """Return (tools_text, form, line_number) for the `tools:` key.

    Handles the three forms in the tree: a bracketed array (which may span to
    its closing bracket), a bare comma list on the key's own line, and a YAML
    block list of following `- item` lines.
    """
    for i, line in enumerate(fm_lines):
        match = TOOLS_KEY_RE.match(line)
        if not match:
            continue
        lineno = i + 2  # +1 for the opening fence, +1 for 1-based
        rest = match.group(1).strip()
        if rest.startswith("["):
            buf = rest
            j = i
            while "]" not in buf and j + 1 < len(fm_lines):
                j += 1
                buf += " " + fm_lines[j].strip()
            return buf, "bracketed", lineno
        if rest:
            return rest, "comma", lineno
        items = []
        j = i + 1
        while j < len(fm_lines):
            item = BLOCK_ITEM_RE.match(fm_lines[j])
            if not item:
                break
            items.append(item.group(1))
            j += 1
        return "\n".join(items), "block", lineno
    return None, None, None


def load_registry(root):
    path = os.path.join(root, REGISTRY_REL)
    try:
        with open(path, encoding="utf-8") as handle:
            registry = json.load(handle)
    except (OSError, ValueError) as exc:
        raise RuntimeError(
            "MCP registry unreadable at %s (%s) — the required_by arm cannot "
            "run, and a skipped arm must not read as a clean one" % (path, exc)
        )
    servers = registry.get("servers")
    if not isinstance(servers, dict) or not servers:
        raise RuntimeError(
            "MCP registry at %s declares no servers — an empty vocabulary "
            "would make the required_by arm vacuously green" % path
        )
    # The registry key is not always the tool namespace (`mcp_excalidraw`
    # registers tools as mcp__excalidraw__*). That mapping is carried as DATA in
    # desktop_config_key, which patch-desktop-config.py treats as canonical, so
    # read it rather than stripping a prefix — a heuristic would agree with the
    # data only coincidentally and would mis-normalize a future key.
    by_namespace = {}
    for key, entry in servers.items():
        if not isinstance(entry, dict):
            continue
        namespace = entry.get("desktop_config_key") or key
        by_namespace[namespace] = {
            "key": key,
            "required_by": [str(x) for x in (entry.get("required_by") or [])],
        }
    return by_namespace


def collect(root):
    agents = discover(root)
    if not agents:
        raise RuntimeError(
            "no agent definitions discovered under %s — check --root; this "
            "repo always ships agents, so an empty sweep means the glob "
            "stopped matching" % root
        )
    registry = load_registry(root)

    findings = []
    observations = []
    counters = {
        "agents_discovered": len(agents),
        "tools_form_counts": {"bracketed": 0, "comma": 0, "block": 0},
        "grant_tokens": 0,
        "body_call_sites": 0,
        "registered_namespaces": len(registry),
        "skipped_no_tools": 0,
        "skipped_unregistered": 0,
    }
    granting_plugins = {}

    for rel in agents:
        try:
            with open(os.path.join(root, rel), encoding="utf-8") as handle:
                text = handle.read()
        except OSError as exc:
            # Never skip: a file that was discovered and then could not be read
            # would leave the population silently short, which is the same
            # invisible-absence failure this guard exists to close.
            raise RuntimeError("agent file unreadable: %s (%s)" % (rel, exc))
        fm_lines, body = split_frontmatter(text)
        tools_text, form, lineno = extract_tools(fm_lines)

        body_tokens = MCP_TOKEN_RE.findall(body)
        counters["body_call_sites"] += len(body_tokens)

        if tools_text is None:
            # No `tools:` key means unrestricted tool inheritance, so a body
            # call site is genuinely reachable — a skip, not an exemption.
            counters["skipped_no_tools"] += 1
            continue

        counters["tools_form_counts"][form] += 1
        grant_tokens = MCP_TOKEN_RE.findall(tools_text)
        counters["grant_tokens"] += len(grant_tokens)
        granted = set(grant_tokens)
        plugin = rel.split(os.sep)[0]

        for namespace in sorted(set(body_tokens)):
            if namespace not in granted:
                findings.append({
                    "file": rel,
                    "line": lineno,
                    "arm": "body_call_site_ungranted",
                    "namespace": namespace,
                    "detail": (
                        "body calls mcp__%s__* but this agent's tools: grants "
                        "no %s tool" % (namespace, namespace)
                    ),
                })

        for namespace in sorted(granted):
            if namespace not in registry:
                counters["skipped_unregistered"] += 1
                continue
            granting_plugins.setdefault(namespace, set()).add(plugin)
            if plugin not in registry[namespace]["required_by"]:
                findings.append({
                    "file": rel,
                    "line": lineno,
                    "arm": "required_by_missing_plugin",
                    "namespace": namespace,
                    "detail": (
                        "%s grants mcp__%s__* but registry server %s does not "
                        "list it in required_by"
                        % (plugin, namespace, registry[namespace]["key"])
                    ),
                })

    # Non-failing: the arm asserts every GRANTING plugin is listed, not the
    # converse, so a listed plugin that grants nothing is reported for a human
    # rather than turned into a violation.
    for namespace, entry in sorted(registry.items()):
        for plugin in entry["required_by"]:
            if plugin not in granting_plugins.get(namespace, set()):
                observations.append({
                    "kind": "listed_without_grant",
                    "namespace": namespace,
                    "plugin": plugin,
                    "detail": (
                        "registry server %s lists %s in required_by but no %s "
                        "agent grants an mcp__%s__* tool"
                        % (entry["key"], plugin, plugin, namespace)
                    ),
                })

    return findings, observations, counters


def main(argv):
    parser = argparse.ArgumentParser(description="MCP agent-grant guard")
    parser.add_argument(
        "--root",
        default=None,
        help="tree to scan; discovery and reported paths are relative to it",
    )
    args = parser.parse_args(argv)
    root = os.path.abspath(args.root) if args.root else repo_root_default()

    try:
        findings, observations, counters = collect(root)
    except RuntimeError as exc:
        print(json.dumps({"success": False, "data": {}, "error": str(exc)},
                         indent=2, ensure_ascii=False))
        return 2

    by_arm = {}
    for finding in findings:
        by_arm[finding["arm"]] = by_arm.get(finding["arm"], 0) + 1

    summary = {"total": len(findings), "by_arm": by_arm}
    summary.update(counters)

    result = {
        "success": not findings,
        "data": {
            "root": root,
            "violations": findings,
            "observations": observations,
            "summary": summary,
        },
        "error": "",
    }
    print(json.dumps(result, indent=2, ensure_ascii=False))

    if findings:
        for finding in findings:
            print("FAIL: %s:%s [%s] %s" % (
                finding["file"], finding["line"], finding["arm"],
                finding["detail"]), file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))

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
That reasoning held while the only affirmative signal was the token itself. It
no longer does, and the evaluation of the alternative resolved to ADOPT. The
registry already names each server's tools in `provides_tools[]`, so a body can
be read affirmatively with NEITHER prose NOR a token, by asking whether it names
one of those tools inside a backtick code span. That second arm lives below, and
the plugin-scoped prose detector that formerly sat in cogni-website's own test
directory is retired with it.

Measured when adopted: the registry registers 2 servers carrying 18 distinct
bare names, with NO name owned by more than one server; of the 103 agents that
declare a `tools:` key, 9 name at least one of those tools in a code span, for
52 name hits in total, and 0 of them are offenders. The retired arm's single live
instance was cogni-website/agents/hero-renderer.md, which documents driving
Pencil with no `mcp__` token anywhere in its body; this arm sees it through
`get_guidelines` and `batch_design`, both resolving to pencil, which that agent
grants. Because no bare name has two owners today, the multi-owner rules below
are forward-looking and fixture-pinned — they describe no live collision.

Resolution is SERVER level, and the code span is the mechanical context
requirement. A bare name is satisfied by ANY `mcp__<ns>__*` grant of a server
that provides it; where two servers provide the same name, granting either
satisfies it, and where neither is granted exactly one finding is emitted
against the lexicographically-first owner, so the output is deterministic
rather than dependent on dict order. The span is what makes the arm safe:
bare names like `get_screenshot` and `export_scene` are ordinary English, and
matching them in running prose is the very false-positive class that kept the
old heuristic plugin-scoped.

Three residuals, stated rather than implied away. An agent that names a server
in prose while naming NONE of its tools in a code span is outside both arms.
The no-`tools:`-key skip is inherited here, and it is not hypothetical: the
`storyboard` and `web` agents in cogni-visual and cogni-workspace declare no
`tools:` key and together carry 22 in-span name hits this arm deliberately does
not judge. And a code span inside a DISCLAIMING sentence would read as affirmative
— that has no instance today, and the span requirement is what keeps the edge
narrow, but it is real. Finally, the vocabulary is only as complete as the
registry: agents grant 26 distinct tool names across the two registered
servers while `provides_tools[]` lists 18, so 9 granted names are outside this
arm's reach. That completeness question is now ANSWERED rather than deferred:
each granted `mcp__<registered-ns>__<tool>` is resolved against its own
server's `provides_tools[]`, and a name absent from it is surfaced as a
`granted_outside_vocabulary` observation. Today that reports 9 gaps. Each is
one record naming the gap once and carrying its granting agents as evidence,
because the fix is one edit to the registry however many agents grant the name
— emitting per agent would have restated one fact 17 times and pointed each
copy at a file that is by construction not where the fix goes.

It reports rather than fails, and that is the whole of the decision. A grant
outside the vocabulary is a registry-accuracy fact, not an agent defect: the
agent's grant is correct and the registry is behind it. Making it a hard arm
would gate CI on a judgement about what two upstream servers really provide —
a claim nothing in this repo can check — so it takes the same non-failing
channel as the stale `required_by` entry below, which is the same class one
field over. `success` is computed from findings alone, so neither channel can
move the exit code.

The empty-vocabulary floor is decided too, and separately. The union check in
`load_registry` fires only when EVERY server loses its array; a per-server
check now raises alongside it, because one server going empty — or a new one
registered without an array — narrows both provides_tools channels for that
server while `provides_tools_vocabulary` stays a healthy positive number and
every case stays green. That is this guard's own failure class one layer down,
so it raises rather than reporting: unlike a stale name, an absent array is not
a judgement about upstream, it is a registry that cannot be read.

Two residuals follow from those choices rather than being overlooked. The
channel is non-failing by design, so a stale registry still waits on a human;
what changed is that it can no longer wait unseen. And a grant of an
UNREGISTERED namespace has no vocabulary to resolve against and is skipped by
construction — 18 of the 73 grant tokens are in that class today, the same
population the `required_by` arm already skips for the same reason.

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
# ONE grammar for the token, with both segments captured. Read it only through
# the two readers below, never `findall` — with two groups `findall` yields
# (namespace, tool) TUPLES, and a caller expecting flat strings would compare a
# namespace against a set of tuples, making `namespace not in granted` always
# true and `granted.intersection(owners)` never intersect: two arms turned into
# false-positive generators with every case still green. The readers exist so
# that hazard is stated once, here, instead of a second pattern carrying a
# second copy of the character class — which is the drift that matters, since
# this class is the one that already went blind to a whole namespace once.
MCP_TOKEN_RE = re.compile(r"mcp__([A-Za-z0-9_-]+?)__([A-Za-z0-9_-]+)")


def namespaces_in(text):
    """Every namespace named by an mcp__ token in `text`, with repeats."""
    return [match.group(1) for match in MCP_TOKEN_RE.finditer(text)]


def grants_in(text):
    """Every (namespace, tool) pair named by an mcp__ token in `text`."""
    return [match.group(1, 2) for match in MCP_TOKEN_RE.finditer(text)]

# The mechanical context requirement for the provides_tools arm: a registry bare
# name counts only inside a backtick code span. The FENCED alternative is listed
# first on purpose — an inline branch tried first would pair the opening fence's
# backticks with each other and mis-slice a fenced block into fragments.
CODE_SPAN_RE = re.compile(r"```.*?```|`[^`\n]+`", re.S)

# The single anchor for YAML block-list item lines.
# Measured when this note was pinned: 10 agents declare `tools:` this way (the
# guard re-derives that count every run as `summary.tools_form_counts.block`),
# and 3 of the 4 agents carrying a real body call site are among them, so a
# reader that misses this form reports those 3 as false offenders.
# The counts are a snapshot; the form stays load-bearing while any block-form
# agent carries a call site.
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
    # bare tool name -> sorted namespaces providing it. Built from the same
    # desktop_config_key mapping, so the arm keyed on it inherits the registry's
    # own naming rather than a second, drifting notion of a namespace.
    tool_owners = {}
    # Registry keys whose server declares no vocabulary at all — invisible to
    # the union floor below, which is why both floors exist (see the docstring).
    vocabulary_gaps = []
    for key, entry in servers.items():
        if not isinstance(entry, dict):
            continue
        namespace = entry.get("desktop_config_key") or key
        by_namespace[namespace] = {
            "key": key,
            "required_by": [str(x) for x in (entry.get("required_by") or [])],
        }
        tools = [str(tool) for tool in entry.get("provides_tools") or []]
        if not tools:
            vocabulary_gaps.append(str(key))
        by_namespace[namespace]["vocabulary"] = set(tools)
        for tool in tools:
            tool_owners.setdefault(tool, set()).add(namespace)
    if not tool_owners:
        raise RuntimeError(
            "MCP registry at %s declares no provides_tools for any server — an "
            "empty vocabulary would make the provides_tools arm vacuously "
            "green, which is the invisible-absence failure this guard closes"
            % path
        )
    # The per-server half of the same floor: the union check above is
    # all-or-nothing, so on its own a single server going empty stays green.
    # It raises rather than reporting because an absent array is not a
    # judgement about upstream, it is a vocabulary that cannot be read.
    if vocabulary_gaps:
        raise RuntimeError(
            "MCP registry at %s registers server(s) %s with no provides_tools "
            "— a per-server empty vocabulary narrows the provides_tools arm "
            "and the granted-name resolution for that server while the union "
            "vocabulary stays non-empty, so it would pass unseen" % (
                path, ", ".join(sorted(vocabulary_gaps)))
        )
    tool_owners = {name: sorted(owners) for name, owners in tool_owners.items()}
    return by_namespace, tool_owners


def collect(root):
    agents = discover(root)
    if not agents:
        raise RuntimeError(
            "no agent definitions discovered under %s — check --root; this "
            "repo always ships agents, so an empty sweep means the glob "
            "stopped matching" % root
        )
    registry, tool_owners = load_registry(root)
    # ONE alternation over the whole vocabulary, not a search per name. A `\b`
    # in leading position defeats re's literal-prefix prescan, so N separate
    # patterns each walk the full span text; over this tree that is the
    # difference between ~47ms and ~4ms, and it grows with the vocabulary
    # rather than staying flat. Alternatives are ordered longest-first so the
    # engine prefers `batch_create_elements` over the `create_element` it
    # contains.
    #
    # The word boundaries carry two properties this arm depends on, both
    # verified against the tree rather than assumed. A bare name inside an
    # `mcp__<ns>__<name>` token never matches, because the preceding `_` is a
    # word character — so this arm and the body-call-site arm structurally
    # cannot both report the same call site. And the vocabulary's one
    # containment pair never matches its own substring, for the same reason.
    vocabulary_re = re.compile(
        r"\b(?:%s)\b" % "|".join(
            re.escape(name)
            for name in sorted(tool_owners, key=lambda n: (-len(n), n))
        )
    )
    findings = []
    observations = []
    # (namespace, tool) -> the (plugin, file) pairs granting it. Accumulated
    # across the whole sweep, not per agent: the gap is one registry fact
    # however many agents happen to grant the name.
    outside = {}
    counters = {
        "agents_discovered": len(agents),
        "tools_form_counts": {"bracketed": 0, "comma": 0, "block": 0},
        "grant_tokens": 0,
        "body_call_sites": 0,
        "registered_namespaces": len(registry),
        "skipped_no_tools": 0,
        "skipped_unregistered": 0,
        "provides_tools_vocabulary": len(tool_owners),
        # The examined population for the granted-name resolution below: grant
        # token INSTANCES (same semantics as grant_tokens, not distinct pairs)
        # whose namespace is registered and therefore HAS a vocabulary to
        # resolve against. Incremented before the membership test, so a
        # mutation of that test collapses the reporting without collapsing the
        # counter — the liveness floor keeps measuring what was examined rather
        # than what was reported. Same reasoning as the post-skip counter below.
        "provides_tools_grant_names_resolved": 0,
        # Counted POST-skip, unlike body_call_sites just above, which is counted
        # before it. The asymmetry is deliberate: this counter is the liveness
        # floor for what the arm actually judged, so folding in the agents it
        # skipped would let the population look healthy while the arm examined
        # nothing.
        "provides_tools_code_span_names": 0,
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

        body_tokens = namespaces_in(body)
        counters["body_call_sites"] += len(body_tokens)

        if tools_text is None:
            # No `tools:` key means unrestricted tool inheritance, so a body
            # call site is genuinely reachable — a skip, not an exemption.
            counters["skipped_no_tools"] += 1
            continue

        counters["tools_form_counts"][form] += 1
        grant_tokens = namespaces_in(tools_text)
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

        # The completeness channel's per-agent half: resolve each granted
        # tool against its OWN server's vocabulary. A name owned by a different
        # server says nothing about this one, so the union is the wrong set.
        # Only accumulation happens here — the finding is a registry fact, so
        # it is emitted once per gap after the sweep, beside listed_without_grant.
        for namespace, tool in grants_in(tools_text):
            if namespace not in registry:
                # An unregistered server has no vocabulary to judge against —
                # the same semantic skip the required_by loop takes above, and
                # deliberately not re-counted there: skipped_unregistered
                # measures that loop's population, not this one's.
                continue
            counters["provides_tools_grant_names_resolved"] += 1
            vocabulary = registry[namespace]["vocabulary"]
            if tool not in vocabulary:
                outside.setdefault((namespace, tool), set()).add((plugin, rel))

        # Third arm. It sits after the required_by loop, and therefore after the
        # no-`tools:`-key skip above, so an agent with unrestricted tools is
        # never judged here — the measured "0 offenders" figure is contingent on
        # that inherited skip, not independent of it.
        # Joined with a newline, and with the backticks retained, so the
        # boundaries above bind at each span's edges and no name can match
        # across two adjacent spans.
        spans = "\n".join(CODE_SPAN_RE.findall(body))
        ungranted = {}
        for name in sorted(set(vocabulary_re.findall(spans))):
            counters["provides_tools_code_span_names"] += 1
            owners = tool_owners[name]
            if granted.intersection(owners):
                # SERVER level: any grant of any owning server satisfies the
                # name. Where a name has two owners, granting either is enough.
                continue
            # No owner granted. Attribute to the lexicographically-first owner
            # so a two-owner name yields exactly one finding in a stable place,
            # rather than one per owner or one chosen by dict order.
            ungranted.setdefault(owners[0], []).append(name)

        for namespace in sorted(ungranted):
            names = sorted(ungranted[namespace])
            findings.append({
                "file": rel,
                "line": lineno,
                "arm": "provides_tools_body_name_ungranted",
                "namespace": namespace,
                "detail": (
                    "body names registry tool(s) %s in a code span but this "
                    "agent's tools: grants no %s tool"
                    % (", ".join(names), namespace)
                ),
            })

    # Non-failing, and a REGISTRY fact rather than an agent one — one record
    # per gap, granting agents carried as evidence (see the docstring).
    for namespace, tool in sorted(outside):
        holders = sorted(outside[(namespace, tool)])
        observations.append({
            "kind": "granted_outside_vocabulary",
            "namespace": namespace,
            "tool": tool,
            "plugins": sorted({plugin for plugin, _ in holders}),
            "files": [rel for _, rel in holders],
            "detail": (
                "%s grant mcp__%s__%s but registry server %s does not list %s "
                "in provides_tools, so the name is outside the vocabulary "
                "arm's reach" % (
                    ", ".join(sorted({plugin for plugin, _ in holders})),
                    namespace, tool, registry[namespace]["key"], tool)
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

# resolve-wiki-scripts.sh — shared shell probe for locating a vendored wiki engine
# skill's scripts/ directory, sourced (never executed) by the knowledge-* SKILL.md
# flows. Keeping the probe in one file means a change to the resolution rule
# lands once instead of being hand-applied across every flow. The Python peer
# (_knowledge_lib.resolve_wiki_scripts) stays a separate copy by necessity —
# standalone Python scripts cannot source a shell snippet.
#
# Resolution is VENDORED-ONLY. cogni-knowledge ships the engine in-tree under
# scripts/vendor/cogni-wiki/ and is self-contained; there is no external engine
# source to fall back to. The plugin the vendored tree was copied from is retired
# — absent from .claude-plugin/marketplace.json and registered in
# scripts/retired-plugins.json — so an external install can only be a stale,
# unversioned copy. Resolving one would silently run an engine older than the
# plugin that called it, which is worse than failing loudly against the versioned
# copy that ships here. Do not reintroduce a sibling or marketplace-cache probe.
#
# Usage (inside a SKILL.md shell block; CLAUDE_PLUGIN_ROOT preferred but optional —
# when unset, the plugin root is derived from this script's own sourced location):
#   . "${CLAUDE_PLUGIN_ROOT}/scripts/resolve-wiki-scripts.sh"
#   WIKI_INGEST_SCRIPTS=$(resolve_wiki_scripts wiki-ingest backlink_audit.py) || abort "..."
#
# bash 3.2 + stdlib only.

# Captured at SOURCE time, not function-run time: BASH_SOURCE[0] carries the
# sourced file path under bash; under zsh (FUNCTION_ARGZERO default) $0 carries
# it here at the top level but would be the *function name* inside the function
# body, so capturing later would derive a garbage root.
_RESOLVE_WIKI_SCRIPTS_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")/.." 2>/dev/null && pwd)"

resolve_wiki_scripts() {  # $1 = skill name, e.g. wiki-ingest / wiki-lint / wiki-health
  local skill="$1"
  local ep="${2:-}"   # $2 = optional entry-point script; when set, the probe
                      # wins only if "<dir>/$ep" is a file. This is the VENDOR
                      # INTEGRITY guard — it catches a botched vendored copy
                      # (dir copied, script missed) here rather than letting it
                      # surface as a FileNotFoundError deep in a run. With no
                      # fallback branch left, it is the only such guard.
  # Plugin root: prefer CLAUDE_PLUGIN_ROOT, fall back to the root derived from
  # this script's own sourced location (nested-skill Bash blocks don't inherit
  # the env var).
  local _cpr="${CLAUDE_PLUGIN_ROOT:-$_RESOLVE_WIKI_SCRIPTS_ROOT}"
  local vend="${_cpr}/scripts/vendor/cogni-wiki/skills/${skill}/scripts"
  test -d "$vend" && { [ -z "$ep" ] || [ -f "$vend/$ep" ]; } && { echo "$vend"; return 0; }
  return 1
}

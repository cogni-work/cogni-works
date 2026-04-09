#!/usr/bin/env python3
"""
patch-desktop-config.py — Merge git-installed MCP servers into Claude Desktop's config.

Reads mcp-git-registry.json for server definitions, resolves the installed wrapper
path from ~/.claude/mcp-servers/<name>/start.sh, and merges each entry into
claude_desktop_config.json. Creates a timestamped backup before any modification.

Usage:
  python3 patch-desktop-config.py --registry <path> [--dry-run] [--force]

Output: JSON with success status and actions taken.
"""

import argparse
import json
import os
import platform
import shutil
import sys
from datetime import datetime, timezone
from pathlib import Path


def get_desktop_config_path() -> Path:
    """Return the platform-specific path to claude_desktop_config.json."""
    system = platform.system()
    if system == "Darwin":
        return Path.home() / "Library" / "Application Support" / "Claude" / "claude_desktop_config.json"
    elif system == "Linux":
        # XDG_CONFIG_HOME or ~/.config
        config_home = os.environ.get("XDG_CONFIG_HOME", str(Path.home() / ".config"))
        return Path(config_home) / "Claude" / "claude_desktop_config.json"
    elif system == "Windows":
        appdata = os.environ.get("APPDATA", str(Path.home() / "AppData" / "Roaming"))
        return Path(appdata) / "Claude" / "claude_desktop_config.json"
    else:
        # Fallback — try macOS path
        return Path.home() / "Library" / "Application Support" / "Claude" / "claude_desktop_config.json"


def resolve_wrapper_path(server_name: str) -> str | None:
    """Find the installed wrapper script for a git-based MCP server."""
    mcp_base = os.environ.get("CLAUDE_MCP_DIR", str(Path.home() / ".claude" / "mcp-servers"))
    wrapper = Path(mcp_base) / server_name / "start.sh"
    if wrapper.exists():
        return str(wrapper)
    return None


def get_platform_key() -> str:
    """Map platform.system() to registry platform keys."""
    return {"Darwin": "darwin", "Linux": "linux", "Windows": "win32"}.get(
        platform.system(), "darwin"
    )


def build_mcp_entry(server: dict) -> dict | None:
    """Build a claude_desktop_config.json mcpServers entry from registry data.

    Returns None if the server type can't be resolved (e.g. git server not installed,
    native server platform not supported).
    """
    server_type = server.get("type", "git")

    if server_type == "git":
        wrapper_path = resolve_wrapper_path(server["name"])
        if not wrapper_path:
            return None
        entry = {
            "command": "bash",
            "args": [wrapper_path],
        }
    elif server_type == "native":
        plat = get_platform_key()
        platform_config = server.get("platforms", {}).get(plat)
        if not platform_config:
            return None
        command = platform_config["command"]
        # Skip if the binary doesn't exist at the expected path
        if os.path.isabs(command) and not os.path.exists(command):
            return None
        entry = {
            "command": command,
            "args": platform_config.get("args", []),
        }
    else:
        return None

    entry["env"] = dict(server.get("env", {}))
    return entry


def result_json(success: bool, **data) -> str:
    return json.dumps({"success": success, "data": data}, indent=2)


def main():
    parser = argparse.ArgumentParser(description="Patch Claude Desktop config with git-installed MCP servers")
    parser.add_argument("--registry", required=True, help="Path to mcp-git-registry.json")
    parser.add_argument("--dry-run", action="store_true", help="Show what would change without writing")
    parser.add_argument("--force", action="store_true", help="Overwrite existing entries")
    parser.add_argument("--config-path", help="Override auto-detected config path (for testing)")
    args = parser.parse_args()

    # Load registry
    try:
        with open(args.registry) as f:
            registry = json.load(f)
    except (FileNotFoundError, json.JSONDecodeError) as e:
        print(result_json(False, error=f"Cannot read registry: {e}"))
        sys.exit(1)

    servers = registry.get("servers", {})
    if not servers:
        print(result_json(True, action="noop", message="No servers in registry"))
        return

    # Resolve Desktop config path
    config_path = Path(args.config_path) if args.config_path else get_desktop_config_path()

    # Load existing config (or start fresh)
    if config_path.exists():
        try:
            with open(config_path) as f:
                desktop_config = json.load(f)
        except json.JSONDecodeError:
            print(result_json(False, error=f"Invalid JSON in {config_path}"))
            sys.exit(1)
    else:
        desktop_config = {}

    if "mcpServers" not in desktop_config:
        desktop_config["mcpServers"] = {}

    existing_servers = desktop_config["mcpServers"]
    actions = []

    for name, server in servers.items():
        config_key = server.get("desktop_config_key", name)

        already_exists = config_key in existing_servers
        if already_exists and not args.force:
            actions.append({"server": name, "action": "skipped", "reason": "already configured"})
            continue

        entry = build_mcp_entry(server)
        if entry is None:
            server_type = server.get("type", "git")
            reason = "not installed" if server_type == "git" else "binary not found on this platform"
            actions.append({"server": name, "action": "skipped", "reason": reason})
            continue

        existing_servers[config_key] = entry
        action_verb = "updated" if already_exists else "added"
        actions.append({"server": name, "action": action_verb, "config_key": config_key})

    # Check if anything changed
    additions = [a for a in actions if a["action"] in ("added", "updated")]
    if not additions:
        print(result_json(True, action="noop", actions=actions,
                          message="No changes needed", config_path=str(config_path)))
        return

    if args.dry_run:
        print(result_json(True, action="dry_run", actions=actions,
                          config_path=str(config_path),
                          preview=desktop_config["mcpServers"]))
        return

    # Create backup before writing
    if config_path.exists():
        backup_path = config_path.with_suffix(
            f".backup-{datetime.now(timezone.utc).strftime('%Y%m%dT%H%M%SZ')}.json"
        )
        shutil.copy2(config_path, backup_path)
        backup_str = str(backup_path)
    else:
        config_path.parent.mkdir(parents=True, exist_ok=True)
        backup_str = None

    # Write updated config
    with open(config_path, "w") as f:
        json.dump(desktop_config, f, indent=2)
        f.write("\n")

    print(result_json(True, action="patched", actions=actions,
                      config_path=str(config_path), backup=backup_str))


if __name__ == "__main__":
    main()

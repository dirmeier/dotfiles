#!/usr/bin/env bash
set -euo pipefail

# Reproduce the Claude Code plugin set on a new machine.
#
# Single source of truth is claude/settings.json:
#   - marketplaces come from .extraKnownMarketplaces[*].source.repo
#     (plus the built-in official marketplace, always added)
#   - plugins come from the keys of .enabledPlugins
#
# Idempotent: re-adding a marketplace or re-installing a plugin is tolerated.
# Requires: python3, and the `claude` CLI on PATH.

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SETTINGS="$DOTFILES/claude/settings.json"

command -v claude  >/dev/null 2>&1 || { echo "ERROR: 'claude' CLI not found on PATH" >&2; exit 1; }
command -v python3 >/dev/null 2>&1 || { echo "ERROR: python3 not found on PATH"       >&2; exit 1; }
[[ -f "$SETTINGS" ]] || { echo "ERROR: $SETTINGS not found" >&2; exit 1; }

echo "Reading plugin config from $SETTINGS"

# The official marketplace is always required; custom ones are read from settings.
marketplaces=("anthropics/claude-plugins-official")
while IFS= read -r repo; do
    [[ -n "$repo" ]] && marketplaces+=("$repo")
done < <(python3 -c '
import json, sys
d = json.load(open(sys.argv[1]))
for m in d.get("extraKnownMarketplaces", {}).values():
    repo = (m.get("source") or {}).get("repo")
    if repo:
        print(repo)
' "$SETTINGS")

echo "Adding marketplaces..."
for mp in "${marketplaces[@]}"; do
    echo "  + $mp"
    claude plugin marketplace add "$mp" || echo "    (already added or unavailable; continuing)"
done

echo "Installing enabled plugins..."
while IFS= read -r plugin; do
    [[ -z "$plugin" ]] && continue
    echo "  + $plugin"
    claude plugin install "$plugin" || echo "    (already installed or unavailable; continuing)"
done < <(python3 -c '
import json, sys
d = json.load(open(sys.argv[1]))
for name, enabled in d.get("enabledPlugins", {}).items():
    if enabled:
        print(name)
' "$SETTINGS")

echo "Done. Restart Claude Code for plugin changes to take effect."

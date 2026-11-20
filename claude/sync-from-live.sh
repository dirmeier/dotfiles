#!/usr/bin/env bash
set -euo pipefail

# Pull drift from the live ~/.claude environment back into this repo, so the
# repo stays the reproducible source of truth after you install/upgrade
# things locally (new plugins, new skills dropped in by a tool, etc).
#
# What it does:
#   1. Merges any enabledPlugins / extraKnownMarketplaces present locally but
#      missing from claude/settings.json (additive only), and copies the
#      allowlisted preference keys (PREF_KEYS below) from live, live wins.
#      Never touches model/theme/env/hooks/permissions.
#   2. For skills/agents/memory: if the live path is still the intended
#      symlink into this repo, does nothing. If it has drifted into a real
#      copy (this happens — some tool can replace a symlink with a real
#      file), copies new/changed files into the repo (additive, never
#      deletes from the repo).
#   3. Reports (does not copy) top-level ~/.claude files that aren't tracked
#      here yet (e.g. CLAUDE.md, RTK.md, keybindings.json) so you can decide.
#
# Nothing here commits. Review with `git status`/`git diff` and commit
# yourself. Safe to re-run any time — idempotent, additive only.

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CLAUDE_HOME="$HOME/.claude"
REPO_SETTINGS="$DOTFILES/claude/settings.json"
LIVE_SETTINGS="$CLAUDE_HOME/settings.json"

command -v python3 >/dev/null 2>&1 || { echo "ERROR: python3 not found on PATH" >&2; exit 1; }
command -v rsync    >/dev/null 2>&1 || { echo "ERROR: rsync not found on PATH"   >&2; exit 1; }
[[ -f "$LIVE_SETTINGS" ]] || { echo "ERROR: $LIVE_SETTINGS not found" >&2; exit 1; }
[[ -f "$REPO_SETTINGS" ]] || { echo "ERROR: $REPO_SETTINGS not found" >&2; exit 1; }

echo "== 1. Plugins & marketplaces =="
python3 - "$LIVE_SETTINGS" "$REPO_SETTINGS" <<'PY'
import json, sys

live_path, repo_path = sys.argv[1], sys.argv[2]
live = json.load(open(live_path))
repo = json.load(open(repo_path))

added_plugins = []
repo.setdefault("enabledPlugins", {})
for name, enabled in live.get("enabledPlugins", {}).items():
    if enabled and name not in repo["enabledPlugins"]:
        repo["enabledPlugins"][name] = True
        added_plugins.append(name)

added_marketplaces = []
repo.setdefault("extraKnownMarketplaces", {})
for mp_name, mp in live.get("extraKnownMarketplaces", {}).items():
    if mp_name not in repo["extraKnownMarketplaces"]:
        repo["extraKnownMarketplaces"][mp_name] = mp
        added_marketplaces.append(mp_name)

# Allowlist, not denylist: live also holds permissions (machine paths) and env
# (secrets) that must never reach the repo. Add a key here to start syncing it.
PREF_KEYS = ["effortLevel", "modelSettings", "autoCompactWindow", "promptCacheTtl",
             "subagentPromptCacheTtl", "autoUpdatesChannel"]
changed_prefs = []
for key in PREF_KEYS:
    if key in live and repo.get(key) != live[key]:
        repo[key] = live[key]
        changed_prefs.append(key)

if added_plugins or added_marketplaces or changed_prefs:
    with open(repo_path, "w") as f:
        json.dump(repo, f, indent=2)
        f.write("\n")

if added_plugins:
    print("  added plugins: " + ", ".join(added_plugins))
if added_marketplaces:
    print("  added marketplaces: " + ", ".join(added_marketplaces))
if changed_prefs:
    print("  updated settings: " + ", ".join(changed_prefs))
if not (added_plugins or added_marketplaces or changed_prefs):
    print("  already in sync.")
PY

echo ""
echo "== 2. Tracked symlink targets (skills, agents, memory, global instructions) =="
realpath_py() { python3 -c "import os,sys; print(os.path.realpath(sys.argv[1]))" "$1"; }

# live_name:repo_name — names differ for the two global instruction files, since a
# bare CLAUDE.md in the repo gets hard-blocked by the academic-research-skills
# plugin's write-scope guard (see root CLAUDE.md).
pairs=(
    "skills:skills"
    "agents:agents"
    "memory:memory"
    "hooks:hooks"
    "CLAUDE.md:global-CLAUDE.md"
    "RTK.md:RTK.md"
)

for pair in "${pairs[@]}"; do
    live_name="${pair%%:*}"
    repo_name="${pair##*:}"
    live="$CLAUDE_HOME/$live_name"
    repo="$DOTFILES/claude/$repo_name"

    if [[ -L "$live" ]]; then
        if [[ "$(realpath_py "$live")" == "$(realpath_py "$repo")" ]]; then
            echo "  $live_name: symlinked to repo, nothing to sync"
        else
            echo "  $live_name: WARNING — symlink points elsewhere ($(readlink "$live")), check manually"
        fi
        continue
    fi

    if [[ ! -e "$live" ]]; then
        echo "  $live_name: not present locally, skipping"
        continue
    fi

    if [[ -f "$live" ]]; then
        if cmp -s "$live" "$repo" 2>/dev/null; then
            echo "  $live_name: real copy locally, but content already matches repo"
        else
            cp "$live" "$repo"
            echo "  $live_name: real copy locally (not a symlink) — copied into repo ($repo_name)"
        fi
        continue
    fi

    echo "  $live_name: real copy locally (not a symlink) — copying new/changed files into repo"
    # Per-entry, not a whole-tree rsync: some children (e.g. skills installed by an
    # external skill-installer) are themselves symlinks out of ~/.claude. The repo
    # intentionally freezes those as plain copies (see claude/README.md), and rsync -a
    # errors trying to replace a real destination dir with a symlink source in one pass.
    for child in "$live"/*; do
        [[ -e "$child" ]] || continue
        base="$(basename "$child")"
        if [[ -L "$child" ]]; then
            echo "    $base: live entry is a symlink -> $(readlink "$child") (external installer); repo keeps its frozen copy, skipping"
            continue
        fi
        rsync -a --checksum --itemize-changes "$child" "$repo/" | sed 's/^/    /'
    done

    extra="$(diff -rq "$live" "$repo" 2>/dev/null | grep '^Only in '"$repo"'' || true)"
    if [[ -n "$extra" ]]; then
        echo "    note: repo has files not present locally (kept, not deleted):"
        echo "$extra" | sed 's/^/      /'
    fi
done

echo ""
echo "== 3. Other untracked top-level ~/.claude files =="
found_untracked=0
for f in keybindings.json; do
    if [[ -e "$CLAUDE_HOME/$f" && ! -e "$DOTFILES/claude/$f" ]]; then
        echo "  ~/.claude/$f exists locally but isn't tracked in the repo yet."
        found_untracked=1
    fi
done
[[ "$found_untracked" -eq 0 ]] && echo "  none."

echo ""
echo "Done. Review with:"
echo "  git -C \"$DOTFILES\" status"
echo "  git -C \"$DOTFILES\" diff"

#!/usr/bin/env bash
set -euo pipefail

# Bootstrap the Claude Code environment on a workstation.
#
# Strategy (see claude/README.md):
#   - authored content (skills, agents, memory, hooks) -> symlinked from this repo
#   - declarative config (settings.json)               -> symlinked from this repo (no credentials)
#   - rtk CLI (used by the Bash hook in settings.json) -> installed if missing
#   - plugins/marketplaces                             -> installed via claude/install-plugins.sh
#   - login                                            -> run `claude` once and sign in (subscription)
#
# Idempotent: safe to re-run. Existing real dirs/files are backed up before linking.

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_HOME="$HOME/.claude"

echo "Bootstrapping from $DOTFILES"

# Symlink $src -> $dst, backing up any pre-existing real file/dir first.
backup_and_link() {
    local src="$1" dst="$2"
    if [[ -L "$dst" ]]; then
        ln -sfn "$src" "$dst"
        echo "  re-linked $dst -> $src"
        return
    fi
    if [[ -e "$dst" ]]; then
        local bak="${dst}.bak.$(date +%Y%m%d%H%M%S)"
        mv "$dst" "$bak"
        echo "  backed up $dst -> $bak"
    fi
    ln -sfn "$src" "$dst"
    echo "  linked $dst -> $src"
}

mkdir -p "$CLAUDE_HOME"

echo "Linking Claude content (skills, agents, memory, hooks)..."
backup_and_link "$DOTFILES/claude/skills" "$CLAUDE_HOME/skills"
backup_and_link "$DOTFILES/claude/agents" "$CLAUDE_HOME/agents"
backup_and_link "$DOTFILES/claude/memory" "$CLAUDE_HOME/memory"
backup_and_link "$DOTFILES/claude/hooks" "$CLAUDE_HOME/hooks"

echo "Linking global user instructions (CLAUDE.md, RTK.md)..."
backup_and_link "$DOTFILES/claude/global-CLAUDE.md" "$CLAUDE_HOME/CLAUDE.md"
backup_and_link "$DOTFILES/claude/RTK.md" "$CLAUDE_HOME/RTK.md"

echo "Linking settings.json..."
backup_and_link "$DOTFILES/claude/settings.json" "$CLAUDE_HOME/settings.json"

echo "Checking rtk (the Bash hook in settings.json calls it)..."
if ! command -v rtk >/dev/null 2>&1; then
    if command -v brew >/dev/null 2>&1; then
        brew install rtk
    else
        curl -fsSL https://raw.githubusercontent.com/rtk-ai/rtk/refs/heads/master/install.sh | sh
    fi
fi
# A different crate is also named rtk; only Rust Token Killer has `gain`.
# `rtk init -g` is not run here: the hook is already in the linked settings.json.
rtk gain >/dev/null 2>&1 || echo "  WARNING: rtk is missing or is the wrong tool; check that ~/.local/bin is on PATH"

echo "Activating git secret-scan pre-commit hook..."
git -C "$DOTFILES" config core.hooksPath .githooks

echo "Installing Claude Code plugins..."
bash "$DOTFILES/claude/install-plugins.sh"

echo ""
echo "Done. Remaining manual steps:"
echo "  1. Run 'claude' once and sign in with your subscription"
echo "  2. Restart your shell so PATH changes (for example ~/.local/bin for rtk) apply"
echo "  3. Install VS Code extensions: see .vscode/extensions.json"

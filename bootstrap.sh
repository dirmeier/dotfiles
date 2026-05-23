#!/usr/bin/env bash
set -euo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "Bootstrapping from $DOTFILES"

# Claude Code — symlink skills and memory into ~/.claude
# Note: settings.json is NOT synced (contains credentials). Configure manually.
mkdir -p ~/.claude

link() {
    local src="$1" dst="$2"
    if [[ -e "$dst" && ! -L "$dst" ]]; then
        echo "Backing up $dst -> ${dst}.bak"
        mv "$dst" "${dst}.bak"
    fi
    ln -sfn "$src" "$dst"
    echo "  linked $dst -> $src"
}

echo "Linking Claude Code files..."
link "$DOTFILES/claude/skills"  ~/.claude/skills
link "$DOTFILES/claude/memory"  ~/.claude/memory

echo "Installing Claude Code plugins..."
bash "$DOTFILES/claude/install-plugins.sh"

echo ""
echo "Done. Remaining manual steps:"
echo "  1. Configure ~/.claude/settings.json (API endpoint, auth token)"
echo "  2. Install VS Code extensions: see .vscode/extensions.json"

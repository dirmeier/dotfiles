#!/usr/bin/env bash
set -euo pipefail

# Installs all Claude Code plugins from the official marketplace.
# Run once after cloning dotfiles on a new machine.

plugins=(
    context7
    code-review
    code-simplifier
    skill-creator
    claude-md-management
    commit-commands
    github
    superpowers
)

for plugin in "${plugins[@]}"; do
    echo "Installing $plugin..."
    claude plugins install "${plugin}@claude-plugins-official"
done

echo "Done. All plugins installed."

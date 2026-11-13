# Claude Code environment

Reproducible Claude Code setup across machines. Everything here is deployed by
the repo's top-level `bootstrap.sh`. The target machine signs in with a Claude
subscription, so no token or gateway URL is configured anywhere.

## How it works — three kinds of state, three strategies

| Kind | What | Strategy |
|------|------|----------|
| **Authored content** | `skills/`, `agents/`, `memory/`, `hooks/`, `global-CLAUDE.md`, `RTK.md` | **Symlinked** into `~/.claude/` — the repo is the single source of truth, so edits show up in `git status` immediately and a `git pull` on another machine is instantly live. |
| **Declarative config** | `settings.json` | **Symlinked** into `~/.claude/settings.json`. Holds model, theme, effort level, hooks, enabled plugins, and known marketplaces. No credentials. |
| **Plugins & marketplaces** | the 16 enabled plugins | Installed by `install-plugins.sh`, which reads the list straight out of `settings.json` (so the two can't drift). |

## Files

- `settings.json` — user settings. The live `~/.claude/settings.json` is a
  symlink to this. **No `env` block lives here.**
- `install-plugins.sh` — adds marketplaces and installs every plugin listed in
  `settings.json`. Idempotent. Needs `python3` and the `claude` CLI.
- `sync-from-live.sh` — the reverse direction: pulls drift from the live
  `~/.claude` env back into this repo (new plugins you installed locally,
  files that drifted from symlink to real copy). Additive only, never
  deletes, never commits. Run it whenever you've upgraded your local Claude
  Code setup and want the repo to catch up.
- `skills/` — user skills, all real copies (self-contained). Some were originally
  symlinks into `~/.agents/skills/` (a skill-installer location with a
  `.skill-lock.json`); they're frozen here as plain files so no external installer
  is needed on another machine.
- `agents/` — user subagents (`planner`, `web-search-agent` + `web-search-modules`).
- `hooks/` — hook scripts that `settings.json` calls. `ste100-reminder.sh` adds the
  plain-English writing rule to every prompt (`UserPromptSubmit` hook).
- `memory/` — user-level Claude memory (`MEMORY.md` + feedback notes).
- `global-CLAUDE.md` — mirrors `~/.claude/CLAUDE.md` (global user instructions,
  currently just `@RTK.md`). Named `global-CLAUDE.md` instead of `CLAUDE.md`
  because the `academic-research-skills` plugin hard-blocks writes to any file
  literally named `CLAUDE.md` — see root `CLAUDE.md` for detail.
- `RTK.md` — mirrors `~/.claude/RTK.md`, the `rtk` CLI proxy reference.

## Setup on a new (or existing) machine

```sh
git clone git@github.com:dirmeier/dotfiles.git ~/PROJECTS/_dotfiles
cd ~/PROJECTS/_dotfiles
./bootstrap.sh
```

`bootstrap.sh` will:

1. Back up any existing real `~/.claude/{skills,agents,memory,hooks,CLAUDE.md,RTK.md,settings.json}` and symlink them to this repo.
2. Install `rtk` if it is missing (`brew install rtk`, or the official install script). The `PreToolUse` hook in `settings.json` calls it.
3. Activate the secret-scanning pre-commit hook (`git config core.hooksPath .githooks`).
4. Run `install-plugins.sh`.

Then:

- Run `claude` once and sign in with your subscription.
- Restart your shell so PATH changes apply (`rtk` may land in `~/.local/bin`).

## Credentials policy (repo is PUBLIC)

- The committed `settings.json` has **no credentials**.
- `.gitignore` blocks stray `settings.local.json` / `*.bak` files.
- The `.githooks/pre-commit` hook scans staged changes for token signatures
  (e.g. `ANTHROPIC_AUTH_TOKEN`, `eyJ…`) and **aborts the commit** if any appear.

## Adding a plugin or marketplace later

Two ways:

- **Installed it locally first?** Run `./claude/sync-from-live.sh` — it pulls
  the new `enabledPlugins`/`extraKnownMarketplaces` entries out of your live
  `~/.claude/settings.json` into this repo automatically.
- **Editing the repo first?** Edit `settings.json` by hand (add the plugin to
  `enabledPlugins`, and the marketplace to `extraKnownMarketplaces` if it's
  new), then run `./claude/install-plugins.sh` to install it locally.

Either way: commit `settings.json` and pull on the other machine.

See the root `CLAUDE.md` for the full runbook on repeating this sync task.

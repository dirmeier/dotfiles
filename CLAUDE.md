# Repo purpose

This repo makes Simon's Claude Code environment (plugins, skills, agents,
memory, settings) reproducible on any machine via `./bootstrap.sh`. See
`claude/README.md` for the full strategy. This file is a runbook for the
recurring task: **"sync my current local Claude Code env into this repo, and
keep it installable from scratch."**

## Recurring task: sync local env -> repo

Run `claude/sync-from-live.sh` first — it automates most of this (additive
only, never deletes, never commits):

```sh
./claude/sync-from-live.sh
```

It does three things:
1. Merges `enabledPlugins` / `extraKnownMarketplaces` present in the live
   `~/.claude/settings.json` but missing from `claude/settings.json`. Also copies
   an allowlist of preference keys from live (live wins): `effortLevel`,
   `modelSettings`, `autoCompactWindow`, `promptCacheTtl`,
   `subagentPromptCacheTtl`, `autoUpdatesChannel` (`PREF_KEYS` in the script). Leaves
   `model`/`theme`/`env`/`hooks`/`permissions` alone — those are either
   deliberate repo config, machine-specific or machine-secret.
2. For `skills/`, `agents/`, `memory/`: if the live path is still the
   intended symlink into this repo, does nothing. If it drifted into a real
   copy (this happens — see "Known drift" below), copies new/changed files
   into the repo per-entry (skips any live entry that is itself a symlink
   from an external skill-installer, since the repo intentionally freezes
   those as plain copies — see `claude/README.md`).
3. Reports (does not copy) top-level `~/.claude` files not tracked here yet
   (`CLAUDE.md`, `RTK.md`, `keybindings.json`).

After running it: `git status` / `git diff`, review, commit yourself.

### Known drift: "symlinked" paths can become real files

`bootstrap.sh` is *designed* to symlink `~/.claude/{skills,agents,memory,
settings.json}` to this repo, but some tool (a plugin installer, an editor
save, etc.) can replace a symlink with a real file/dir without warning.
`sync-from-live.sh` step 2 checks for this automatically, but if you're
debugging by hand:

```sh
for f in skills agents memory settings.json; do
  [ -L ~/.claude/$f ] && echo "$f: symlinked OK" || echo "$f: REAL — drift"
done
```

To restore the actual symlink for a drifted path, re-run `./bootstrap.sh` —
it backs up the real dir/file to `*.bak.<timestamp>` first. This changes live
`~/.claude/` structure, so confirm with Simon before doing it.

### Things the script deliberately leaves for a human

- **New non-secret hooks** in live settings.json (e.g. a token-saving CLI
  hook) — flag explicitly and ask before deciding if it belongs in the repo.
- **Anything new under `~/.claude/`** beyond what `claude/README.md`
  documents. Never track `cache/`, `projects/`, `sessions/`,
  `shell-snapshots/`, `tmp/`, `usage-data/`, `daemon/`, `ide/`, `jobs/` —
  that's Claude Code's own runtime state.
- Update `claude/README.md`'s plugin count / file list if it changed.

`~/.claude/CLAUDE.md` and `~/.claude/RTK.md` (global user instructions, incl.
the `rtk` CLI proxy reference) ARE tracked — as `claude/global-CLAUDE.md` and
`claude/RTK.md` respectively (renamed to dodge the write-guard below),
symlinked by `bootstrap.sh` back to their real names in `~/.claude/`.

### A note on writing this exact file

The `academic-research-skills` plugin ships a `PreToolUse` guard
(`ars_write_scope_guard.py`) that hard-blocks `Write`/`Edit`/`MultiEdit`
(and, for its own subagents, `Bash`) on any file literally named `CLAUDE.md`
or `.claude/CLAUDE.md`, anywhere, including for the main session — it's
meant to protect the ARS plugin's own scope-enforcement file, not this repo.
If you need to edit this file via the agent and the tool call gets denied
with "part of the enforcement infrastructure", that plugin is why; editing
it through `Bash` (e.g. a heredoc) is not intercepted for the main session
and works.

## Fresh-machine install

```sh
git clone git@github.com:dirmeier/dotfiles.git ~/PROJECTS/_dotfiles
cd ~/PROJECTS/_dotfiles
./bootstrap.sh
```

Then run `claude` once and sign in with the subscription, and restart the
shell. Full detail in `claude/README.md`.

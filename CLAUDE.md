# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repo is

A cross-platform (Linux + macOS) **dotfiles** repo — configs for Ghostty, shell
(bash/zsh), git, tmux, Neovim, and CLI tools (bat/fzf/ripgrep), installed by
symlink. No build step, no application code. Everything is bash scripts, config
files, and a small Lua Neovim config, all themed to one `muted-ink` palette.

## Commands

```bash
./install.sh [--copy] [--dry-run] [MODULE ...]   # install; MODULES: ghostty shell git tmux nvim cli
make install / dry-run / uninstall
make install-<module>        # e.g. make install-nvim
make doctor                  # report linked targets + missing binaries
make backup                  # tarball all managed files to ./backups/
make validate                # ghostty +validate-config (needs ghostty CLI)
make check                   # THE quality gate — run after editing any script
```

There is no test suite. `make check` is the gate: `bash -n` on all shell
scripts, plus `zsh -n`, `shellcheck`, and `luacheck` **when those tools are
present** (each step skips gracefully otherwise, so it exits 0 locally). CI
(`.github/workflows/check.yml`) installs them so the full gate runs on push/PR.

## Architecture (the important part)

**Module = top-level directory + its own `install.sh`.** The modules are
`ghostty/ shell/ git/ tmux/ nvim/ cli/`. The root `install.sh` is only an
orchestrator: it sets three env vars and then sources each selected module's
installer.

- `lib/common.sh` is the shared library every module installer sources. Its
  **`link_file SRC DEST`** is the core primitive: no-op if already linked,
  else mkdir parents → back up existing `DEST` to `DEST.backup-<ts>` → symlink
  (or copy). Also provides `backup_path`, `run` (dry-run wrapper), `have`, and
  exports `DOTFILES_ROOT`/`XDG_CONFIG_HOME`.
- Env contract between root and modules: `DOTFILES_MODE` (symlink|copy),
  `DOTFILES_DRY_RUN` (true|false), `DOTFILES_PLATFORM` (macos|linux|other).
  A module installer must honor these — always go through `link_file`/`run`,
  never `ln`/`cp`/`mv` directly, or `--dry-run` and `--copy` break.
- **Nothing private or generated lives in the repo.** Managed configs load an
  untracked local file last: `~/.gitconfig.local` (identity), `~/.bashrc.local`,
  `~/.zshrc.local`, `~/.config/ghostty/local.ghostty`. Put machine/secret
  settings there. `.gitignore` only needs `backups/` and `*.backup-*`.
- `scripts/` holds cross-cutting tools (`doctor.sh`, `backup.sh`,
  `uninstall.sh`); ghostty-specific helpers (`validate.sh`, `use-profile.sh`,
  `print-paths.sh`) live in `ghostty/`.

## Theming

`muted-ink` is defined once as a palette (hex in `ghostty/themes/muted-ink`) and
**re-expressed per tool** — changing a color means editing every expression:
`ghostty/themes/muted-ink`, `nvim/colors/muted-ink.lua`,
`nvim/lua/plugins/lualine.lua`, `cli/bat/themes/muted-ink.tmTheme` (also used by
git-delta via `syntax-theme = muted-ink`), `tmux/tmux.conf` status colors, the
`[delta]` block in `git/gitconfig`, and the `--colors`/`FZF_DEFAULT_OPTS` in
`cli/ripgrep/ripgreprc` and `shell/exports.sh`.

## Conventions

- Shell scripts: `set -euo pipefail`, a `usage()`, support `--dry-run`.
- `shell/aliases.sh` and `functions.sh` are sourced by **both** bash and zsh —
  keep them POSIX-compatible. `shell/bashrc` intentionally sources distro
  defaults (`/etc/bashrc`, `~/.bashrc.d`) so managing it doesn't break Fedora.
- Tools degrade gracefully when a binary is absent: `git` pager is
  `delta || less`; `ls` aliases fall back from `eza` to `ls`; the prompt uses
  starship if present else the bundled `shell/prompt/*` snippets.
- Ghostty config: comments on their own line — no trailing inline comments in
  `.ghostty` files. Validate real changes with `make validate`.
- Binaries are NOT installed by this repo; `docs/BOOTSTRAP.md` has the per-OS
  package commands (everything but starship is in Fedora repos).

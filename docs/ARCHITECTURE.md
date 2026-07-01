# Architecture

## Layout

Each tool is a self-contained **module** — a top-level directory holding its
config files plus an `install.sh`:

```text
.
├── install.sh          # orchestrator: runs each module's install.sh
├── lib/common.sh       # shared bash helpers (link_file, backup_path, run, ...)
├── ghostty/            # terminal emulator config + muted-ink theme
├── shell/              # managed bashrc/zshrc, aliases/exports/functions, prompt, starship
├── git/                # gitconfig, delta theme, global ignore
├── tmux/               # tmux.conf
├── nvim/               # lazy.nvim config + muted-ink colorscheme
├── cli/                # bat, ripgrep (fzf configured via env)
├── scripts/            # cross-cutting: doctor, backup, uninstall
└── docs/
```

## Install model

`./install.sh [modules...]` sets three environment variables and then sources
each selected module's `install.sh`:

- `DOTFILES_MODE` — `symlink` (default) or `copy`
- `DOTFILES_DRY_RUN` — `true` prints actions without touching the filesystem
- `DOTFILES_PLATFORM` — `macos` / `linux` / `other` (from `uname`)

Every module installer sources `lib/common.sh` and uses **`link_file SRC DEST`**,
which:

1. no-ops if `DEST` already links to the repo;
2. creates parent directories;
3. backs up anything already at `DEST` to `DEST.backup-<timestamp>`;
4. symlinks (or copies) `SRC` → `DEST`.

Because installs are just symlinks, editing a file in the repo immediately
changes the live config. Nothing is generated back into the repo except
`nvim/lazy-lock.json` (plugin version pins, intentionally tracked).

## Config precedence and local overrides

Nothing private lives in the repo. Each tool has an **untracked** local-override
file the managed config loads last, so machine-specific or secret settings never
get committed:

| Tool    | Managed (repo)         | Local override (untracked) |
|---------|------------------------|----------------------------|
| bash    | `shell/bashrc`         | `~/.bashrc.local` |
| zsh     | `shell/zshrc`          | `~/.zshrc.local` |
| git     | `git/gitconfig`        | `~/.gitconfig.local` (identity, signing keys) |
| ghostty | `ghostty/config.ghostty` | `~/.config/ghostty/local.ghostty` |

## Theming

`muted-ink` is defined once as a palette and re-expressed per tool so the whole
environment matches: Ghostty theme, a Neovim colorscheme, a bat/delta
`.tmTheme`, a lualine theme, tmux status colors, and fzf/ripgrep color flags.
See [THEMES.md](THEMES.md).

## Uninstall / rollback

`scripts/uninstall.sh` removes only symlinks that point back into this repo
(foreign files are left alone) and can `--restore-backup` the most recent
`.backup-*` for each target. `scripts/backup.sh` snapshots all managed paths to
`./backups/` as a tarball before you make changes.

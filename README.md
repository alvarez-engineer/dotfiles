# dotfiles

A cross-platform (Linux + macOS) development environment, version-controlled and
installed by symlink. One `muted-ink` dark theme runs across every tool:
terminal, editor, multiplexer, git diffs, and CLI utilities.

Each tool is a self-contained **module** with its own config and installer. Use
all of them or just the ones you want.

## Modules

| Module    | Configures | Installs to |
|-----------|-----------|-------------|
| `ghostty` | Ghostty terminal + muted-ink theme, per-platform profiles | `~/.config/ghostty` |
| `shell`   | Managed `bashrc`/`zshrc`, aliases/exports/functions, prompt, starship | `~/.bashrc`, `~/.zshrc`, `~/.config/starship.toml` |
| `git`     | `gitconfig`, delta pager (muted-ink), global ignore | `~/.gitconfig`, `~/.config/git/ignore` |
| `tmux`    | Themed `tmux.conf` | `~/.config/tmux/tmux.conf` |
| `nvim`    | Minimal lazy.nvim setup + muted-ink colorscheme | `~/.config/nvim` |
| `cli`     | bat, ripgrep, fzf (theming + config) | `~/.config/{bat,ripgrep}` |

## Quick start

```bash
git clone <your-repo-url> dotfiles
cd dotfiles

# Tools + configs in one shot (bootstrap installs binaries via dnf/apt/brew,
# using sudo on Linux; then all configs are symlinked, backing up existing files)
./install.sh --bootstrap

# Or do the two steps separately / selectively:
./scripts/bootstrap.sh       # just install the tool binaries   (make bootstrap)
./install.sh                 # just symlink all configs         (make install)
./install.sh --dry-run       # preview without changing anything
./install.sh shell git nvim  # only some modules
```

See [docs/BOOTSTRAP.md](docs/BOOTSTRAP.md) for per-OS details and manual steps.
Config for a tool you haven't installed yet is harmless — it waits until the
binary exists. After adding your git identity to `~/.gitconfig.local`, launch
`nvim` once so lazy.nvim installs plugins.

## Everyday commands

```bash
make bootstrap       # install tool binaries (dnf/apt/brew); -dev adds linters
make all             # bootstrap + install in one shot
make install         # ./install.sh (configs only)
make dry-run         # preview all actions
make install-nvim    # one module (also: -shell -git -tmux -ghostty -cli)
make doctor          # what's linked, what tools are missing
make backup          # tarball all managed files to ./backups/ before changes
make validate        # ghostty +validate-config (needs the ghostty CLI)
make uninstall       # remove our symlinks (add --restore-backup to roll back)
make check           # syntax + lint gate (bash/zsh/shellcheck/luacheck)
```

## How it works

- **Symlinks, not copies** (by default): edit a file in the repo and the live
  config changes immediately. Use `--copy` if you prefer independent copies.
- **Backups**: anything already at a target is moved to `<target>.backup-<ts>`.
- **Nothing private in the repo**: identity/secrets/machine tweaks go in
  untracked local files (`~/.gitconfig.local`, `~/.bashrc.local`, …) that the
  managed configs load last.
- **One palette everywhere**: `muted-ink` is defined once and re-expressed per
  tool. See [docs/THEMES.md](docs/THEMES.md).

Full details in [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md).

## Documentation

- [Bootstrap (install the binaries)](docs/BOOTSTRAP.md)
- [Architecture](docs/ARCHITECTURE.md)
- Modules: [Shell](docs/SHELL.md) · [Git](docs/GIT.md) · [tmux](docs/TMUX.md) · [Neovim](docs/NVIM.md) · [CLI tools](docs/CLI.md)
- Ghostty: [macOS](docs/MACOS.md) · [Linux](docs/LINUX.md) · [Fonts](docs/FONTS.md) · [Themes](docs/THEMES.md) · [Keybindings](docs/KEYBINDS.md) · [Shell integration](docs/SHELL_INTEGRATION.md) · [Prompt](docs/PROMPT.md)
- [Troubleshooting](docs/TROUBLESHOOTING.md) · [Maintenance](docs/MAINTENANCE.md) · [Community cheatsheet](docs/COMMUNITY_CHEATSHEET.md) · [References](docs/REFERENCES.md)

## Uninstall

```bash
./scripts/uninstall.sh                    # remove symlinks that point into this repo
./scripts/uninstall.sh --restore-backup   # and restore the most recent backups
```

Foreign files (anything not a symlink into this repo) are never touched.

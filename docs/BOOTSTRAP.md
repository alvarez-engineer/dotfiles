# Bootstrap: installing the tool binaries

The dotfiles **configure** tools; they do not install the binaries. Install the
programs first (or alongside), then run `./install.sh` to symlink the configs.

Config for a tool that isn't installed yet is harmless — it simply sits ready
until you install the binary.

## Automated (recommended)

`scripts/bootstrap.sh` detects your platform (dnf / apt / brew) and installs the
whole toolchain, including Starship via its official script where it isn't
packaged. It uses `sudo` on Linux (you'll be prompted).

```bash
./scripts/bootstrap.sh            # install all tools      (make bootstrap)
./scripts/bootstrap.sh --dev      # tools + gate linters   (make bootstrap-dev)
./scripts/bootstrap.sh --dry-run  # print the commands, change nothing

# One shot — tools then configs:
./install.sh --bootstrap          # (make all)
```

`--dev` adds the `make check` linters (`shellcheck`, and `luacheck` via
LuaRocks). Everything below is the equivalent **manual** path, per OS.

## Fedora / RHEL (dnf)

Everything except Starship is in the Fedora repositories:

```bash
sudo dnf install -y neovim tmux fzf ripgrep bat eza git-delta zsh fd-find
```

Starship and opencode are not in the Fedora repos — use their official
installers. Both pipe a downloaded script straight into a shell, so read them
first if that matters to you; `scripts/bootstrap.sh` runs the same two commands.

```bash
curl -sS https://starship.rs/install.sh | sh
curl -fsSL https://opencode.ai/install | bash
```

Dev-gate linters (only needed to run `make check` locally):

```bash
sudo dnf install -y ShellCheck luarocks && sudo luarocks install luacheck
```

Ghostty itself: install from https://ghostty.org/download (or your distro's
package). It is optional — the rest of the dotfiles work without it.

## macOS (Homebrew)

```bash
brew install neovim tmux fzf ripgrep bat eza git-delta starship zsh fd opencode
brew install --cask ghostty
```

Homebrew puts binaries in `/opt/homebrew/bin` (Apple Silicon) or
`/usr/local/bin` (Intel) — never `/usr/bin`. Nothing in this repo hardcodes a
tool's absolute path for exactly that reason.

## Debian / Ubuntu (apt)

```bash
sudo apt update
sudo apt install -y neovim tmux fzf ripgrep bat eza git zsh fd-find
# 'bat' installs as 'batcat' and 'fd' as 'fdfind' on Debian.
# delta:    download the .deb from https://github.com/dandavison/delta/releases
# starship: curl -sS https://starship.rs/install.sh | sh
# opencode: curl -fsSL https://opencode.ai/install | bash
```

`eza` is absent from older apt repos; `scripts/bootstrap.sh` warns and carries
on rather than failing the run. The `ls` aliases fall back to plain `ls`.

## What each tool is for

| Tool       | Used by module | Purpose |
|------------|----------------|---------|
| ghostty    | ghostty        | Terminal emulator (the anchor) |
| neovim     | nvim           | Editor; muted-ink colorscheme + lazy.nvim |
| tmux       | tmux           | Terminal multiplexer / persistent sessions |
| starship   | shell          | Cross-shell prompt (falls back to bundled prompt) |
| fzf        | shell, cli, notes | Fuzzy finder + shell key bindings; `bdf`/`bdg` |
| ripgrep    | shell, cli, notes | Fast search; Telescope live-grep; `bdg` |
| fd         | (optional)     | Fast file finder |
| bat        | cli, notes     | `cat` with highlighting; delta's syntax themer; `bdf` preview |
| eza        | shell          | Modern `ls` (aliases fall back to `ls` if absent) |
| git-delta  | git            | Git pager (falls back to `less` if absent) |
| zsh        | shell          | Optional shell; a managed `.zshrc` is provided |
| opencode   | opencode       | AI coding agent (installed via its official script) |
| gh         | git (optional) | GitHub credential helper; resolved through `PATH` |

The `notes` module needs **no binaries at all** to capture and route notes —
`bd` and `bdsplit` are plain bash. `fzf` (and `ripgrep`) only unlock the `bdf`
and `bdg` searchers, which fail with a clear message if the tool is missing.

## After installing binaries

```bash
./install.sh          # (re)link configs; picks up newly installed tools
make doctor           # confirm what's linked and what's still missing
nvim                  # first launch: lazy.nvim installs plugins + parsers
```

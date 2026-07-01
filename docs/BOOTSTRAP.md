# Bootstrap: installing the tool binaries

The dotfiles **configure** tools; they do not install the binaries. Install the
programs first (or alongside), then run `./install.sh` to symlink the configs.

Config for a tool that isn't installed yet is harmless — it simply sits ready
until you install the binary.

## Fedora / RHEL (dnf)

Everything except Starship is in the Fedora repositories:

```bash
sudo dnf install -y neovim tmux fzf ripgrep bat eza git-delta zsh fd-find
```

Starship is not in the Fedora repos — use the official installer:

```bash
curl -sS https://starship.rs/install.sh | sh
```

Ghostty itself: install from https://ghostty.org/download (or your distro's
package). It is optional — the rest of the dotfiles work without it.

## macOS (Homebrew)

```bash
brew install neovim tmux fzf ripgrep bat eza git-delta starship zsh fd
brew install --cask ghostty
```

## Debian / Ubuntu (apt)

```bash
sudo apt update
sudo apt install -y neovim tmux fzf ripgrep bat eza git zsh fd-find
# 'bat' installs as 'batcat' and 'fd' as 'fdfind' on Debian.
# delta: download the .deb from https://github.com/dandavison/delta/releases
# starship: curl -sS https://starship.rs/install.sh | sh
```

## What each tool is for

| Tool       | Used by module | Purpose |
|------------|----------------|---------|
| ghostty    | ghostty        | Terminal emulator (the anchor) |
| neovim     | nvim           | Editor; muted-ink colorscheme + lazy.nvim |
| tmux       | tmux           | Terminal multiplexer / persistent sessions |
| starship   | shell          | Cross-shell prompt (falls back to bundled prompt) |
| fzf        | shell, cli     | Fuzzy finder + shell key bindings |
| ripgrep    | shell, cli     | Fast search; powers Telescope live-grep |
| fd         | (optional)     | Fast file finder |
| bat        | cli            | `cat` with syntax highlighting; delta's syntax themer |
| eza        | shell          | Modern `ls` (aliases fall back to `ls` if absent) |
| git-delta  | git            | Git pager (falls back to `less` if absent) |
| zsh        | shell          | Optional shell; a managed `.zshrc` is provided |

## After installing binaries

```bash
./install.sh          # (re)link configs; picks up newly installed tools
make doctor           # confirm what's linked and what's still missing
nvim                  # first launch: lazy.nvim installs plugins + parsers
```

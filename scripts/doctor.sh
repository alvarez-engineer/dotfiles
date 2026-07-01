#!/usr/bin/env bash
set -euo pipefail

# Reports the health of the dotfiles install: which tools are present, which
# config targets are symlinked back into this repo, and which binaries are
# still missing.

repo_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
xdg="${XDG_CONFIG_HOME:-$HOME/.config}"

printf 'dotfiles doctor\n===============\n\n'
printf 'repo:     %s\n' "$repo_root"
printf 'OS:       %s\n' "$(uname -srm)"
printf 'shell:    %s\n' "${SHELL:-unknown}"
printf 'XDG_CONFIG_HOME: %s\n\n' "$xdg"

printf 'Tools:\n'
for b in ghostty nvim tmux git starship fzf rg bat eza delta zsh; do
  if command -v "$b" >/dev/null 2>&1; then
    printf '  [x] %-9s %s\n' "$b" "$(command -v "$b")"
  else
    printf '  [ ] %-9s missing\n' "$b"
  fi
done

printf '\nLinked config targets:\n'
targets=(
  "$HOME/.bashrc"
  "$HOME/.zshrc"
  "$HOME/.gitconfig"
  "$xdg/starship.toml"
  "$xdg/git/ignore"
  "$xdg/ghostty/config.ghostty"
  "$xdg/tmux/tmux.conf"
  "$xdg/nvim"
  "$xdg/bat/config"
  "$xdg/ripgrep/ripgreprc"
)
for t in "${targets[@]}"; do
  if [[ -L "$t" ]]; then
    dest="$(readlink -f "$t" 2>/dev/null || true)"
    case "$dest" in
      "$repo_root"/*) printf '  [x] %-34s -> repo\n' "${t/#$HOME/~}" ;;
      *)              printf '  [!] %-34s -> %s (foreign)\n' "${t/#$HOME/~}" "$dest" ;;
    esac
  elif [[ -e "$t" ]]; then
    printf '  [o] %-34s exists but is not a symlink\n' "${t/#$HOME/~}"
  else
    printf '  [ ] %-34s absent\n' "${t/#$HOME/~}"
  fi
done

if command -v ghostty >/dev/null 2>&1 && [[ -f "$xdg/ghostty/config.ghostty" ]]; then
  printf '\nGhostty config:\n'
  # +show-config reads the default config (our symlink) and warns on bad keys.
  # Preferred over +validate-config, which is broken in some headless/snap builds.
  warn_out="$(ghostty +show-config 2>&1 >/dev/null || true)"
  if [[ -z "$warn_out" ]]; then
    printf '  ok (no warnings from +show-config)\n'
  else
    printf '  warnings:\n%s\n' "$warn_out"
  fi
fi

printf '\nMissing binaries can be installed via docs/BOOTSTRAP.md\n'

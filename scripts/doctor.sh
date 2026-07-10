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

# VS Code's config root moves with the install flavor. Mirrors vscode/install.sh.
if [[ -d "$HOME/.var/app/com.visualstudio.code" ]]; then
  vscode_user="$HOME/.var/app/com.visualstudio.code/config/Code/User"
  vscode_ext="$HOME/.var/app/com.visualstudio.code/data/vscode/extensions"
elif [[ "$(uname -s)" == "Darwin" ]]; then
  vscode_user="$HOME/Library/Application Support/Code/User"
  vscode_ext="$HOME/.vscode/extensions"
else
  vscode_user="$xdg/Code/User"
  vscode_ext="$HOME/.vscode/extensions"
fi

printf 'Tools:\n'
for b in ghostty nvim tmux git starship fzf rg bat eza delta zsh opencode code claude; do
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
  "$xdg/opencode/opencode.json"
  "$vscode_user/settings.json"
  "$vscode_ext/dotfiles.muted-ink-1.0.0"
  "$vscode_ext/dotfiles.workbench-1.0.0"
  "$HOME/.local/bin/code"
  "$HOME/.local/bin/dev-shell"
  "$HOME/.claude/statusline.sh"
  "$HOME/.local/bin/bd"
  "$HOME/.local/bin/bdsplit"
  "$HOME/.local/bin/bdf"
  "$HOME/.local/bin/bdg"
)
for t in "${targets[@]}"; do
  if [[ -L "$t" ]]; then
    dest="$(readlink -f "$t" 2>/dev/null || true)"
    case "$dest" in
      "$repo_root"/*) printf '  [x] %-34s -> repo\n' "${t/#$HOME/\~}" ;;
      *)              printf '  [!] %-34s -> %s (foreign)\n' "${t/#$HOME/\~}" "$dest" ;;
    esac
  elif [[ -e "$t" ]]; then
    printf '  [o] %-34s exists but is not a symlink\n' "${t/#$HOME/\~}"
  else
    printf '  [ ] %-34s absent\n' "${t/#$HOME/\~}"
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

notes_dir="${NOTES_DIR:-$HOME/notes}"
printf '\nNotes:\n'
printf '  dir:    %s' "${notes_dir/#$HOME/\~}"
if [[ -d "$notes_dir" ]]; then
  printf '\n'
  if [[ -d "$notes_dir/inbox" ]]; then
    # Count unrouted dumps without tripping `set -e` on an empty inbox.
    pending="$(find "$notes_dir/inbox" -maxdepth 1 -name '*.md' -type f | wc -l | tr -d ' ')"
    printf '  inbox:  %s dump(s) awaiting bdsplit\n' "$pending"
  else
    printf '  inbox:  absent (run: ./install.sh notes)\n'
  fi
  if git -C "$notes_dir" rev-parse --git-dir >/dev/null 2>&1; then
    origin="$(git -C "$notes_dir" remote get-url origin 2>/dev/null || true)"
    if [[ -n "$origin" ]]; then
      # Normalize scp-style (git@host:path) and https remotes to host/path.
      # Any host works — bdsplit --commit/--push never special-case one.
      host_path="${origin#*://}"
      host_path="${host_path#*@}"
      host_path="${host_path/://}"
      printf '  remote: %s\n' "${host_path%.git}"
    else
      printf '  remote: none (local git repo only)\n'
    fi
  else
    printf '  remote: not a git repo\n'
  fi
else
  printf ' (absent)\n'
fi

printf '\nMissing binaries can be installed via docs/BOOTSTRAP.md\n'

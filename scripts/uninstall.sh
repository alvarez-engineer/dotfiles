#!/usr/bin/env bash
set -euo pipefail

# Reverses ./install.sh: removes the symlinks this repo created and, optionally,
# restores the most recent timestamped backup for each target.

usage() {
  cat <<'EOF'
Usage: scripts/uninstall.sh [--restore-backup] [--dry-run]

Removes dotfiles symlinks that point back into this repo. Files that are not
symlinks into the repo are left untouched.

Options:
  --restore-backup   after removing each link, restore its most recent
                     <target>.backup-* if one exists
  --dry-run          print actions without changing files
  -h, --help         show this help
EOF
}

restore_backup="false"
dry_run="false"
while [[ $# -gt 0 ]]; do
  case "$1" in
    --restore-backup) restore_backup="true"; shift ;;
    --dry-run) dry_run="true"; shift ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown option: $1" >&2; usage; exit 1 ;;
  esac
done

repo_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
xdg="${XDG_CONFIG_HOME:-$HOME/.config}"

# Every target the module installers can create.
targets=(
  "$HOME/.bashrc"
  "$HOME/.zshrc"
  "$HOME/.gitconfig"
  "$xdg/starship.toml"
  "$xdg/git/ignore"
  "$xdg/ghostty/config.ghostty"
  "$xdg/ghostty/profiles"
  "$xdg/ghostty/themes"
  "$xdg/ghostty/local.example.ghostty"
  "$xdg/tmux/tmux.conf"
  "$xdg/nvim"
  "$xdg/bat/config"
  "$xdg/bat/themes/muted-ink.tmTheme"
  "$xdg/ripgrep/ripgreprc"
)

run() { if [[ "$dry_run" == "true" ]]; then printf 'DRY RUN: %s\n' "$*"; else "$@"; fi; }

for t in "${targets[@]}"; do
  if [[ ! -L "$t" ]]; then
    continue
  fi

  link_dest="$(readlink -f "$t" 2>/dev/null || true)"
  case "$link_dest" in
    "$repo_root"/*)
      echo "Removing symlink: $t"
      run rm -f "$t"
      ;;
    *)
      echo "Skipping (not our symlink): $t"
      continue
      ;;
  esac

  if [[ "$restore_backup" == "true" ]]; then
    # Backup names are timestamped (no special chars), so ls -t is safe here.
    # shellcheck disable=SC2012
    latest="$(ls -1dt "${t}".backup-* 2>/dev/null | head -n 1 || true)"
    if [[ -n "$latest" ]]; then
      echo "Restoring: $latest -> $t"
      run mv "$latest" "$t"
    fi
  fi
done

echo "Uninstall complete. Restart your shell to drop shell changes."

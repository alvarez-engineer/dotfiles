#!/usr/bin/env bash
set -euo pipefail

# Archive the current (pre-symlink) state of every file the dotfiles manage,
# so you can roll back even after installing. Writes to ./backups/.

repo_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
backup_dir="$repo_root/backups"
timestamp="$(date +%Y%m%d-%H%M%S)"
archive="$backup_dir/dotfiles-backup-$timestamp.tar.gz"

# Managed paths, relative to $HOME so they restore cleanly with `tar -C ~`.
#
# The untracked *.local files are here because they are the only irreplaceable
# things in the set — everything else can be re-linked from the repo.
#
# ~/.local/bin/{bd,bdsplit,bdf,bdg} is deliberately absent: those are symlinks
# into the repo, and `tar -h` would archive their contents, so restoring would
# drop real files on top of the links and silently freeze them at this version.
# $NOTES_DIR is absent for the same reason it is not in the repo — it is your
# data, and it should have its own git history.
rel_targets=(
  ".bashrc"
  ".bashrc.local"
  ".zshrc"
  ".zshrc.local"
  ".gitconfig"
  ".gitconfig.local"
  ".config/starship.toml"
  ".config/git/ignore"
  ".config/ghostty"
  ".config/tmux"
  ".config/nvim"
  ".config/bat"
  ".config/ripgrep"
  ".config/opencode/opencode.json"
  ".config/opencode/tui.json"
  ".config/opencode/themes"
)

present=()
for rel in "${rel_targets[@]}"; do
  [[ -e "$HOME/$rel" || -L "$HOME/$rel" ]] && present+=("$rel")
done

if [[ ${#present[@]} -eq 0 ]]; then
  echo "Nothing to back up." >&2
  exit 0
fi

mkdir -p "$backup_dir"
# -h dereferences symlinks so the archive holds real file contents.
tar -czhf "$archive" -C "$HOME" "${present[@]}" 2>/dev/null || \
  tar -czf "$archive" -C "$HOME" "${present[@]}"
echo "Created backup: $archive"
printf 'Included:\n'; printf '  %s\n' "${present[@]}"

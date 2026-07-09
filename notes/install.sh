#!/usr/bin/env bash
set -euo pipefail
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)/lib/common.sh"

src="$DOTFILES_ROOT/notes"
notes_dir="${NOTES_DIR:-$HOME/notes}"
bin_dir="$HOME/.local/bin"

info "notes -> $bin_dir, $notes_dir"

# The commands. ~/.local/bin is already on PATH via shell/bashrc + shell/zshrc,
# but each script also defaults NOTES_DIR itself, so the notes module works even
# when the shell module is not installed.
for cmd in bd bdsplit bdf bdg; do
  link_file "$src/bin/$cmd" "$bin_dir/$cmd"
done

# The notes tree lives outside the repo: private, mutable, never tracked here.
run mkdir -p "$notes_dir/inbox" "$notes_dir/archive"

# seed_file SRC DEST — copy a starter file, but never over an existing one.
# Deliberately not link_file: these are your notes, not managed config. Linking
# them back into the repo would drag note content into version control.
seed_file() {
  local seed="$1" dest="$2"
  if [[ -e "$dest" ]]; then
    log "keep: $dest (already exists)"
  else
    log "seed: $dest"
    run cp -- "$seed" "$dest"
  fi
}

for f in todo questions remember; do
  seed_file "$src/skel/$f.md" "$notes_dir/$f.md"
done

log "notes dir: $notes_dir"

if git -C "$notes_dir" rev-parse --git-dir >/dev/null 2>&1; then
  remote="$(git -C "$notes_dir" remote get-url origin 2>/dev/null || true)"
  log "git repo: yes${remote:+ (origin: $remote)}"
else
  log "git repo: no — 'git -C $notes_dir init' to get history; bdsplit --commit needs it"
fi

have fzf || log "fzf not installed; bdf/bdg will be ready once it is"
have rg  || log "ripgrep not installed; bdg will be ready once it is"

cat <<EOF
  markers: '- [ ] todo'  '? question'  '! remember'
  capture: bd "some title"      route: bdsplit --dry-run
  details: $src/README.md
EOF

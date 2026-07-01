#!/usr/bin/env bash
# Shared helpers for dotfiles install scripts.
# Source this from a module's install.sh:
#   source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)/lib/common.sh"
#
# Respects two environment variables set by the top-level installer:
#   DOTFILES_DRY_RUN=true   print actions without changing the filesystem
#   DOTFILES_MODE=symlink|copy   how link_file installs (default symlink)

set -euo pipefail

: "${DOTFILES_DRY_RUN:=false}"
: "${DOTFILES_MODE:=symlink}"

# Repo root = parent of the dir holding this file.
DOTFILES_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
export DOTFILES_ROOT

# XDG base dirs with the usual fallbacks.
XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
export XDG_CONFIG_HOME

log()  { printf '  %s\n' "$*"; }
info() { printf '\n== %s ==\n' "$*"; }
warn() { printf 'warning: %s\n' "$*" >&2; }
die()  { printf 'error: %s\n' "$*" >&2; exit 1; }

# run CMD... — execute unless in dry-run mode.
run() {
  if [[ "$DOTFILES_DRY_RUN" == "true" ]]; then
    printf 'DRY RUN: %s\n' "$*"
  else
    "$@"
  fi
}

# backup_path PATH — move an existing file/dir/symlink aside with a timestamp.
# Safe to call when PATH does not exist. Never follows the target.
backup_path() {
  local target="$1"
  if [[ -e "$target" || -L "$target" ]]; then
    local backup="${target}.backup-$(date +%Y%m%d-%H%M%S)"
    log "backup: $target -> $backup"
    run mv "$target" "$backup"
  fi
}

# link_file SRC DEST — install SRC (repo path) at DEST, honoring DOTFILES_MODE.
# Creates parent dirs, backs up whatever is already at DEST, then symlinks
# (default) or copies. If DEST is already the correct symlink, it is a no-op.
link_file() {
  local src="$1" dest="$2"
  [[ -e "$src" ]] || die "source does not exist: $src"

  if [[ "$DOTFILES_MODE" == "symlink" && -L "$dest" && "$(readlink -- "$dest")" == "$src" ]]; then
    log "ok: $dest already links to repo"
    return 0
  fi

  run mkdir -p "$(dirname -- "$dest")"
  backup_path "$dest"

  if [[ "$DOTFILES_MODE" == "copy" ]]; then
    log "copy: $dest"
    run cp -R "$src" "$dest"
  else
    log "link: $dest -> $src"
    run ln -s "$src" "$dest"
  fi
}

# have CMD — true if CMD is on PATH.
have() { command -v "$1" >/dev/null 2>&1; }

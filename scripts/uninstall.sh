#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage: scripts/uninstall.sh [--restore-backup] [--dry-run]

Reverses scripts/install.sh and scripts/install-prompt.sh:
  - removes the managed prompt block from ~/.bashrc and ~/.zshrc
  - removes the installed Ghostty config (symlink or copied directory)

Options:
  --restore-backup   after removing, move the most recent
                     <config>.backup-* directory back into place
  --dry-run          print actions without changing files
  -h, --help         show this help
EOF
}

restore_backup="false"
dry_run="false"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --restore-backup)
      restore_backup="true"
      shift
      ;;
    --dry-run)
      dry_run="true"
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      usage
      exit 1
      ;;
  esac
done

config_dir="${XDG_CONFIG_HOME:-$HOME/.config}/ghostty"
block_start="# >>> ghostty muted coding prompt >>>"
block_end="# <<< ghostty muted coding prompt <<<"

run() {
  if [[ "$dry_run" == "true" ]]; then
    printf 'DRY RUN: %s\n' "$*"
  else
    "$@"
  fi
}

remove_prompt_block() {
  local rc_file="$1"
  [[ -f "$rc_file" ]] || return 0
  if ! grep -Fq "$block_start" "$rc_file"; then
    return 0
  fi

  local backup="${rc_file}.backup-$(date +%Y%m%d-%H%M%S)"
  echo "Removing prompt block from $rc_file (backup: $backup)"
  if [[ "$dry_run" == "true" ]]; then
    printf 'DRY RUN: strip block between markers in %s\n' "$rc_file"
    return 0
  fi

  cp "$rc_file" "$backup"
  # Delete the marker block. install-prompt.sh prepends a blank line before the
  # block, so hold each blank line back and drop it if the block starts next.
  local tmp
  tmp="$(mktemp)"
  awk -v s="$block_start" -v e="$block_end" '
    skip { if ($0 == e) skip = 0; next }
    $0 == s { skip = 1; held = 0; next }
    $0 == "" { if (held) print ""; held = 1; next }
    { if (held) { print ""; held = 0 } print }
    END { if (held) print "" }
  ' "$rc_file" >"$tmp"
  mv "$tmp" "$rc_file"
}

remove_config() {
  if [[ -L "$config_dir" ]]; then
    echo "Removing config symlink: $config_dir"
    run rm -f "$config_dir"
  elif [[ -d "$config_dir" ]]; then
    echo "Removing config directory: $config_dir"
    run rm -rf "$config_dir"
  else
    echo "No installed config at $config_dir"
  fi
}

restore_latest_backup() {
  local latest
  latest="$(ls -1d "${config_dir}".backup-* 2>/dev/null | sort | tail -n 1 || true)"
  if [[ -z "$latest" ]]; then
    echo "No backup found matching ${config_dir}.backup-*"
    return 0
  fi
  echo "Restoring backup: $latest -> $config_dir"
  run mv "$latest" "$config_dir"
}

remove_prompt_block "$HOME/.bashrc"
remove_prompt_block "$HOME/.zshrc"
remove_config

if [[ "$restore_backup" == "true" ]]; then
  restore_latest_backup
fi

echo "Uninstall complete. Restart your shell to drop the prompt changes."

#!/usr/bin/env bash
set -euo pipefail

config_dir="${XDG_CONFIG_HOME:-$HOME/.config}/ghostty"
backup_dir="$(pwd)/backups"
timestamp="$(date +%Y%m%d-%H%M%S)"
archive="$backup_dir/ghostty-config-$timestamp.tar.gz"

if [[ ! -e "$config_dir" ]]; then
  echo "No Ghostty config found at $config_dir" >&2
  exit 1
fi

mkdir -p "$backup_dir"
tar -czf "$archive" -C "$(dirname "$config_dir")" "$(basename "$config_dir")"
echo "Created backup: $archive"

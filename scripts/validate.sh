#!/usr/bin/env bash
set -euo pipefail

config_file="${1:-${XDG_CONFIG_HOME:-$HOME/.config}/ghostty/config.ghostty}"

if ! command -v ghostty >/dev/null 2>&1; then
  echo "Ghostty CLI was not found on PATH."
  echo "Install Ghostty first, then run: ghostty +validate-config --config-file '$config_file'"
  exit 127
fi

if [[ ! -f "$config_file" ]]; then
  echo "Config file not found: $config_file" >&2
  exit 1
fi

ghostty +validate-config --config-file "$config_file"

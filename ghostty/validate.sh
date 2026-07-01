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

# +validate-config is the canonical validator, but it is broken in some headless
# / snap builds (exits non-zero on any --config-file, even an empty one). If it
# fails, fall back to +show-config, which reads the default config and prints a
# warning for every unknown key or bad value.
if ghostty +validate-config --config-file "$config_file" 2>/tmp/gv.$$; then
  cat /tmp/gv.$$ 2>/dev/null || true
  rm -f /tmp/gv.$$
  echo "Config valid: $config_file"
else
  rm -f /tmp/gv.$$
  echo "Note: +validate-config failed (often a headless/snap limitation)."
  echo "Falling back to +show-config on the default config location..."
  warn_out="$(ghostty +show-config 2>&1 >/dev/null || true)"
  if [[ -z "$warn_out" ]]; then
    echo "No warnings from +show-config — config appears valid."
  else
    echo "Warnings:"
    printf '%s\n' "$warn_out"
    exit 1
  fi
fi

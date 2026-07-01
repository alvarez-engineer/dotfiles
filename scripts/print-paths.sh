#!/usr/bin/env bash
set -euo pipefail

cat <<EOF
Preferred cross-platform path:
  ${XDG_CONFIG_HOME:-$HOME/.config}/ghostty/config.ghostty

macOS-specific fallback paths:
  $HOME/Library/Application Support/com.mitchellh.ghostty/config.ghostty
  $HOME/Library/Application Support/com.mitchellh.ghostty/config

Legacy/older filename:
  ${XDG_CONFIG_HOME:-$HOME/.config}/ghostty/config
EOF

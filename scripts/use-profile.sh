#!/usr/bin/env bash
set -euo pipefail

profile="${1:-}"
config_dir="${XDG_CONFIG_HOME:-$HOME/.config}/ghostty"

if [[ -z "$profile" ]]; then
  echo "Usage: scripts/use-profile.sh macos|linux|minimal" >&2
  exit 1
fi

case "$profile" in
  macos|linux|minimal) ;;
  *)
    echo "Invalid profile: $profile" >&2
    echo "Expected one of: macos, linux, minimal" >&2
    exit 1
    ;;
esac

if [[ ! -d "$config_dir/profiles" ]]; then
  echo "Ghostty config profiles not found at $config_dir/profiles" >&2
  echo "Run ./scripts/install.sh first." >&2
  exit 1
fi

ln -sf "profiles/${profile}.ghostty" "$config_dir/profile.ghostty"
echo "Active Ghostty profile: $profile"
echo "Reload Ghostty to apply the change."

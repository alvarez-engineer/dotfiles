#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage: scripts/install.sh [--copy] [--profile macos|linux|minimal] [--dry-run]

Installs ./config into ${XDG_CONFIG_HOME:-$HOME/.config}/ghostty.

Default behavior:
  - symlink config directory
  - auto-detect platform profile
  - backup existing Ghostty config directory before replacing it

Options:
  --copy             copy files instead of symlinking
  --profile NAME     force profile: macos, linux, or minimal
  --dry-run          print actions without changing files
  -h, --help         show this help
EOF
}

mode="symlink"
profile=""
dry_run="false"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --copy)
      mode="copy"
      shift
      ;;
    --profile)
      profile="${2:-}"
      shift 2
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

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd -- "$script_dir/.." && pwd)"
source_config="$repo_root/config"
target_config="${XDG_CONFIG_HOME:-$HOME/.config}/ghostty"

if [[ -z "$profile" ]]; then
  case "$(uname -s)" in
    Darwin) profile="macos" ;;
    Linux) profile="linux" ;;
    *) profile="minimal" ;;
  esac
fi

case "$profile" in
  macos|linux|minimal) ;;
  *)
    echo "Invalid profile: $profile" >&2
    echo "Expected one of: macos, linux, minimal" >&2
    exit 1
    ;;
esac

run() {
  if [[ "$dry_run" == "true" ]]; then
    printf 'DRY RUN: %s\n' "$*"
  else
    "$@"
  fi
}

echo "Source: $source_config"
echo "Target: $target_config"
echo "Mode:   $mode"
echo "Profile: $profile"

if [[ -e "$target_config" || -L "$target_config" ]]; then
  timestamp="$(date +%Y%m%d-%H%M%S)"
  backup_path="${target_config}.backup-${timestamp}"
  echo "Backing up existing config to $backup_path"
  run mv "$target_config" "$backup_path"
fi

run mkdir -p "$(dirname "$target_config")"

if [[ "$mode" == "copy" ]]; then
  run cp -R "$source_config" "$target_config"
else
  run ln -s "$source_config" "$target_config"
fi

profile_src="$source_config/profiles/${profile}.ghostty"
profile_target="$target_config/profile.ghostty"

if [[ "$mode" == "copy" ]]; then
  run cp "$profile_src" "$profile_target"
else
  run ln -sf "profiles/${profile}.ghostty" "$profile_target"
fi

cat <<EOF

Installed Ghostty config.

Next:
  1. Run: ghostty +validate-config --config-file "$target_config/config.ghostty"
  2. Reload Ghostty: macOS cmd+shift+, or Linux ctrl+shift+,
  3. For local overrides: cp "$target_config/local.example.ghostty" "$target_config/local.ghostty"
EOF

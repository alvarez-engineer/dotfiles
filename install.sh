#!/usr/bin/env bash
set -euo pipefail

# Top-level dotfiles installer. Runs each module's install.sh, which symlinks
# that tool's config into place (backing up anything already there).

usage() {
  cat <<'EOF'
Usage: ./install.sh [--copy] [--dry-run] [MODULE ...]

Installs dotfiles by symlinking each module's config into place. Existing files
are backed up with a timestamp before being replaced.

Modules (default: all): ghostty shell git tmux nvim cli

Options:
  --bootstrap  install the tool binaries first (scripts/bootstrap.sh; needs sudo)
  --copy       copy files instead of symlinking
  --dry-run    print actions without changing the filesystem
  -h, --help   show this help

Examples:
  ./install.sh                 # symlink all configs
  ./install.sh --bootstrap     # install tools, then symlink all configs
  ./install.sh --dry-run       # preview all actions
  ./install.sh shell git       # install only the shell and git modules
  ./install.sh --copy nvim     # copy the nvim config instead of symlinking
EOF
}

ALL_MODULES=(ghostty shell git tmux nvim cli)

mode="symlink"
dry_run="false"
bootstrap="false"
selected=()

while [[ $# -gt 0 ]]; do
  case "$1" in
    --copy)      mode="copy"; shift ;;
    --dry-run)   dry_run="true"; shift ;;
    --bootstrap) bootstrap="true"; shift ;;
    -h|--help)   usage; exit 0 ;;
    -*)          echo "Unknown option: $1" >&2; usage; exit 1 ;;
    *)           selected+=("$1"); shift ;;
  esac
done

repo_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

# --bootstrap: install the tool binaries first (needs sudo on Linux).
if [[ "$bootstrap" == "true" ]]; then
  bootstrap_args=()
  [[ "$dry_run" == "true" ]] && bootstrap_args+=("--dry-run")
  bash "$repo_root/scripts/bootstrap.sh" "${bootstrap_args[@]}"
fi

if [[ ${#selected[@]} -eq 0 ]]; then
  selected=("${ALL_MODULES[@]}")
fi

# Validate requested modules up front.
for m in "${selected[@]}"; do
  if [[ ! -x "$repo_root/$m/install.sh" && ! -f "$repo_root/$m/install.sh" ]]; then
    echo "Unknown or non-installable module: $m" >&2
    echo "Available: ${ALL_MODULES[*]}" >&2
    exit 1
  fi
done

export DOTFILES_MODE="$mode"
export DOTFILES_DRY_RUN="$dry_run"

case "$(uname -s)" in
  Darwin) platform="macos" ;;
  Linux)  platform="linux" ;;
  *)      platform="other" ;;
esac
export DOTFILES_PLATFORM="$platform"

echo "Dotfiles installer"
echo "  repo:     $repo_root"
echo "  platform: $platform"
echo "  mode:     $mode"
echo "  dry-run:  $dry_run"
echo "  modules:  ${selected[*]}"

for m in "${selected[@]}"; do
  printf '\n### %s ###\n' "$m"
  bash "$repo_root/$m/install.sh"
done

cat <<EOF

Done. Notes:
  - Backups of replaced files use the suffix .backup-<timestamp>.
  - Some tools need their binary installed separately; see docs/BOOTSTRAP.md.
  - Restart your shell (or 'source ~/.bashrc') to pick up shell changes.
EOF

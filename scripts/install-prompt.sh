#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE_EOF'
Usage: scripts/install-prompt.sh [--shell bash|zsh] [--dry-run]

Installs a shell prompt source block that shows:
  - current working directory
  - git branch
  - git dirty/staged/untracked/ahead/behind status
  - Python virtual environment or Conda environment
  - previous command exit status

This script edits ~/.bashrc or ~/.zshrc. It creates a timestamped backup first.
USAGE_EOF
}

shell_name=""
dry_run="false"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --shell)
      shell_name="${2:-}"
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

if [[ -z "$shell_name" ]]; then
  case "${SHELL##*/}" in
    zsh) shell_name="zsh" ;;
    bash) shell_name="bash" ;;
    *)
      echo "Could not infer shell from SHELL=${SHELL:-unset}. Use --shell bash or --shell zsh." >&2
      exit 1
      ;;
  esac
fi

case "$shell_name" in
  bash)
    rc_file="$HOME/.bashrc"
    prompt_file='${XDG_CONFIG_HOME:-$HOME/.config}/ghostty/shell/bash_prompt.sh'
    source_line='source "${XDG_CONFIG_HOME:-$HOME/.config}/ghostty/shell/bash_prompt.sh"'
    ;;
  zsh)
    rc_file="$HOME/.zshrc"
    prompt_file='${XDG_CONFIG_HOME:-$HOME/.config}/ghostty/shell/zsh_prompt.zsh'
    source_line='source "${XDG_CONFIG_HOME:-$HOME/.config}/ghostty/shell/zsh_prompt.zsh"'
    ;;
  *)
    echo "Unsupported shell: $shell_name" >&2
    echo "Expected bash or zsh." >&2
    exit 1
    ;;
esac

block_start="# >>> ghostty muted coding prompt >>>"
block_end="# <<< ghostty muted coding prompt <<<"
block="${block_start}
if [ -r \"${prompt_file}\" ]; then
  ${source_line}
fi
${block_end}"

run() {
  if [[ "$dry_run" == "true" ]]; then
    printf 'DRY RUN: %s\n' "$*"
  else
    "$@"
  fi
}

if [[ ! -f "$rc_file" ]]; then
  echo "Creating $rc_file"
  run touch "$rc_file"
fi

if grep -Fq "$block_start" "$rc_file"; then
  echo "Prompt block already exists in $rc_file"
  exit 0
fi

backup="${rc_file}.backup-$(date +%Y%m%d-%H%M%S)"
echo "Backing up $rc_file to $backup"
run cp "$rc_file" "$backup"

if [[ "$dry_run" == "true" ]]; then
  printf 'DRY RUN: append prompt block to %s\n' "$rc_file"
else
  printf '\n%s\n' "$block" >> "$rc_file"
fi

echo "Installed prompt block for $shell_name. Restart your shell or run: source $rc_file"

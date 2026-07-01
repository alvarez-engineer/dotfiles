#!/usr/bin/env bash
set -euo pipefail

config_dir="${XDG_CONFIG_HOME:-$HOME/.config}/ghostty"
config_file="$config_dir/config.ghostty"

printf 'Ghostty doctor\n'
printf '==============\n\n'

printf 'OS: %s\n' "$(uname -s)"
printf 'Shell: %s\n' "${SHELL:-unknown}"
printf 'XDG_CONFIG_HOME: %s\n' "${XDG_CONFIG_HOME:-not set}"
printf 'Expected config dir: %s\n' "$config_dir"
printf 'Expected config file: %s\n\n' "$config_file"

if command -v ghostty >/dev/null 2>&1; then
  printf 'Ghostty CLI: %s\n' "$(command -v ghostty)"
  ghostty +version || true
else
  printf 'Ghostty CLI: not found on PATH\n'
fi

printf '\nConfig files:\n'
if [[ -e "$config_dir" ]]; then
  find "$config_dir" -maxdepth 4 \( -type f -o -type l \) | sort
else
  printf 'Missing: %s\n' "$config_dir"
fi

printf '\nPrompt hook check:\n'
if [[ -f "$HOME/.zshrc" ]] && grep -Fq 'ghostty muted coding prompt' "$HOME/.zshrc"; then
  printf 'Found managed prompt block in ~/.zshrc\n'
elif [[ -f "$HOME/.bashrc" ]] && grep -Fq 'ghostty muted coding prompt' "$HOME/.bashrc"; then
  printf 'Found managed prompt block in ~/.bashrc\n'
else
  printf 'No managed prompt block found. Run ./scripts/install-prompt.sh if desired.\n'
fi

printf '\nValidation:\n'
if command -v ghostty >/dev/null 2>&1 && [[ -f "$config_file" ]]; then
  ghostty +validate-config --config-file "$config_file"
else
  printf 'Skipped. Ghostty CLI or config file missing.\n'
fi

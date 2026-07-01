#!/usr/bin/env bash
set -euo pipefail
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)/lib/common.sh"

src="$DOTFILES_ROOT/tmux"

info "tmux -> ~/.config/tmux/tmux.conf"

# tmux >= 3.1 reads $XDG_CONFIG_HOME/tmux/tmux.conf natively.
link_file "$src/tmux.conf" "$XDG_CONFIG_HOME/tmux/tmux.conf"

if have tmux; then
  ver="$(tmux -V 2>/dev/null || echo unknown)"
  log "tmux present: $ver (reload inside tmux with prefix + r)"
else
  log "tmux not installed; config is ready for when you install it"
fi

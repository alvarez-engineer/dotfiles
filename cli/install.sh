#!/usr/bin/env bash
set -euo pipefail
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)/lib/common.sh"

src="$DOTFILES_ROOT/cli"

info "cli tools -> bat, ripgrep"

# bat: config + the muted-ink theme (shared with delta via syntax-theme).
link_file "$src/bat/config" "$XDG_CONFIG_HOME/bat/config"
link_file "$src/bat/themes/muted-ink.tmTheme" "$XDG_CONFIG_HOME/bat/themes/muted-ink.tmTheme"

# ripgrep: config picked up through RIPGREP_CONFIG_PATH (set in shell/exports.sh).
link_file "$src/ripgrep/ripgreprc" "$XDG_CONFIG_HOME/ripgrep/ripgreprc"

# fzf colors/keybindings are configured via env in shell/exports.sh — nothing to link.

# bat needs a cache rebuild to see a new custom theme.
if have bat; then
  log "rebuilding bat theme cache"
  run bat cache --build >/dev/null 2>&1 || warn "bat cache --build failed; run it manually"
elif have batcat; then
  log "rebuilding bat (batcat) theme cache"
  run batcat cache --build >/dev/null 2>&1 || warn "batcat cache --build failed; run it manually"
else
  log "bat not installed; theme will apply once it is"
fi

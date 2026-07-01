#!/usr/bin/env bash
set -euo pipefail
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)/lib/common.sh"

src="$DOTFILES_ROOT/opencode"
dest="$XDG_CONFIG_HOME/opencode"

info "opencode -> $dest"

# Config + TUI theme selection + the custom muted-ink theme. We link individual
# files so opencode's own state (auth.json with API keys, etc.) is never touched.
link_file "$src/opencode.json" "$dest/opencode.json"
link_file "$src/tui.json"      "$dest/tui.json"
link_file "$src/themes/muted-ink.json" "$dest/themes/muted-ink.json"

if have opencode; then
  log "opencode present: $(opencode --version 2>/dev/null || echo unknown)"
  log "authenticate once with: opencode auth login   (keys are stored outside this repo)"
else
  log "opencode not installed; config is ready for when you install it"
fi

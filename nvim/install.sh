#!/usr/bin/env bash
set -euo pipefail
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)/lib/common.sh"

src="$DOTFILES_ROOT/nvim"

info "nvim -> ~/.config/nvim"

# Symlink the whole config dir. lazy.nvim state lives in ~/.local/share/nvim,
# so nothing is written back into the repo except lazy-lock.json (tracked).
link_file "$src" "$XDG_CONFIG_HOME/nvim"

if have nvim; then
  log "neovim present: $(nvim --version | head -1)"
  log "run 'nvim' once to let lazy.nvim install plugins + treesitter parsers"
else
  log "neovim not installed; config is ready for when you install it"
fi

#!/usr/bin/env bash
set -euo pipefail
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)/lib/common.sh"

src="$DOTFILES_ROOT/git"

info "git -> ~/.gitconfig, ~/.config/git/ignore"

link_file "$src/gitconfig" "$HOME/.gitconfig"
link_file "$src/gitignore_global" "$XDG_CONFIG_HOME/git/ignore"

# Seed ~/.gitconfig.local with an identity template if it does not exist yet.
local_cfg="$HOME/.gitconfig.local"
if [[ ! -e "$local_cfg" ]]; then
  if [[ "$DOTFILES_DRY_RUN" == "true" ]]; then
    printf 'DRY RUN: create %s identity template\n' "$local_cfg"
  else
    cat >"$local_cfg" <<'EOF'
# Machine-local git settings (untracked). Fill in your identity.
[user]
	name = Your Name
	email = you@example.com
# [user]
#	signingkey = <key-id>
# [commit]
#	gpgsign = true
EOF
    log "created identity template: $local_cfg (edit name/email)"
  fi
else
  log "keeping existing $local_cfg"
fi

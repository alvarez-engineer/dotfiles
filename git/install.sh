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
    # The name/email stay COMMENTED OUT on purpose. A live placeholder identity
    # would not fail — git would happily author every commit as
    # "Your Name <you@example.com>". Leaving them commented makes git refuse to
    # commit until a real identity is set, which is the safe default.
    cat >"$local_cfg" <<'EOF'
# Machine-local git settings (untracked). Uncomment and fill in your identity;
# until you do, git will refuse to commit rather than use a placeholder name.
[user]
#	name = Your Name
#	email = you@example.com
#	signingkey = <key-id>
# [commit]
#	gpgsign = true
EOF
    log "created identity template: $local_cfg"
    log "  -> set your name/email there; git will not commit until you do"
  fi
else
  log "keeping existing $local_cfg"
fi

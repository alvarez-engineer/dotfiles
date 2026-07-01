#!/usr/bin/env bash
set -euo pipefail
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)/lib/common.sh"

src="$DOTFILES_ROOT/shell"

info "shell -> ~/.bashrc, ~/.zshrc, starship"

link_file "$src/bashrc" "$HOME/.bashrc"
link_file "$src/zshrc"  "$HOME/.zshrc"
link_file "$src/starship.toml" "$XDG_CONFIG_HOME/starship.toml"

cat <<'EOF'
  note: managed rc files source your distro defaults (/etc/bashrc, ~/.bashrc.d)
        and load aliases/exports/functions from the repo. Put private, machine-
        specific settings in ~/.bashrc.local or ~/.zshrc.local (untracked).
EOF

#!/usr/bin/env bash
set -euo pipefail
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)/lib/common.sh"

# Ghostty config lives at $XDG_CONFIG_HOME/ghostty on both Linux and macOS.
src="$DOTFILES_ROOT/ghostty"
dest="$XDG_CONFIG_HOME/ghostty"

info "ghostty -> $dest"

# Symlink the tracked pieces individually so generated files (profile.ghostty,
# local.ghostty) can live in $dest as real files without polluting the repo.
link_file "$src/config.ghostty" "$dest/config.ghostty"
link_file "$src/profiles"       "$dest/profiles"
link_file "$src/themes"         "$dest/themes"
link_file "$src/local.example.ghostty" "$dest/local.example.ghostty"

# Pick the platform overlay; config.ghostty loads it via `config-file = ?profile.ghostty`.
case "${DOTFILES_PLATFORM:-$(uname -s)}" in
  macos|Darwin) profile="macos" ;;
  linux|Linux)  profile="linux" ;;
  *)            profile="minimal" ;;
esac

profile_link="$dest/profile.ghostty"
if [[ "$DOTFILES_MODE" == "copy" ]]; then
  run cp "$src/profiles/${profile}.ghostty" "$profile_link"
else
  # Relative symlink so it resolves inside $dest regardless of repo location.
  run ln -sf "profiles/${profile}.ghostty" "$profile_link"
fi
log "profile: $profile"

if have ghostty; then
  log "validating config"
  run ghostty +validate-config --config-file "$dest/config.ghostty" || warn "ghostty validation reported issues"
else
  log "ghostty CLI not found; skipping validation (run 'make validate' later)"
fi

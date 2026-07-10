#!/usr/bin/env bash
set -euo pipefail
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)/lib/common.sh"

src="$DOTFILES_ROOT/claude"
claude_dir="$HOME/.claude"

info "claude -> $claude_dir"

# The status line is pure, portable tooling: symlink it like any other config.
link_file "$src/statusline.sh" "$claude_dir/statusline.sh"

# settings.json is SEEDED, never symlinked or overwritten. Two reasons:
#
#   - Claude Code has no user-level `.local` override layer. `settings.local.json`
#     is project-scoped, so the trick every other module here uses -- ship the
#     managed file, let an untracked local file load last and win -- is not
#     available. Whatever lands in ~/.claude/settings.json is the whole story.
#
#   - That one file mixes portable preferences (theme, model, effortLevel) with
#     machine and account state (enabledPlugins) and a security posture
#     (skipDangerousModePermissionPrompt). Symlinking it would drag a permission
#     -prompt bypass into version control, and into any future public push.
#
# So the repo ships defaults for the portable half only. This is the same
# contract as the notes module's seed_file: your file, our starting point.
settings_dest="$claude_dir/settings.json"

if [[ -e "$settings_dest" ]]; then
  log "keep: $settings_dest (already exists; never overwritten)"
  if ! grep -q '"dark-ansi"' "$settings_dest" 2>/dev/null; then
    log "hint: set \"theme\": \"dark-ansi\" to inherit muted-ink from the terminal"
  fi
  if ! grep -q '"statusLine"' "$settings_dest" 2>/dev/null; then
    log "hint: add the status line -- see $src/settings.json"
  fi
else
  log "seed: $settings_dest"
  if [[ "$DOTFILES_DRY_RUN" == "true" ]]; then
    printf 'DRY RUN: install %s/settings.json -> %s (with __HOME__ expanded)\n' "$src" "$settings_dest"
  else
    mkdir -p "$claude_dir"
    # statusLine.command is passed to a shell by Claude Code, but a leading `~`
    # is not reliably expanded there. Bake the absolute path in at install time;
    # this is a copy, not a link, so rewriting it is safe.
    sed "s|__HOME__|$HOME|g" "$src/settings.json" >"$settings_dest"
  fi
fi

have claude || log "claude not installed; see https://claude.com/claude-code"

cat <<EOF
  theme:      dark-ansi (renders from the terminal's ANSI palette = muted-ink)
  statusline: $claude_dir/statusline.sh
  note:       settings.json holds machine state (enabledPlugins, permissions);
              it is seeded once and never overwritten. Edit it in place.
EOF

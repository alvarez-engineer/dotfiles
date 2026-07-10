#!/usr/bin/env bash
set -euo pipefail
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)/lib/common.sh"

src="$DOTFILES_ROOT/vscode"
theme_src="$src/extensions/muted-ink"
bin_dir="$HOME/.local/bin"
ext_id="dotfiles.muted-ink"
ext_ver="1.0.0"

# VS Code keeps user config and extensions in two *separate* roots, and a flatpak
# install relocates both. Unlike every other module here, there is no single XDG
# path to link into -- resolve the pair up front. scripts/doctor.sh and
# scripts/uninstall.sh mirror this block.
if [[ -d "$HOME/.var/app/com.visualstudio.code" ]]; then
  flavor="flatpak"
  user_dir="$HOME/.var/app/com.visualstudio.code/config/Code/User"
  ext_dir="$HOME/.var/app/com.visualstudio.code/data/vscode/extensions"
elif [[ "${DOTFILES_PLATFORM:-}" == "macos" ]]; then
  flavor="native (macOS)"
  user_dir="$HOME/Library/Application Support/Code/User"
  ext_dir="$HOME/.vscode/extensions"
else
  flavor="native"
  user_dir="$XDG_CONFIG_HOME/Code/User"
  ext_dir="$HOME/.vscode/extensions"
fi

ext_dest="$ext_dir/${ext_id}-${ext_ver}"

info "vscode ($flavor) -> $user_dir"

link_file "$src/settings.json" "$user_dir/settings.json"

# The `code` shim. See vscode/bin/code for why it exists and why it has to defer
# to a native install when there is one. Linked before the theme, because the
# theme install below invokes it.
link_file "$src/bin/code" "$bin_dir/code"

# The integrated terminal's shell: hops out of the flatpak sandbox (which has no
# tmux and no claude) and attaches one tmux session per project.
link_file "$src/bin/dev-shell" "$bin_dir/dev-shell"

# --- Theme ------------------------------------------------------------------
#
# Dropping an extension folder into the extensions directory does NOT work on a
# current VS Code. It scans the folder, then records it in `.obsolete` and
# ignores it, because `extensions.json` -- not the directory listing -- is the
# authoritative list of installed user extensions. On 1.127 the log reads:
#
#     [info] Marked extension as removed dotfiles.muted-ink-1.0.0
#
# The only supported way into `extensions.json` is `--install-extension` with a
# packaged .vsix. So: package and install once, then replace the copy VS Code
# made with a symlink back into the repo. Once the id is registered the folder is
# no longer orphaned, and a symlink there survives -- which restores this repo's
# usual "edit the file, the live config changes" behavior for the theme.

theme_registered() {
  [[ -f "$ext_dir/extensions.json" ]] &&
    grep -q "\"$ext_id\"" "$ext_dir/extensions.json"
}

# A local .vsix is just a zip whose entries live under extension/. The
# [Content_Types].xml and extension.vsixmanifest that Marketplace packages carry
# are not required for --install-extension (verified on 1.127).
build_vsix() {
  local work="$1" out="$2"
  mkdir -p "$work/extension"
  cp -R "$theme_src/package.json" "$theme_src/themes" "$work/extension/"
  if have zip; then
    (cd "$work" && zip -q -r "$out" extension)
  else
    (cd "$work" && python3 -c '
import os, sys, zipfile
with zipfile.ZipFile(sys.argv[1], "w", zipfile.ZIP_DEFLATED) as z:
    for root, _, files in os.walk("extension"):
        for f in files:
            z.write(os.path.join(root, f))
' "$out")
  fi
}

install_theme() {
  # Build under XDG_CACHE_HOME rather than /tmp: a flatpak VS Code gets a private
  # /tmp and cannot read a host /tmp path, so a .vsix staged there is invisible
  # to it. (vscode/bin/code passes --filesystem=/tmp, but do not lean on that.)
  local cache="${XDG_CACHE_HOME:-$HOME/.cache}"
  local work vsix rc=0
  mkdir -p "$cache"
  work="$(mktemp -d "$cache/muted-ink-vsix.XXXXXX")"
  vsix="$work/muted-ink.vsix"

  # No RETURN trap: `trap ... RETURN` set inside a function is global, and would
  # then fire on every later function return too. Clean up on both paths instead.
  build_vsix "$work" "$vsix" || rc=$?
  if ((rc == 0)); then
    "$src/bin/code" --install-extension "$vsix" --force >/dev/null 2>&1 || rc=$?
  fi
  rm -rf "$work"
  return "$rc"
}

if [[ "$DOTFILES_DRY_RUN" == "true" ]]; then
  log "DRY RUN: package $theme_src and install it with code --install-extension"
  log "DRY RUN: link: $ext_dest -> $theme_src"
elif theme_registered && [[ -L "$ext_dest" ]]; then
  log "ok: theme already registered and linked"
else
  if ! have zip && ! have python3; then
    warn "neither zip nor python3 found; cannot package the theme -- skipping"
  elif ! theme_registered && ! install_theme; then
    warn "could not register the theme with VS Code (is it installed?) -- skipping"
  else
    # Deliberately not link_file: it would rename VS Code's freshly installed
    # copy to <dir>.backup-<ts> *inside the extensions directory*, where VS Code
    # would scan it as a second, orphaned extension. This directory is ours -- we
    # just created it -- so replace it outright.
    if [[ "$DOTFILES_MODE" == "copy" ]]; then
      log "keep: $ext_dest (copy installed by VS Code)"
    else
      run rm -rf "$ext_dest"
      log "link: $ext_dest -> $theme_src"
      run ln -s "$theme_src" "$ext_dest"
    fi
  fi
fi

log "theme: Muted Ink (already selected in settings.json)"

if [[ "$flavor" == "flatpak" ]]; then
  log "launcher: flatpak run com.visualstudio.code (wrapped by ~/.local/bin/code)"
fi

# A running VS Code does not notice a newly installed extension directory.
log "restart VS Code (or: Developer > Reload Window) to load the theme"

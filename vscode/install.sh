#!/usr/bin/env bash
set -euo pipefail
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)/lib/common.sh"

src="$DOTFILES_ROOT/vscode"
bin_dir="$HOME/.local/bin"

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

info "vscode ($flavor) -> $user_dir"

link_file "$src/settings.json" "$user_dir/settings.json"

# The `code` shim. See vscode/bin/code for why it exists and why it has to defer
# to a native install when there is one. Linked before the extensions, because
# installing them below invokes it.
link_file "$src/bin/code" "$bin_dir/code"

# The integrated terminal's launcher: hops out of the flatpak sandbox (which has
# no tmux and no claude) and attaches a tmux session. Used by the workbench
# extension's layout and as the default terminal profile.
link_file "$src/bin/dev-shell" "$bin_dir/dev-shell"

# --- Local extensions -------------------------------------------------------
#
# Dropping an extension folder into the extensions directory does NOT work on a
# current VS Code. It scans the folder, records it in `.obsolete`, and ignores
# it, because `extensions.json` -- not the directory listing -- is the
# authoritative list of installed user extensions. On 1.127 the log reads:
#
#     [info] Marked extension as removed dotfiles.muted-ink-1.0.0
#
# The only supported way into `extensions.json` is `--install-extension` with a
# packaged .vsix. So: package and install once, then replace the copy VS Code
# made with a symlink back into the repo. Once the id is registered the folder is
# no longer orphaned, and the symlink survives -- which restores this repo's
# usual "edit the file, the live config changes" behavior. This holds for the
# coded workbench extension exactly as for the theme.

ext_registered() { # $1 = extension id
  [[ -f "$ext_dir/extensions.json" ]] && grep -q "\"$1\"" "$ext_dir/extensions.json"
}

# A local .vsix is just a zip whose entries live under extension/. The
# [Content_Types].xml and extension.vsixmanifest that Marketplace packages carry
# are not required for --install-extension (verified on 1.127). Copy the whole
# source dir, so this works for a theme (package.json + themes/) and a coded
# extension (package.json + extension.js) alike.
register_extension() { # $1 = source dir
  local esrc="$1" cache work vsix rc=0
  cache="${XDG_CACHE_HOME:-$HOME/.cache}"
  mkdir -p "$cache"
  # Build under XDG_CACHE_HOME, never /tmp: a flatpak VS Code has a private /tmp
  # and cannot read a host /tmp path, so a .vsix staged there is invisible to it.
  work="$(mktemp -d "$cache/dotfiles-vsix.XXXXXX")"
  vsix="$work/ext.vsix"
  mkdir -p "$work/extension"
  cp -R "$esrc/." "$work/extension/"
  if have zip; then
    (cd "$work" && zip -q -r "$vsix" extension) || rc=$?
  else
    (cd "$work" && python3 -c '
import os, sys, zipfile
with zipfile.ZipFile(sys.argv[1], "w", zipfile.ZIP_DEFLATED) as z:
    for root, _, files in os.walk("extension"):
        for f in files:
            z.write(os.path.join(root, f))
' "$vsix") || rc=$?
  fi
  ((rc == 0)) && { "$src/bin/code" --install-extension "$vsix" --force >/dev/null 2>&1 || rc=$?; }
  rm -rf "$work"
  return "$rc"
}

# install_local_extension ID VERSION SRC_DIR LABEL
install_local_extension() {
  local id="$1" ver="$2" esrc="$3" label="$4"
  local dest="$ext_dir/${id}-${ver}"

  if [[ "$DOTFILES_DRY_RUN" == "true" ]]; then
    log "DRY RUN: package + install $label, then link $dest -> $esrc"
    return 0
  fi
  if ext_registered "$id" && [[ -L "$dest" ]]; then
    log "ok: $label already registered and linked"
    return 0
  fi
  if ! have zip && ! have python3; then
    warn "neither zip nor python3 found; cannot package $label -- skipping"
    return 0
  fi
  if ! ext_registered "$id" && ! register_extension "$esrc"; then
    warn "could not register $label with VS Code (is it installed?) -- skipping"
    return 0
  fi
  # Deliberately not link_file: it would rename VS Code's freshly installed copy
  # to <dir>.backup-<ts> *inside the extensions directory*, where VS Code would
  # scan it as a second, orphaned extension. This directory is ours -- replace it.
  if [[ "$DOTFILES_MODE" == "copy" ]]; then
    log "keep: $dest (copy installed by VS Code)"
  else
    run rm -rf "$dest"
    log "link: $dest -> $esrc"
    run ln -s "$esrc" "$dest"
  fi
}

install_local_extension "dotfiles.muted-ink" "1.0.0" "$src/extensions/muted-ink"        "Muted Ink theme"
install_local_extension "dotfiles.workbench" "1.0.0" "$src/extensions/dotfiles-workbench" "Dotfiles Workbench"

log "theme: Muted Ink (already selected in settings.json)"
log "layout: Dotfiles Workbench builds it on folder open (Ctrl+Alt+D to rebuild)"

if [[ "$flavor" == "flatpak" ]]; then
  log "launcher: flatpak run com.visualstudio.code (wrapped by ~/.local/bin/code)"
fi

# A running VS Code does not notice newly installed extensions.
log "restart VS Code (or: Developer > Reload Window) to load them"

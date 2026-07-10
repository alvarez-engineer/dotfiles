#!/usr/bin/env bash
set -euo pipefail
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)/lib/common.sh"

# Installs the tool BINARIES the dotfiles configure. Needs sudo on Linux.
# Kept separate from install.sh (which only symlinks configs and needs no root).

usage() {
  cat <<'EOF'
Usage: scripts/bootstrap.sh [--dev] [--dry-run] [-h]

Installs the command-line tools these dotfiles configure, using the platform
package manager (dnf / apt / brew). Starship is installed via its official
script where it isn't packaged.

Options:
  --dev        also install the dev-gate linters (shellcheck, luacheck)
  --dry-run    print the commands without running them
  -h, --help   show this help

Notes:
  - On Linux this uses sudo for the package manager; you'll be prompted.
  - Ghostty is not auto-installed on Linux; see https://ghostty.org/download
EOF
}

dev="false"
while [[ $# -gt 0 ]]; do
  case "$1" in
    --dev) dev="true"; shift ;;
    --dry-run) DOTFILES_DRY_RUN="true"; shift ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown option: $1" >&2; usage; exit 1 ;;
  esac
done

# sudo only when needed and available.
SUDO=""
if [[ "${EUID:-$(id -u)}" -ne 0 ]] && have sudo; then SUDO="sudo"; fi
sudo_run() { if [[ -n "$SUDO" ]]; then run "$SUDO" "$@"; else run "$@"; fi; }

detect_os() {
  case "$(uname -s)" in
    Darwin) echo macos ;;
    Linux)
      # shellcheck disable=SC1091
      [[ -r /etc/os-release ]] && . /etc/os-release
      case " ${ID:-} ${ID_LIKE:-} " in
        *fedora*|*rhel*|*centos*) echo fedora ;;
        *debian*|*ubuntu*)        echo debian ;;
        *)                        echo linux-unknown ;;
      esac ;;
    *) echo unknown ;;
  esac
}

# We install JetBrainsMono *Nerd Font* rather than plain JetBrains Mono. The Nerd
# Font is a superset -- identical letterforms plus the Powerline/branch/icon glyphs
# in the Private Use Area -- so it costs nothing for normal text and makes the
# claude status line's opt-in glyph mode (DOTFILES_STATUSLINE_GLYPHS=nerd) render.
#
# It matters for VS Code, not Ghostty. VS Code resolves `terminal.integrated.fontFamily`
# through fontconfig, and `fc-match` answers *Noto Sans* -- proportional -- when the
# family is missing, quietly un-monospacing the terminal and tofu-ing every glyph.
# Ghostty needs nothing: it embeds JetBrains Mono and has a built-in Nerd Font
# symbol fallback, so its glyphs render whether or not this install runs.
#
# The "Mono" variant ("JetBrainsMono Nerd Font Mono") forces every icon into a
# single cell, so columns never shift -- the right choice for a terminal/editor.
#
# Not fatal: vscode/settings.json falls back through plain JetBrains Mono then
# Source Code Pro, and Ghostty never needed it. Warn and carry on, as with
# eza/git-delta below.
font_warn="JetBrainsMono Nerd Font not installed; ghostty renders glyphs anyway, but VS Code will tofu them"

# Pinned Nerd Fonts release. The per-font zip carries all weights/variants; we keep
# only the four the editor actually uses.
nf_version="3.4.0"
nf_url="https://github.com/ryanoasis/nerd-fonts/releases/download/v${nf_version}/JetBrainsMono.zip"
# The "Mono" variant's core weights (family: "JetBrainsMono Nerd Font Mono").
nf_faces=(
  JetBrainsMonoNerdFontMono-Regular.ttf
  JetBrainsMonoNerdFontMono-Bold.ttf
  JetBrainsMonoNerdFontMono-Italic.ttf
  JetBrainsMonoNerdFontMono-BoldItalic.ttf
)

# Where a font can be dropped without root and still be found.
user_font_dir() {
  if [[ "$(uname -s)" == "Darwin" ]]; then
    printf '%s\n' "$HOME/Library/Fonts"
  else
    printf '%s\n' "${XDG_DATA_HOME:-$HOME/.local/share}/fonts"
  fi
}

# True when fontconfig resolves the family to itself. A missing font does not
# error here -- fc-match always answers *something* -- so compare the answer.
font_present() {
  have fc-match || return 1
  fc-match "JetBrainsMono Nerd Font Mono" family 2>/dev/null | grep -qi 'JetBrainsMono Nerd Font'
}

# Fetch the release and unpack the four faces into the user font directory. No root.
install_font_user() {
  local dir tmp
  dir="$(user_font_dir)/JetBrainsMonoNerd"
  have curl  || { warn "curl not found; cannot fetch JetBrainsMono Nerd Font"; return 1; }
  have unzip || { warn "unzip not found; cannot unpack JetBrainsMono Nerd Font"; return 1; }

  log "fetching JetBrainsMono Nerd Font $nf_version into $dir (no root; ~124M download)"
  tmp="$(mktemp -d)"
  if ! curl -sSL --fail --max-time 300 -o "$tmp/nf.zip" "$nf_url"; then
    rm -rf "$tmp"; warn "download failed: $nf_url"; return 1
  fi
  # Extract only the faces we keep; the full archive is ~96 TTFs.
  if ! unzip -qo "$tmp/nf.zip" "${nf_faces[@]}" -d "$tmp/x"; then
    rm -rf "$tmp"; warn "could not unpack the JetBrainsMono Nerd Font archive"; return 1
  fi
  mkdir -p "$dir"
  cp "$tmp/x"/*.ttf "$dir/"
  rm -rf "$tmp"

  # macOS has no fc-cache; CoreText picks up ~/Library/Fonts on its own.
  if have fc-cache; then fc-cache -f "$dir" >/dev/null 2>&1 || true; fi
  log "installed JetBrainsMono Nerd Font to $dir"
  return 0
}

# install_nerd_font [PACKAGED INSTALL COMMAND...]
#
# Try a packaged install first when one is given (only Homebrew reliably packages
# the Nerd variant), and fall back to the rootless user-local fetch otherwise --
# no sudo, no TTY to type a password into, package not in the repo. Trust the
# packaged command's exit status rather than re-checking with font_present():
# macOS has no fontconfig, so font_present() is always false there and would send a
# successful `brew install --cask` down the fallback path.
install_nerd_font() {
  if font_present; then
    log "JetBrainsMono Nerd Font already installed"
    return 0
  fi

  if [[ "$DOTFILES_DRY_RUN" == "true" ]]; then
    [[ $# -gt 0 ]] && printf 'DRY RUN: %s\n' "$*"
    printf 'DRY RUN: on failure, fetch %s into %s\n' "$nf_url" "$(user_font_dir)/JetBrainsMonoNerd"
    return 0
  fi

  if [[ $# -gt 0 ]] && "$@"; then
    log "JetBrainsMono Nerd Font installed via the system package manager"
    return 0
  fi

  [[ $# -gt 0 ]] && warn "packaged install unavailable or failed; falling back to a user-local install"
  install_font_user || warn "$font_warn"
}

install_starship() {
  if have starship; then log "starship already installed"; return 0; fi
  log "installing starship (official script)"
  if [[ "$DOTFILES_DRY_RUN" == "true" ]]; then
    printf 'DRY RUN: curl -sS https://starship.rs/install.sh | sh -s -- -y\n'
  else
    curl -sS https://starship.rs/install.sh | sh -s -- -y
  fi
}

install_opencode() {
  if have opencode; then log "opencode already installed"; return 0; fi
  log "installing opencode (official script)"
  if [[ "$DOTFILES_DRY_RUN" == "true" ]]; then
    printf 'DRY RUN: curl -fsSL https://opencode.ai/install | bash\n'
  else
    curl -fsSL https://opencode.ai/install | bash
  fi
}

bootstrap_fedora() {
  info "Fedora: installing tools via dnf"
  sudo_run dnf install -y neovim tmux fzf ripgrep bat eza git-delta zsh fd-find git
  # The Nerd variant is not reliably in Fedora's repos; go straight to the
  # rootless user-local fetch.
  install_nerd_font
  install_starship
  install_opencode
  if [[ "$dev" == "true" ]]; then
    info "dev linters"
    sudo_run dnf install -y ShellCheck luarocks
    sudo_run luarocks install luacheck
  fi
}

bootstrap_debian() {
  info "Debian/Ubuntu: installing tools via apt"
  sudo_run apt-get update
  sudo_run apt-get install -y neovim tmux fzf ripgrep bat fd-find zsh git
  # eza and git-delta are not in older apt repos; try, but don't fail the run.
  sudo_run apt-get install -y eza  || warn "eza not packaged here; install manually if wanted"
  sudo_run apt-get install -y git-delta || warn "git-delta not in apt; see delta releases page"
  # Debian's fonts-jetbrains-mono is plain (no Nerd glyphs); fetch the Nerd build.
  install_nerd_font
  warn "Debian names: 'bat' -> batcat, 'fd' -> fdfind (alias or symlink as desired)"
  install_starship
  install_opencode
  if [[ "$dev" == "true" ]]; then
    info "dev linters"
    sudo_run apt-get install -y shellcheck luarocks || warn "install shellcheck/luarocks manually"
    run luarocks install --local luacheck || warn "luacheck: run 'luarocks install luacheck'"
  fi
}

bootstrap_macos() {
  info "macOS: installing tools via Homebrew"
  have brew || die "Homebrew not found. Install it from https://brew.sh, then re-run."
  run brew install neovim tmux fzf ripgrep bat eza git-delta starship zsh fd git opencode
  run brew install --cask ghostty || warn "ghostty cask skipped (already installed?)"
  install_nerd_font run brew install --cask font-jetbrains-mono-nerd-font
  if [[ "$dev" == "true" ]]; then
    info "dev linters"
    run brew install shellcheck luacheck
  fi
}

os="$(detect_os)"
echo "Bootstrap: platform=$os dev=$dev dry-run=$DOTFILES_DRY_RUN"
case "$os" in
  fedora) bootstrap_fedora ;;
  debian) bootstrap_debian ;;
  macos)  bootstrap_macos ;;
  *) die "Unsupported platform '$os'. See docs/BOOTSTRAP.md for manual steps." ;;
esac

cat <<'EOF'

Tools installed. Next:
  ./install.sh          # symlink configs (safe to re-run; backs up existing)
  make doctor           # confirm what's linked and present
  nvim                  # first launch installs plugins + treesitter parsers
EOF

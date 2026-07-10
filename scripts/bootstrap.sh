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

# JetBrains Mono has to be installed system-wide even though ghostty/config.ghostty
# names it and looks fine without it: Ghostty *embeds* the font, so the terminal
# renders correctly on a machine where fontconfig has never heard of it. Nothing
# else does. VS Code in particular resolves `editor.fontFamily` through fontconfig,
# and `fc-match "JetBrains Mono"` answers *Noto Sans* -- proportional -- when the
# font is missing, quietly un-monospacing the editor. So the terminal and the
# editor drift apart while every config file claims they agree.
#
# Not fatal: vscode/settings.json falls back through Source Code Pro, and Ghostty
# never needed it. Warn and carry on, as with eza/git-delta below.
font_warn="JetBrains Mono not installed; ghostty embeds it but VS Code will fall back"

# Upstream tag. v2.304 is byte-for-byte the release Fedora ships as
# jetbrains-mono-fonts 2.304, so the user-local fallback below is not a downgrade.
jbm_version="2.304"
jbm_url="https://github.com/JetBrains/JetBrainsMono/releases/download/v${jbm_version}/JetBrainsMono-${jbm_version}.zip"

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
  fc-match "JetBrains Mono" family 2>/dev/null | grep -qi 'JetBrains Mono'
}

# Fetch the release and unpack the TTFs into the user font directory. No root.
install_font_user() {
  local dir tmp
  dir="$(user_font_dir)/JetBrainsMono"
  have curl  || { warn "curl not found; cannot fetch JetBrains Mono"; return 1; }
  have unzip || { warn "unzip not found; cannot unpack JetBrains Mono"; return 1; }

  log "fetching JetBrains Mono $jbm_version into $dir (no root required)"
  tmp="$(mktemp -d)"
  if ! curl -sSL --fail --max-time 180 -o "$tmp/jbm.zip" "$jbm_url"; then
    rm -rf "$tmp"; warn "download failed: $jbm_url"; return 1
  fi
  if ! unzip -qo "$tmp/jbm.zip" 'fonts/ttf/*.ttf' -d "$tmp/x"; then
    rm -rf "$tmp"; warn "could not unpack the JetBrains Mono archive"; return 1
  fi
  mkdir -p "$dir"
  cp "$tmp/x"/fonts/ttf/*.ttf "$dir/"
  rm -rf "$tmp"

  # macOS has no fc-cache; CoreText picks up ~/Library/Fonts on its own.
  if have fc-cache; then fc-cache -f "$dir" >/dev/null 2>&1 || true; fi
  log "installed JetBrains Mono to $dir"
  return 0
}

# install_jetbrains_mono [PACKAGED INSTALL COMMAND...]
#
# Try the distro package first, and fall back to a user-local install when that
# fails for *any* reason -- no sudo, no TTY to type a password into, package not
# in the repo. Trust the packaged command's exit status rather than re-checking
# with font_present(): macOS has no fontconfig, so font_present() is always false
# there and would send a successful `brew install --cask` down the fallback path.
install_jetbrains_mono() {
  if font_present; then
    log "JetBrains Mono already installed"
    return 0
  fi

  if [[ "$DOTFILES_DRY_RUN" == "true" ]]; then
    [[ $# -gt 0 ]] && printf 'DRY RUN: %s\n' "$*"
    printf 'DRY RUN: on failure, fetch %s into %s\n' "$jbm_url" "$(user_font_dir)/JetBrainsMono"
    return 0
  fi

  if [[ $# -gt 0 ]] && "$@"; then
    log "JetBrains Mono installed via the system package manager"
    return 0
  fi

  warn "packaged install unavailable or failed; falling back to a user-local install"
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
  install_jetbrains_mono sudo_run dnf install -y jetbrains-mono-fonts
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
  install_jetbrains_mono sudo_run apt-get install -y fonts-jetbrains-mono
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
  install_jetbrains_mono run brew install --cask font-jetbrains-mono
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

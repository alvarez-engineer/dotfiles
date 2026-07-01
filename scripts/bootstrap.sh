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

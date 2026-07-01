# shellcheck shell=bash
# Shell functions. Sourced by bashrc and zshrc. Written to work in both.

# mkcd DIR — create a directory and cd into it.
mkcd() {
  [ -n "${1:-}" ] || { echo "usage: mkcd DIR" >&2; return 2; }
  mkdir -p -- "$1" && cd -- "$1" || return
}

# up [N] — cd up N directories (default 1).
up() {
  # Note: avoid the name 'path' here — in zsh it is tied to $PATH.
  local n="${1:-1}" rel=""
  case "$n" in
    ''|*[!0-9]*) echo "usage: up [N]" >&2; return 2 ;;
  esac
  while [ "$n" -gt 0 ]; do rel="../$rel"; n=$((n - 1)); done
  cd -- "$rel" || return
}

# extract FILE — unpack most common archive formats.
extract() {
  [ -f "${1:-}" ] || { echo "usage: extract FILE" >&2; return 2; }
  case "$1" in
    *.tar.bz2|*.tbz2) tar xjf "$1" ;;
    *.tar.gz|*.tgz)   tar xzf "$1" ;;
    *.tar.xz)         tar xJf "$1" ;;
    *.tar)            tar xf  "$1" ;;
    *.bz2)            bunzip2 "$1" ;;
    *.gz)             gunzip  "$1" ;;
    *.zip)            unzip   "$1" ;;
    *.7z)             7z x    "$1" ;;
    *.rar)            unrar x "$1" ;;
    *) echo "extract: unsupported format: $1" >&2; return 1 ;;
  esac
}

# fkill — fuzzy-pick a process and kill it (needs fzf).
fkill() {
  command -v fzf >/dev/null 2>&1 || { echo "fkill: fzf not installed" >&2; return 1; }
  local pid
  pid="$(ps -eo pid,comm,args | sed 1d | fzf --multi --prompt='kill> ' | awk '{print $1}')"
  [ -n "$pid" ] && echo "$pid" | xargs kill "${1:--TERM}"
}

# gcd — cd to a git repo's top level.
gcd() {
  local root
  root="$(git rev-parse --show-toplevel 2>/dev/null)" || { echo "not in a git repo" >&2; return 1; }
  cd -- "$root" || return
}

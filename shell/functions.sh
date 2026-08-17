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

# code [ARGS] — VS Code, closing the terminal it was launched from.
#
# `code .` is a hand-off: the work continues in the GUI, so the shell that
# launched it has nothing left to do. Exiting the shell is also exactly the
# "close only this tab" behavior wanted -- a Ghostty tab is one shell, and
# inside tmux it closes just that pane/window, never the whole terminal.
#
# It stays open for anything that is NOT a plain hand-off, which is why the
# flag list below is an allow-list rather than a list of exceptions:
#   - EDITOR="code -w" (git commit, crontab -e) must block, then return here.
#   - --help, --version, --list-extensions, --status print to this terminal.
#   - a pipe or a script: no PS1, or stdout is not a tty.
# A new VS Code flag is therefore inert here until it is added, which is the
# safe direction to fail. DOTFILES_CODE_NO_CLOSE=1 turns the close off.
#
# `env` runs the real binary (vscode/bin/code) rather than recursing into this
# function; nohup/setsid keep the GUI alive past the terminal's dying SIGHUP,
# which matters because `flatpak run` stays in the foreground.
code() {
  local arg
  # DOTFILES_CODE_DEBUG makes the shim print its resolved command instead of
  # running it -- output, so the terminal has to survive to show it.
  if [ -n "${DOTFILES_CODE_NO_CLOSE:-}" ] || [ -n "${DOTFILES_CODE_DEBUG:-}" ] ||
    [ -z "${PS1:-}" ] || [ ! -t 1 ]; then
    env code "$@"
    return
  fi
  for arg in "$@"; do
    case "$arg" in
      -n|--new-window|-r|--reuse-window|-g|--goto|-a|--add) ;;
      --folder-uri|--file-uri|--profile|--) ;;
      -*) env code "$@"; return ;;
    esac
  done
  if command -v setsid >/dev/null 2>&1; then
    setsid nohup env code "$@" >/dev/null 2>&1 &
  else
    nohup env code "$@" >/dev/null 2>&1 &
  fi
  # Off the job table, or interactive zsh answers the exit below with
  # "you have running jobs" and stays open until you exit a second time.
  disown 2>/dev/null || :
  exit 0
}

# gcd — cd to a git repo's top level.
gcd() {
  local root
  root="$(git rev-parse --show-toplevel 2>/dev/null)" || { echo "not in a git repo" >&2; return 1; }
  cd -- "$root" || return
}

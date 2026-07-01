# Muted coding prompt for bash.
# Source from ~/.bashrc:
#   source ~/.config/ghostty/shell/bash_prompt.sh

__ghostty_prompt_git() {
  command git rev-parse --is-inside-work-tree >/dev/null 2>&1 || return 0

  local branch status upstream counts ahead behind
  branch="$(command git branch --show-current 2>/dev/null)"
  if [[ -z "$branch" ]]; then
    branch="$(command git rev-parse --short HEAD 2>/dev/null)"
  fi
  [[ -z "$branch" ]] && return 0

  status=""
  if ! command git diff --quiet --ignore-submodules -- 2>/dev/null; then
    status="${status}*"
  fi
  if ! command git diff --cached --quiet --ignore-submodules -- 2>/dev/null; then
    status="${status}+"
  fi
  if command git ls-files --others --exclude-standard --directory --no-empty-directory 2>/dev/null | command head -n 1 | command grep -q .; then
    status="${status}?"
  fi

  upstream="$(command git rev-parse --abbrev-ref --symbolic-full-name '@{u}' 2>/dev/null || true)"
  if [[ -n "$upstream" ]]; then
    counts="$(command git rev-list --left-right --count HEAD..."$upstream" 2>/dev/null || true)"
    ahead="${counts%%[[:space:]]*}"
    behind="${counts##*[[:space:]]}"
    [[ "${ahead:-0}" != "0" ]] && status="${status}↑${ahead}"
    [[ "${behind:-0}" != "0" ]] && status="${status}↓${behind}"
  fi

  printf ' git:%s%s' "$branch" "$status"
}

__ghostty_prompt_env() {
  if [[ -n "${VIRTUAL_ENV:-}" ]]; then
    printf ' py:%s' "${VIRTUAL_ENV##*/}"
  elif [[ -n "${CONDA_DEFAULT_ENV:-}" ]]; then
    printf ' conda:%s' "$CONDA_DEFAULT_ENV"
  fi
}

__ghostty_prompt_status() {
  local code="${1:-0}"
  if [[ "$code" != "0" ]]; then
    printf ' exit:%s' "$code"
  fi
}

__ghostty_make_ps1() {
  local last_status="${1:-0}"
  local reset='\[\e[0m\]'
  local dim='\[\e[38;5;244m\]'
  local accent='\[\e[38;5;109m\]'
  local warn='\[\e[38;5;173m\]'
  local bad='\[\e[38;5;167m\]'

  local git env status
  git="$(__ghostty_prompt_git)"
  env="$(__ghostty_prompt_env)"
  status="$(__ghostty_prompt_status "$last_status")"

  printf '%s\\w%s%s%s%s%s%s%s%s\n%s❯%s ' \
    "$dim" "$reset" \
    "$accent" "$git" "$reset" \
    "$warn" "$env" "$reset" \
    "${bad}${status}${reset}" \
    "$accent" "$reset"
}

__ghostty_prompt_command() {
  local last_status="$?"
  PS1="$(__ghostty_make_ps1 "$last_status")"
}

PROMPT_COMMAND=__ghostty_prompt_command

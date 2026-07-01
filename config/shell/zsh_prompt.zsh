# Muted coding prompt for zsh.
# Source from ~/.zshrc:
#   source ~/.config/ghostty/shell/zsh_prompt.zsh

setopt PROMPT_SUBST

__ghostty_zsh_git() {
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

  printf ' %%F{109}git:%s%s%%f' "$branch" "$status"
}

__ghostty_zsh_env() {
  if [[ -n "${VIRTUAL_ENV:-}" ]]; then
    printf ' %%F{179}py:%s%%f' "${VIRTUAL_ENV:t}"
  elif [[ -n "${CONDA_DEFAULT_ENV:-}" ]]; then
    printf ' %%F{179}conda:%s%%f' "$CONDA_DEFAULT_ENV"
  fi
}

PROMPT='%F{244}%~%f$(__ghostty_zsh_git)$(__ghostty_zsh_env) %(?..%F{167}exit:%?%f )
%F{109}❯%f '

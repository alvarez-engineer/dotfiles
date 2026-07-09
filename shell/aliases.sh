# shellcheck shell=bash
# Aliases. Sourced by bashrc and zshrc. POSIX-compatible so both shells agree.

# --- Listing: prefer eza, fall back to coloured ls ---
if command -v eza >/dev/null 2>&1; then
  alias ls='eza --group-directories-first'
  alias ll='eza -l --group-directories-first --git'
  alias la='eza -la --group-directories-first --git'
  alias lt='eza --tree --level=2 --group-directories-first'
else
  # Pick the flags once, here — never inside the alias body. An alias is textual
  # substitution, so `ls DIR` with a `cmd || fallback` body expands to
  # `ls <flags> || ls --color=auto DIR`: the first branch succeeds, lists the
  # *current* directory, and DIR is never shown. GNU coreutils takes
  # --color/--group-directories-first; BSD (macOS) ls takes neither, only -G.
  if command ls --color=auto --group-directories-first / >/dev/null 2>&1; then
    __ls_flags='--color=auto --group-directories-first'
  elif command ls --color=auto / >/dev/null 2>&1; then
    __ls_flags='--color=auto'
  else
    __ls_flags='-G'
  fi
  # Expanding $__ls_flags at definition time is exactly the intent: the probe
  # above already chose, so the alias must not re-evaluate later (hence SC2139).
  # `command ls` keeps ll/la from re-expanding the `ls` alias onto their flags.
  # shellcheck disable=SC2139
  alias ls="command ls $__ls_flags"
  # shellcheck disable=SC2139
  alias ll="command ls -lh $__ls_flags"
  # shellcheck disable=SC2139
  alias la="command ls -lah $__ls_flags"
  unset __ls_flags
fi
alias l='ll'

# --- Viewing: prefer bat ---
if command -v bat >/dev/null 2>&1; then
  alias cat='bat --paging=never'
  alias less='bat'
fi

# --- grep colours ---
# grep >= 3.8 warns that the egrep/fgrep binaries are obsolescent, so route
# those names at the flag instead of at the deprecated wrappers.
alias grep='grep --color=auto'
alias egrep='grep -E --color=auto'
alias fgrep='grep -F --color=auto'

# --- Navigation ---
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias -- -='cd -'

# --- Safety / conveniences ---
alias mkdir='mkdir -p'
alias df='df -h'
alias du='du -h'
alias mv='mv -i'
alias cp='cp -i'

# --- git shortcuts (mirror the aliases in the git module) ---
alias gs='git status --short --branch'
alias ga='git add'
alias gc='git commit'
alias gca='git commit --amend'
alias gp='git push'
alias gl='git log --oneline --graph --decorate -20'
alias gd='git diff'
alias gco='git checkout'
alias gb='git branch'
alias gsw='git switch'

# --- agent-sandbox: short alias when the tool is on PATH ---
if command -v agent-sandbox >/dev/null 2>&1; then
  alias abox='agent-sandbox'
fi

# --- misc ---
alias reload='exec "$SHELL" -l'
alias path='printf "%s\n" "$PATH" | tr ":" "\n"'
alias serve='python3 -m http.server'

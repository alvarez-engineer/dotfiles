# shellcheck shell=bash
# Aliases. Sourced by bashrc and zshrc. POSIX-compatible so both shells agree.

# --- Listing: prefer eza, fall back to coloured ls ---
if command -v eza >/dev/null 2>&1; then
  alias ls='eza --group-directories-first'
  alias ll='eza -l --group-directories-first --git'
  alias la='eza -la --group-directories-first --git'
  alias lt='eza --tree --level=2 --group-directories-first'
else
  alias ls='ls --color=auto --group-directories-first 2>/dev/null || ls --color=auto'
  alias ll='ls -lh --color=auto'
  alias la='ls -lah --color=auto'
fi
alias l='ll'

# --- Viewing: prefer bat ---
if command -v bat >/dev/null 2>&1; then
  alias cat='bat --paging=never'
  alias less='bat'
fi

# --- grep colours ---
alias grep='grep --color=auto'
alias egrep='egrep --color=auto'
alias fgrep='fgrep --color=auto'

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

# --- misc ---
alias reload='exec "$SHELL" -l'
alias path='printf "%s\n" "$PATH" | tr ":" "\n"'
alias serve='python3 -m http.server'

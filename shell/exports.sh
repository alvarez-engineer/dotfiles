# shellcheck shell=bash
# Environment variables. Sourced by bashrc and zshrc.
# Safe to source in both bash and zsh.

# Preferred editor: nvim > vim > vi.
if command -v nvim >/dev/null 2>&1; then
  export EDITOR="nvim"
elif command -v vim >/dev/null 2>&1; then
  export EDITOR="vim"
else
  export EDITOR="vi"
fi
export VISUAL="$EDITOR"

# Pager. less with sane, color-friendly defaults.
export PAGER="less"
export LESS="-R -F -X -i -M -j.5"
export LESSHISTFILE="-"

# Locale/UTF-8 (only set if not already configured).
: "${LANG:=en_US.UTF-8}"
export LANG

# bat: match the terminal theme and disable its own paging noise.
if command -v bat >/dev/null 2>&1; then
  export BAT_THEME="muted-ink"
  # Use bat as the man pager for colorized man pages.
  export MANPAGER="sh -c 'col -bx | bat --language man --style=plain'"
  export MANROFFOPT="-c"
fi

# ripgrep: pick up the repo's ripgreprc when the cli module is installed.
if [ -r "$HOME/.config/ripgrep/ripgreprc" ]; then
  export RIPGREP_CONFIG_PATH="$HOME/.config/ripgrep/ripgreprc"
fi

# fzf: muted-ink colors + use ripgrep/fd for file lists when available.
export FZF_DEFAULT_OPTS="\
--height=40% --layout=reverse --border=rounded --info=inline \
--color=bg+:#161b22,gutter:-1,fg+:#e6edf3,hl:#7aa2a5,hl+:#7dabab \
--color=info:#6b7280,border:#263241,prompt:#8ba88b,pointer:#7dabab \
--color=marker:#b8a06a,spinner:#9a7eaa,header:#6b7280"
if command -v rg >/dev/null 2>&1; then
  export FZF_DEFAULT_COMMAND='rg --files --hidden --glob "!.git/*"'
  export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
fi

# Starship config path (symlinked by the shell module).
export STARSHIP_CONFIG="${XDG_CONFIG_HOME:-$HOME/.config}/starship.toml"

# opencode CLI installs to ~/.opencode/bin; add it to PATH when present.
[ -d "$HOME/.opencode/bin" ] && export PATH="$HOME/.opencode/bin:$PATH"

# agent-sandbox (sandboxed coding-agent runner) lives in its own repo; add its
# bin/ to PATH when checked out.
[ -d "$HOME/projects/agent-sandbox/bin" ] && export PATH="$HOME/projects/agent-sandbox/bin:$PATH"

# Less history / colored GCC diagnostics.
export GCC_COLORS="error=01;31:warning=01;35:note=01;36:caret=01;32:locus=01:quote=01"

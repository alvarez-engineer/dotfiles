# Shell module

Managed `~/.bashrc` and `~/.zshrc` plus shared aliases, exports, and functions.

## What gets installed

| Source (repo)            | Destination              |
|--------------------------|--------------------------|
| `shell/bashrc`           | `~/.bashrc` (symlink)    |
| `shell/zshrc`            | `~/.zshrc` (symlink)     |
| `shell/starship.toml`    | `~/.config/starship.toml`|

The rc files **source your distro defaults first** (`/etc/bashrc`, `~/.bashrc.d`
on Fedora) so nothing system-provided is lost, then load the shared modules and
finally your machine-local override file.

## Shared modules (sourced by both shells)

- `shell/exports.sh` — `EDITOR`/`VISUAL` (inherited if already set, else
  nvim→vim→vi), `PAGER`/`LESS`, bat as the man pager, `RIPGREP_CONFIG_PATH`,
  `FZF_DEFAULT_OPTS` (muted-ink colors), `STARSHIP_CONFIG`, `NOTES_DIR`.
- `shell/aliases.sh` — `ls`/`ll`/`la` (eza when present, otherwise `ls`), `cat`→bat,
  grep colors, `..`/`...` navigation, git shortcuts, `reload`, `serve`.
- `shell/functions.sh` — `mkcd`, `up [N]`, `extract`, `fkill` (fzf), `gcd`.

Aliases and functions are written in POSIX-compatible form so bash and zsh
behave the same.

### Changing the editor

`exports.sh` only probes for nvim→vim→vi when `EDITOR` is **unset**, so anything
that already exported it (`~/.profile`, an ssh client, `EDITOR=hx tmux new`)
survives. Nothing else in the repo pins an editor: git resolves `$VISUAL` then
`$EDITOR`, and `bd`/`bdf`/`bdg` run `${EDITOR:-vi}`. To change it everywhere, set
it in `~/.bashrc.local` / `~/.zshrc.local`, which are sourced last:

```bash
export EDITOR="hx"
export VISUAL="$EDITOR"
```

**A GUI editor must block until you close the file.** Terminal editors hold the
foreground already; a GUI one usually forks and exits immediately, and git reads
the unchanged commit message and aborts. Pass the editor's wait flag:

```bash
export EDITOR="code -w"       # VS Code
export EDITOR="cursor -w"     # Cursor -- see the macOS caveat below
export EDITOR="subl -w"       # Sublime Text
export EDITOR="zed -w"        # Zed
export EDITOR="gvim -f"       # gVim, -f for "foreground"
export VISUAL="$EDITOR"
```

`EDITOR` is split on whitespace when it is run, so `"code -w"` works, but a path
containing spaces does not. Wrap those in a script on `PATH` instead.

**Cursor.** It is a VS Code fork, so `cursor -w` is the same flag and works on
Linux. Two known problems, neither ours to fix: on macOS `cursor --wait` has
crashed with `Unable to find helper app` (an Electron packaging bug, open across
2.0.77–2.1.42), and Cursor mishandles repository paths containing spaces. Since
this repo targets macOS as a first-class platform, do not assume `cursor -w` in
a shared config — test it on the machine, and keep `code -w` as the fallback.
Note also that `cursor` is the GUI launcher; `cursor-agent` is a different
binary (the coding agent) and is not an `$EDITOR`.

Some editors have no wait flag at all. **Obsidian is one** — it is a vault
browser, not a `$EDITOR`, and it cannot be handed a scratch file and waited on.
Point `EDITOR` at a real editor and let Obsidian open `$NOTES_DIR` as a vault
alongside it; the notes are plain markdown, so both see the same files.

### The `ls` fallback, and why it is not written inside the alias

When `eza` is absent, `aliases.sh` probes `ls` **once, at source time** and bakes
the right flags in — GNU coreutils takes `--color=auto --group-directories-first`,
BSD/macOS `ls` takes neither and wants `-G`.

Putting the fallback *inside* the alias body is the obvious-looking approach and
it is broken, because an alias is textual substitution. Given

```sh
alias ls='ls --color=auto --group-directories-first 2>/dev/null || ls --color=auto'
```

the command `ls somedir` expands to

```sh
ls --color=auto --group-directories-first 2>/dev/null || ls --color=auto somedir
```

On GNU the first branch succeeds — listing the **current** directory — and
`somedir` is never shown. On macOS both branches fail on the unknown flag.

## Prompt

If `starship` is installed it is used automatically. Otherwise the bundled
dependency-free prompt (`shell/prompt/bash_prompt.sh` / `zsh_prompt.zsh`) is
sourced — it shows cwd, git branch + dirty/staged/untracked/ahead-behind state,
Python venv, and last exit code. See [PROMPT.md](PROMPT.md).

## Local overrides (untracked)

Put anything private or machine-specific in `~/.bashrc.local` / `~/.zshrc.local`.
They are sourced last, so they win. Examples:

```bash
export PATH="$HOME/dev/tools:$PATH"
export AWS_PROFILE=work
alias k=kubectl
```

## Notes

- History is de-duplicated and large (50k/100k) with sensible ignore patterns.
- fzf key bindings/completion load automatically when fzf is installed
  (`fzf --bash` / `fzf --zsh`, with a fallback to the packaged scripts).
- Re-source after edits with `reload` (re-execs your login shell).

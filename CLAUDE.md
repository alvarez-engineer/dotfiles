# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repo is

A cross-platform (Linux + macOS) **dotfiles** repo — configs for Ghostty, shell
(bash/zsh), git, tmux, Neovim, and CLI tools (bat/fzf/ripgrep), installed by
symlink. **No build step.** Almost entirely bash scripts, config files, and a
small Lua Neovim config, all themed to one `muted-ink` palette. The one exception
is `vscode/extensions/dotfiles-workbench` — a small plain-CommonJS VS Code
extension (no bundler, no transpile), because a workbench layout and a status-bar
item are extension-only APIs. It is gated by `node --check`, the JS analog of
`bash -n`. So "no application code" narrowed to "no build step."

## Commands

```bash
./install.sh [--bootstrap] [--copy] [--dry-run] [MODULE ...]  # MODULES: ghostty shell git tmux nvim cli opencode vscode claude notes
make bootstrap [bootstrap-dev]  # install tool BINARIES via dnf/apt/brew (sudo); -dev adds linters
make all                     # bootstrap + install in one shot
make install / dry-run / uninstall
make install-<module>        # e.g. make install-nvim
make doctor                  # report linked targets + missing binaries
make backup                  # tarball all managed files to ./backups/
make validate                # ghostty +validate-config (needs ghostty CLI)
make check                   # THE quality gate — run after editing any script
```

`scripts/bootstrap.sh` (needs sudo on Linux) installs the tool binaries; it is
deliberately separate from `install.sh`, which only symlinks configs and needs
no root. `--bootstrap`/`make all` chains them.

There is no test suite. `make check` is the gate: `bash -n` on all shell
scripts, plus `zsh -n`, `shellcheck`, and `luacheck` **when those tools are
present** (each step skips gracefully otherwise, so it exits 0 locally). CI
(`.github/workflows/check.yml`) installs them so the full gate runs on push/PR,
on both Linux and macOS.

The gate lints exactly the files in `SH_FILES` (Makefile) — **a new script that
isn't added there is never checked.** Three ways the gate has silently failed to
gate, all fixed; do not reintroduce them:

- `bash -n a b c` parses only `a`, passing `b c` as positional args. One file
  per invocation, in a loop.
- `cmd1; cmd2` returns only `cmd2`'s status. Use `|| exit 1` per command.
- `luacheck … || true` swallows every error.

When you change the gate, verify each leg can still *fail*: break a file
deliberately, confirm `make check` is non-zero, then restore it.

## Architecture (the important part)

**Module = top-level directory + its own `install.sh`.** The modules are
`ghostty/ shell/ git/ tmux/ nvim/ cli/ opencode/ vscode/ claude/ notes/`. The root `install.sh` is
only an orchestrator: it sets three env vars and then sources each selected
module's installer.

- `lib/common.sh` is the shared library every module installer sources. Its
  **`link_file SRC DEST`** is the core primitive: no-op if already linked,
  else mkdir parents → back up existing `DEST` to `DEST.backup-<ts>` → symlink
  (or copy). Also provides `backup_path`, `run` (dry-run wrapper), `have`, and
  exports `DOTFILES_ROOT`/`XDG_CONFIG_HOME`.
- Env contract between root and modules: `DOTFILES_MODE` (symlink|copy),
  `DOTFILES_DRY_RUN` (true|false), `DOTFILES_PLATFORM` (macos|linux|other).
  A module installer must honor these — always go through `link_file`/`run`,
  never `ln`/`cp`/`mv` directly, or `--dry-run` and `--copy` break.
- **Nothing private or generated lives in the repo.** Managed configs load an
  untracked local file **last, so it overrides**: `~/.gitconfig.local`
  (identity), `~/.bashrc.local`, `~/.zshrc.local`,
  `~/.config/ghostty/local.ghostty`. Put machine/secret settings there.
  "Last" is load-bearing: git applies an `[include]` where it appears and the
  last value of a single-valued key wins, so the `[include]` must stay the final
  line of `git/gitconfig` or every setting above it beats the user's override.
  The `notes/` module is the same idea taken further: it ships commands and a
  marker grammar, while the notes live in `$NOTES_DIR` (default `~/notes`),
  outside the repo and ideally its own git repo.
- `scripts/` holds cross-cutting tools (`doctor.sh`, `backup.sh`,
  `uninstall.sh`); ghostty-specific helpers (`validate.sh`, `use-profile.sh`,
  `print-paths.sh`) live in `ghostty/`.

**`vscode` is the one module that cannot just symlink its payload in**, and it breaks
three of the rules above for reasons worth knowing before you "fix" it:

- VS Code treats `extensions.json` in the extensions directory — not the directory
  listing — as the authoritative record of installed user extensions. A folder merely
  symlinked in is scanned, written into `.obsolete`, and ignored (`[info] Marked
  extension as removed dotfiles.muted-ink-1.0.0`). So `vscode/install.sh` packages the
  theme into a throwaway `.vsix`, registers it via `code --install-extension`, then
  replaces VS Code's installed copy with a symlink back into the repo. The symlink
  survives *because* the id is registered.
- That swap deliberately uses `run rm -rf` + `run ln -s` instead of `link_file`.
  `link_file` would rename the fresh copy to `<dir>.backup-<ts>` **inside** the
  extensions directory, where VS Code would scan it as a second, orphaned extension.
- It resolves a *pair* of roots (user config, extensions), and a flatpak install
  relocates both. `scripts/doctor.sh` and `scripts/uninstall.sh` each mirror that
  detection block — change one, change all three.

Also: VS Code rewrites `settings.json` through the symlink, into the repo. Uninstalling
the theme while VS Code is running *deletes* `workbench.colorTheme` from the tracked
file rather than leaving a dangling name. And Fedora's VS Code is a flatpak with no
`code` on `PATH`, which is why `vscode/bin/code` exists; it must defer to a native
`code` because `shell/bashrc` *prepends* `~/.local/bin`.

**A flatpak VS Code runs its integrated terminal inside the sandbox**, where `PATH` is
`/app/bin:/usr/bin` — bash, git, python3, and *none* of tmux, nvim, ripgrep, fzf, or
claude. So `vscode/bin/dev-shell` is the terminal profile: `/.flatpak-info` detects the
sandbox, `host-spawn` (or `flatpak-spawn --host`) re-execs the script on the host, where
that file is absent so it cannot recurse, and it then attaches one tmux session per
project directory. Both spawn helpers preserve cwd but **neither forwards the
environment** — `host-spawn` passes only `$TERM` unless told otherwise, and a dropped
variable fails silently. That same sandbox needs no special case in `vscode/bin/code`:
its PATH scan finds `/app/bin/code` and defers to it. `dev-shell` also forwards
`CLAUDE_CODE_SSE_PORT` across `host-spawn` so a host-side `claude` still auto-connects to
the VS Code IDE server (diffs as editor tabs); that var is otherwise dropped at the
boundary. It takes `--suffix NAME` (a second, independent session — the workbench's
claude column uses `<dir>-cc`) and `--run CMD` (run once, only on session create, so a
reattach never relaunches it).

**The workbench layout is a coded extension, and both terminals must be editor-area
terminals.** VS Code's bottom panel is a *single* dock, so it cannot be both
under-the-editor and a right column at once — `vscode/extensions/dotfiles-workbench`
therefore builds an editor grid (`vscode.setEditorLayout`) with two editor-area
terminals rather than using the panel. It is idempotent: auto-build is skipped when a
restored window (`enablePersistentSessions`) already put terminals in the editor area, so
it never stacks a second set. Both extensions install the same way — `install.sh` packages
each into a throwaway `.vsix`, registers it, then symlinks the repo dir over VS Code's
copy (see the theme note above); the shared `install_local_extension` handles theme and
code alike.

**`claude/settings.json` is seeded, never symlinked.** Claude Code has no user-level
`.local` layer (`settings.local.json` is project-scoped), and `~/.claude/settings.json`
mixes portable preferences with `enabledPlugins` and `skipDangerousModePermissionPrompt`
— a security posture that must not enter version control. `claude/install.sh` seeds it
only when absent and prints hints otherwise; `uninstall.sh` leaves it. Its `statusLine`
command gets an absolute path baked in at seed time, because a leading `~` is not
reliably expanded there. `claude/statusline.sh` and Claude Code's `dark-ansi` theme both
paint from the 16 ANSI colors rather than muted-ink hex, so they inherit the palette from
whichever terminal hosts them.

## Theming

`muted-ink` is defined once as a palette (hex in `ghostty/themes/muted-ink`) and
**re-expressed per tool** — changing a color means editing every expression:
`ghostty/themes/muted-ink`, `nvim/colors/muted-ink.lua`,
`nvim/lua/plugins/lualine.lua`, `cli/bat/themes/muted-ink.tmTheme` (also used by
git-delta via `syntax-theme = muted-ink`), `tmux/tmux.conf` status colors, the
`[delta]` block in `git/gitconfig`, the `--colors`/`FZF_DEFAULT_OPTS` in
`cli/ripgrep/ripgreprc` and `shell/exports.sh`,
`opencode/themes/muted-ink.json` (defs palette + full theme), and
`vscode/extensions/muted-ink/themes/muted-ink-color-theme.json`. The vscode and
opencode syntax mappings are intentionally the same token→color table; keep them
in step.

## Conventions

- Shell scripts: `set -euo pipefail`, a `usage()`, support `--dry-run`.
- `shell/aliases.sh` and `functions.sh` are sourced by **both** bash and zsh —
  keep them POSIX-compatible. `shell/bashrc` intentionally sources distro
  defaults (`/etc/bashrc`, `~/.bashrc.d`) so managing it doesn't break Fedora.
- Tools degrade gracefully when a binary is absent: `git` pager is
  `delta || less`; `ls` aliases fall back from `eza` to `ls`; the prompt uses
  starship if present else the bundled `shell/prompt/*` snippets.
- **Never put a `cmd || fallback` inside an alias body.** An alias is textual
  substitution, so `ls DIR` expands to `ls <flags> || ls --color=auto DIR` and
  the first branch lists the *cwd* while `DIR` is dropped. Probe the tool once
  at source time and bake the chosen flags in (see `shell/aliases.sh`).
- **Never hardcode a tool's absolute path.** Homebrew installs to
  `/opt/homebrew/bin` (Apple Silicon) or `/usr/local/bin` (Intel), never
  `/usr/bin` — resolve through `PATH` (e.g. `!gh auth git-credential`).
- macOS is a first-class target: BSD `date` has no `-Iseconds` (use
  `date +%Y-%m-%dT%H%M`), BSD `ls` has no `--color`/`--group-directories-first`
  (use `-G`), and BSD awk chokes on interval expressions like `{0,3}`.
- Ghostty config: comments on their own line — no trailing inline comments in
  `.ghostty` files. Validate real changes with `make validate`.
- Binaries are NOT installed by this repo; `docs/BOOTSTRAP.md` has the per-OS
  package commands (everything but starship and opencode is in Fedora repos).

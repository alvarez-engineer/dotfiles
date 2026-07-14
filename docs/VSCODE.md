# VS Code

The `vscode` module installs:

| Repo file | Installed to | How |
|-----------|--------------|-----|
| `vscode/settings.json` | the platform's `Code/User/settings.json` | symlink |
| `vscode/extensions/muted-ink/` | the extensions dir, as `dotfiles.muted-ink-1.0.0` | registered via `.vsix`, then symlinked — [see below](#theme) |
| `vscode/extensions/dotfiles-workbench/` | the extensions dir, as `dotfiles.workbench-1.0.0` | same `.vsix`-then-symlink — [see below](#workbench-layout) |
| `vscode/bin/code` | `~/.local/bin/code` | symlink |
| `vscode/bin/dev-shell` | `~/.local/bin/dev-shell` | symlink — the integrated terminal's shell |

```bash
./install.sh vscode      # or: make install-vscode
```

Restart VS Code afterwards — a running window does not notice a newly linked
extension directory.

## Where VS Code actually keeps its config

There is no single XDG path, and a flatpak install relocates both roots. This is
the one module that has to resolve a *pair* of directories:

| Install | User config | Extensions |
|---------|-------------|------------|
| flatpak | `~/.var/app/com.visualstudio.code/config/Code/User` | `~/.var/app/com.visualstudio.code/data/vscode/extensions` |
| Linux native | `~/.config/Code/User` | `~/.vscode/extensions` |
| macOS | `~/Library/Application Support/Code/User` | `~/.vscode/extensions` |

`vscode/install.sh` detects the flavor by testing for the flatpak app directory,
and `scripts/doctor.sh` and `scripts/uninstall.sh` mirror that logic.

## The `code` shim

Fedora ships VS Code as a flatpak, which installs **no `code` command**. Its
launcher is exported as `com.visualstudio.code`, into
`/var/lib/flatpak/exports/bin` — a directory that is not on `PATH`. So a working
VS Code install still leaves `code file` and `EDITOR="code -w"` broken.

`vscode/bin/code` gives every machine one `code`. Two details matter:

- **It defers to a real VS Code.** `shell/bashrc` and `shell/zshrc` *prepend*
  `~/.local/bin` to `PATH`, so this shim is found before `/usr/bin/code` on a
  machine with a native `.rpm`/`.deb` install. It scans `PATH` for the first
  `code` that is not itself and `exec`s that, falling back to flatpak only when
  there is none. (It compares with bash's `-ef`, not `readlink -f`, which BSD
  and macOS lacked before Monterey.)

- **It passes `--filesystem=/tmp` to flatpak.** Even with `filesystems=host`, a
  flatpak gets a private `/tmp` and cannot read a host `/tmp` file. Tools that
  hand `$EDITOR` a scratch file there (`crontab -e`, `sudoedit`) would open an
  empty buffer and silently discard the edit. `git commit` is unaffected — its
  `COMMIT_EDITMSG` sits inside `.git` — which is precisely why the bug hides.

The PATH scan turns out to cover the flatpak sandbox for free. Run from VS Code's
own integrated terminal, the shim finds `/app/bin/code` — VS Code's real CLI, inside
the sandbox — and defers to it, so `code file` opens a tab in the window you are
already in. Run from a host shell, there is no `code`, and it falls back to
`flatpak run`. That path is single-instance too: `code file` on a running VS Code
attaches to it rather than starting a second app.

`DOTFILES_CODE_DEBUG=1 code` prints the command it would run and exits.

The shim is a transparent pass-through, so unlike other scripts here it has no
`usage()` and no `--dry-run`: every argument, `-h` included, belongs to VS Code.

## The integrated terminal runs inside the sandbox

This is the one that bites. A flatpak VS Code runs its integrated terminal **inside
the flatpak sandbox**, whose `PATH` is only `/app/bin:/usr/bin`. That gives you
`bash`, `git`, `python3`, `make` — and:

```text
[ ] tmux    MISSING
[ ] nvim    MISSING
[ ] claude  MISSING
[ ] rg      MISSING
[ ] fzf     MISSING
```

None of the tools this repo installs. The default integrated terminal cannot run
Claude Code at all.

`vscode/bin/dev-shell` is the terminal profile. It:

1. Detects the sandbox by `/.flatpak-info` and re-execs itself on the host through
   `host-spawn` (or `flatpak-spawn --host`). On the host that file is absent, so it
   does not recurse.
2. Attaches — or creates — **one tmux session**, named for the working directory
   (with `.` and `:` replaced, which tmux forbids in session names), plus an
   optional `--suffix` — the workbench's Claude column uses `<dir>-cc` so it is an
   independent session, not a mirror of the main one.
3. Runs a one-off command with `--run "CMD"`, but only when the session is first
   *created* — so reattaching (a later terminal, or VS Code restoring the session)
   never relaunches it.

The **first** terminal for a directory creates that session and attaches to it.
Every terminal after it joins a **grouped session** instead (`tmux new-session -t
<dir>`, auto-named `<dir>-1`, `<dir>-2`, …): same window list, but its own
current-window pointer. This is the difference between a second *client* and a
second *session*. Two clients of one session mirror each other — same active
window, shared keystrokes and output — which is why opening a new terminal in VS
Code used to echo whatever the first one was already running. A grouped session
shares the windows without the mirroring, so each terminal can sit on a different
window. The clone sets `destroy-unattached on`, so closing that terminal reaps it
while the base session — and the shells running in it — survive. Use `--suffix`
when you want a terminal with a *wholly separate* window list rather than another
view onto the same one.

One pane per terminal, on purpose: the workbench layout (below) is what places two
terminals, so `dev-shell` no longer splits its own pane. It also forwards
`CLAUDE_CODE_SSE_PORT` across `host-spawn`, so a `claude` started on the host still
finds the VS Code IDE server and opens its diffs as editor tabs — without that, the
auto-connect is silently lost at the sandbox boundary.

Both spawn helpers preserve the working directory, which the session name depends
on. **Neither forwards the environment**: `host-spawn` passes only `$TERM` unless
you name more variables, and getting that wrong fails silently — the variable is
simply empty on the far side. `dev-shell` names them explicitly.

The payoff is that the terminal inside VS Code and `tmux attach -t <dir>` from
Ghostty are the *same session*. Closing the editor does not kill the shell, and
switching windows costs no state. Terminal persistence is left **on**
(`enablePersistentSessions: true`): the tmux server is a host daemon that outlives
the editor, so restore reattaches the live session rather than reviving a dead one.

`DOTFILES_DEV_SHELL_NO_TMUX=1` gives a plain login shell.

### tmux and VS Code keybindings

VS Code binds `ctrl+b` to `toggleSidebarVisibility` and handles it before the shell
sees it — which would eat tmux's **stock** prefix. `tmux/tmux.conf` already rebinds
the prefix to `ctrl+a` and unbinds `ctrl+b`, and `ctrl+a` is not a VS Code terminal
binding, so the two coexist.

If a chord is ever swallowed, `"terminal.integrated.sendKeybindingsToShell": true`
sends every keystroke to the shell — at the cost of VS Code's own shortcuts while
the terminal has focus.

## Workbench layout

`vscode/extensions/dotfiles-workbench` lays each project into one fixed shape when
you open it:

```text
┌──────────┬─────────────────────┬───────────────┐
│ Explorer │  file / git diff    │    claude     │
│          │─────────────────────│  (ready shell)│
│          │  terminal           │               │
└──────────┴─────────────────────┴───────────────┘
   sidebar        editor grid: 2 columns,
                  left column split into 2 rows
```

Both terminals are **editor-area** terminals, not the panel: VS Code's bottom panel
is a single dock and cannot be both under-the-editor and a right column at once. The
extension builds an editor grid with `vscode.setEditorLayout` (two columns, the left
split into two rows) and drops a terminal into each of the lower-left and right
groups. The center terminal is `dev-shell` (session `<dir>`); the right is
`dev-shell --suffix cc` (session `<dir>-cc`), a **ready shell** — type `claude` when
you want it. Set `dotfilesWorkbench.claudeAutostart` to launch it automatically.

It is the repo's one coded extension — plain CommonJS, no build step, gated by
`node --check`. Settings:

| Setting | Default | Effect |
|---------|---------|--------|
| `dotfilesWorkbench.autoLayout` | `true` | build on folder open |
| `dotfilesWorkbench.claudeAutostart` | `false` | run `claude` in the right terminal |
| `dotfilesWorkbench.shellPath` | `""` | override `~/.local/bin/dev-shell` |

**Idempotent.** Auto-build is skipped when a restored window
(`enablePersistentSessions`) already has editor-area terminals, so it never stacks a
second layout on top of the first. **`Ctrl+Alt+D`** (or *Dotfiles: Build Dev Layout*)
rebuilds it on demand — useful the first time you open a brand-new repo, or after
tearing the layout down.

> Installing or reloading the extension while a project window is open builds the
> layout in that live window. That is the feature, but it means a running window
> rearranges the moment the extension loads.

### Using it as `$EDITOR`

`shell/exports.sh` deliberately probes `nvim > vim > vi` and never picks a GUI
editor. To make VS Code your `$EDITOR`, set it in `~/.bashrc.local` or
`~/.zshrc.local`, which load last and override:

```bash
export EDITOR="code -w"
export VISUAL="$EDITOR"
```

With the shim on `PATH` this works on flatpak and native installs alike.

## settings.json is read-write

VS Code rewrites `settings.json` whenever you change a setting from the UI. It
edits *through* the symlink, so those writes land in the repo — run `git diff`
after a settings-tweaking session and commit what you meant to keep.

If VS Code ever replaces the symlink with a plain file, `make doctor` reports it:

```text
[o] ~/.var/.../settings.json    exists but is not a symlink
```

Re-run `./install.sh vscode` to restore the link (the plain file is backed up
first, as with any other target).

There is no `settings.json.local` layer — VS Code has no include mechanism. For
machine- or project-specific settings, use a workspace `.vscode/settings.json`
or a VS Code Profile.

> `git/gitignore_global` ignores `.vscode/` globally. To commit a workspace
> settings file for a project, `git add -f .vscode/settings.json`.

## What the settings actually do

The theme aside, `vscode/settings.json` is mostly subtraction — it removes chrome
that duplicates what the editor already tells you: the minimap, breadcrumbs, the
command center, the layout control, the per-editor action buttons. The activity
bar moves to the top, where it costs a row instead of a column. Tabs render flat,
with the active one marked by a single top rule in the accent color.

Two settings are worth calling out:

- **`editor.fontFamily` is a real stack, not just `JetBrains Mono`.** Ghostty
  *bundles* that font, so `font-family = JetBrains Mono` works there even when it
  is not installed system-wide. VS Code bundles nothing. On a machine without it,
  `fc-match "JetBrains Mono"` answers **Noto Sans** — a proportional font — and
  your editor quietly stops being monospaced. The stack falls back through
  `Source Code Pro` and `Adwaita Mono` to the generic `monospace`.

- **`editor.formatOnSave` is off on purpose.** Formatting is a per-project
  decision; a global default rewrites files in repos that never asked for it.

## Theme

`Muted Ink` is a local extension, not a Marketplace install.
[See what it looks like](muted-ink-preview.html) before installing.

**Dropping the folder into the extensions directory does not work.** A current
VS Code treats `extensions.json` — not the directory listing — as the
authoritative record of installed user extensions. It scans an unlisted folder,
then writes it into `.obsolete` and ignores it. On 1.127 the log says:

```text
[info] Marked extension as removed dotfiles.muted-ink-1.0.0
```

The only supported way into `extensions.json` is `--install-extension` with a
packaged `.vsix`. So `vscode/install.sh` does two things:

1. Zips `vscode/extensions/muted-ink/` into a throwaway `.vsix` and installs it,
   which registers the id and leaves a *copy* in the extensions directory. (A
   local `.vsix` is just a zip whose entries sit under `extension/`; the
   `[Content_Types].xml` and `extension.vsixmanifest` that Marketplace packages
   carry are not required.)
2. Replaces that copy with a symlink back into the repo. Once the id is
   registered the folder is no longer orphaned, and the symlink survives — which
   restores this repo's usual "edit the file, the live config changes" behavior.

Registration is skipped on later runs, so `./install.sh vscode` is cheap once the
theme is in place. The `.vsix` is staged under `$XDG_CACHE_HOME`, never `/tmp` —
a flatpak VS Code cannot read a host `/tmp` path, so a `.vsix` staged there would
be invisible to it.

Editing the theme therefore takes effect on the next VS Code window, with no
reinstall. Bumping the `version` in `package.json` does need a reinstall, since
the installed folder name embeds it.

> **Uninstalling the extension while VS Code is running deletes
> `workbench.colorTheme` from `settings.json`** — through the symlink, in the
> repo. VS Code strips the key rather than leave a dangling theme name. If your
> theme silently reverts to Dark Modern, check `git diff vscode/settings.json`.

Its syntax mapping is deliberately identical to `opencode/themes/muted-ink.json`,
so the same token is the same color in Neovim, opencode, and VS Code:

| Token | Color |
|-------|-------|
| comment | `dim` `#6b7280` *italic* |
| keyword | `purple` `#9a7eaa` |
| function | `bblue` `#7e9fbc` |
| string | `green` `#7a9b76` |
| number, type | `byellow` `#c7ae77` |
| operator | `teal` `#7aa2a5` |
| variable, punctuation | `fg` `#c9d1d9` |

The workbench is flat: `activityBar`, `sideBar`, `statusBar`, `titleBar`, `panel`
and both tab states all sit on `#0d1117`, separated by `#161b22` hairlines rather
than by contrasting fills. Teal `#7aa2a5` is the only accent — cursor, active
line number, active tab rule, focus border, buttons, progress.

Changing a color means editing every expression of the palette; the full list is
in [THEMES.md](THEMES.md).

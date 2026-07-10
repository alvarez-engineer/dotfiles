# Claude Code

The `claude` module installs two things:

| Repo file | Installed to | How |
|-----------|--------------|-----|
| `claude/statusline.sh` | `~/.claude/statusline.sh` | symlink |
| `claude/settings.json` | `~/.claude/settings.json` | **seeded once, never overwritten** |

```bash
./install.sh claude      # or: make install-claude
```

## Why settings.json is seeded, not symlinked

Every other module here ships a managed config and lets an untracked local file
load **last** so it wins: `~/.gitconfig.local`, `~/.bashrc.local`,
`~/.config/ghostty/local.ghostty`.

**Claude Code has no user-level local layer.** `settings.local.json` is
project-scoped, so whatever lands in `~/.claude/settings.json` is the whole story.

And that one file mixes two kinds of thing:

| Key | Kind |
|-----|------|
| `theme`, `model`, `effortLevel`, `attribution`, `statusLine` | portable preference |
| `enabledPlugins` | machine / account state |
| `skipDangerousModePermissionPrompt` | a **security posture** |

Symlinking it would put a permission-prompt bypass under version control, and into
any future public push. So the repo ships defaults for the portable half only, and
`claude/install.sh` seeds the file if it is absent and otherwise leaves it entirely
alone — the same contract as the `notes` module's `seed_file`. If the file already
exists, the installer prints what is missing rather than editing it.

`scripts/uninstall.sh` will not remove it either.

## theme: dark-ansi

Claude Code ships `dark`, `light`, `dark-daltonized`, `light-daltonized`,
`dark-ansi`, and `light-ansi`.

The first four paint themselves in hardcoded colors. **`dark-ansi` renders from
the host terminal's 16 ANSI colors** — which Ghostty and the VS Code integrated
terminal both map to `muted-ink`. One setting, and Claude Code is themed in both
hosts, with nothing to update when the palette moves.

That is also why `claude/statusline.sh` paints with the 16 ANSI escapes rather
than `muted-ink`'s hex codes. Hardcoding `#7aa2a5` there would look right in
exactly two terminals and wrong everywhere else.

## The status line

Claude Code passes session JSON on stdin and renders one line of stdout:

```text
~/projects/dotfiles on main ● · Opus 4.8 · ▓▓▓▓▓▓▓░░░ 68% ctx · $0.42 · +156/-42 · 12m
```

Left to right, each segment omitting itself when its data is missing:

| Segment | Source | Color |
|---------|--------|-------|
| Directory | `workspace.current_dir` (`$HOME`→`~`) | cyan |
| Git branch + state | `git` in that dir: branch, `●` when dirty, `↑n`/`↓n` vs upstream | yellow / red / dim |
| Model | `model.display_name` | blue |
| **Context bar** | newest `message.usage` in `transcript_path` over the window (200k, or 1M when `exceeds_200k_tokens`) | green <60%, yellow <85%, red above |
| Session cost | `cost.total_cost_usd` | magenta |
| Lines changed | `cost.total_lines_added` / `_removed` | green / red |
| Duration | `cost.total_duration_ms` | dim |

The context bar is the one field Claude Code does **not** hand over directly: the
script reads the last ~200 KB of the transcript JSONL, scans backward for the most
recent assistant message's token `usage`, and sizes the bar from that. Any failure
(no transcript, unparseable line) just drops the segment.

It degrades to `$PWD` when the JSON is unparseable, falls back to a dir/branch/model
line when `python3` is unavailable, and never exits non-zero — a status line must
not be able to break the prompt.

**Glyphs are ASCII by default.** A pipe cannot detect the rendering font, so
powerline glyphs are opt-in — `export DOTFILES_STATUSLINE_GLYPHS=nerd` swaps the
`·`/`on` separators for powerline glyphs; anything else stays ASCII. `bootstrap.sh`
installs JetBrainsMono Nerd Font Mono so the glyphs resolve in VS Code's terminal
(Ghostty renders them regardless); see [Fonts](FONTS.md).

`statusLine.command` gets an **absolute** path baked in at seed time. A leading `~`
is not reliably expanded there, and the seeded file is a copy, so rewriting it is
safe.

## One window: Claude Code inside VS Code

Claude Code has real IDE integration — the CLI binary carries `anthropic.claude-code`,
`autoConnectIde`, `diffTool`, `CLAUDE_CODE_SSE_PORT`, and a `/ide` command.

Install the extension and run `claude` from VS Code's integrated terminal, and its
diffs open as **native editor tabs** instead of scrolling past in the terminal:

```bash
code --install-extension anthropic.claude-code
```

Reviewing what the agent changed and inspecting files become the same activity, in
one surface. Run Claude Code in Ghostty instead and the diffs are gone when they
scroll.

> The integrated terminal must be a **host** shell for this to work at all — a
> flatpak VS Code sandbox has no `claude` on `PATH`. `vscode/bin/dev-shell` handles
> that; see [VSCODE.md](VSCODE.md).

## Layout

With `workbench.panel.defaultLocation: "right"`, one VS Code window gives you all
three things at once:

```text
┌──────────┬──────────────────┬───────────────┐
│ Explorer │  editor + diffs  │ claude  shell │
│  (files) │                  │  (tmux panes) │
└──────────┴──────────────────┴───────────────┘
```

Split the terminal panel to keep Claude Code and a shell side by side. Because
`dev-shell` attaches a tmux session named for the project, the same session is
reachable from Ghostty with `tmux attach -t <dir>` — closing VS Code does not kill
the conversation, and switching windows costs no state.

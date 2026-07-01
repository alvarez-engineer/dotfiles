# Ghostty Community Cheatsheet

This is an aggregation of practical Ghostty patterns seen across Reddit, GitHub Discussions, dotfiles, and the official docs. Treat this as a menu of ideas, not a strict standard.

This repo intentionally keeps the default setup conservative: one dark muted theme, a cross-platform config path, optional bash/zsh prompt snippets, and optional Starship. Most community setups get their power from the shell stack around Ghostty rather than from Ghostty config alone.

## High-signal takeaways

1. **Keep Ghostty small and predictable.** Many users like Ghostty because a useful config can stay short. Put terminal behavior in Ghostty, coding context in the shell prompt, and project/session behavior in tools like `tmux`, `zellij`, `sesh`, `fzf`, or `zoxide`.
2. **Use a Nerd Font, but debug the exact font family name.** If glyphs or icons do not render, verify the font family as Ghostty sees it instead of guessing the name.
3. **Use muted themes with matching editor colors.** Community theme discussions repeatedly run into the same issue: terminal, prompt, editor, and multiplexer themes should not fight each other.
4. **Prefer optional prompt modules over noisy prompts.** Git branch/status, Python environment, exit code, and command duration are usually useful. Kubernetes, cloud profile, Docker context, and Terraform workspace are useful only when they can change behavior or billing.
5. **Use Ghostty shell integration.** It enables quality-of-life features like prompt-aware close behavior, working-directory inheritance, prompt jumping, prompt selection, and better redraw behavior.
6. **Do not blindly install random dotfiles.** Use community configs as examples, then copy the small pieces you understand.

## Things people commonly add

### 1. Git-aware prompt

Use this when coding in many repos.

Useful prompt fields:

- current directory
- current Git branch
- dirty files: `*`
- staged files: `+`
- untracked files: `?`
- ahead/behind upstream: `↑N` / `↓N`
- previous command exit status
- active Python virtualenv or Conda env

Already included in this repo:

```bash
./install.sh shell
```

Files:

```text
shell/prompt/bash_prompt.sh
shell/prompt/zsh_prompt.zsh
shell/starship.toml
```

### 2. Starship for richer coding context

Common community stack:

```text
Ghostty + Starship + zoxide + eza + fzf + bat + ripgrep
```

Good Starship modules for coding:

| Module | Keep? | Reason |
|---|---:|---|
| directory | yes | orientation |
| git_branch | yes | repo context |
| git_status | yes | uncommitted work |
| python | yes | virtualenv visibility |
| nodejs | optional | useful in JS/TS repos |
| package | optional | useful when jumping between packages |
| cmd_duration | yes | catches slow commands |
| status | yes | failed command visibility |
| docker_context | optional | useful only when context changes |
| kubernetes | off by default | high value but dangerous/noisy if always shown |
| aws/gcloud/azure | off by default | high value but privacy/noise risk |
| terraform | optional | useful when workspace matters |
| nix_shell | optional | useful in Nix workflows |
| direnv | optional | useful when environment auto-loads |

This repo keeps the default prompt low-noise and documents optional Starship modules in `docs/PROMPT.md`.

### 3. Fuzzy config switching

A recurring community pattern is using `fzf` to switch themes, fonts, or config snippets without manually editing config files.

This repo has a simple profile switcher already:

```bash
./ghostty/use-profile.sh macos
./ghostty/use-profile.sh linux
./ghostty/use-profile.sh minimal
```

Optional local helper:

```bash
ghostty-profile-fzf() {
  local repo="$HOME/path/to/ghostty-cross-platform-config"
  local profile
  profile=$(find "$repo/ghostty/profiles" -type f -name '*.ghostty' \
    | sed 's#.*/##; s#\.ghostty$##' \
    | sort \
    | fzf --prompt='ghostty profile> ') || return

  "$repo/ghostty/use-profile.sh" "$profile"
}
```

For a strict dark-only setup, use this for profile switching, not theme switching.

### 4. Session switching

Common setups use Ghostty as the terminal surface and let another tool handle sessions:

- `zellij` for a modern terminal workspace
- `tmux` for persistent local/remote sessions
- `sesh` + `fzf` for fuzzy switching between project sessions
- `zoxide` for fast directory jumping

Recommended pattern:

```text
Ghostty window/tab → zellij or tmux session → editor/test/server panes
```

Good coding session layout:

```text
left: editor
right top: test watcher
right bottom: server/logs
floating/scratch: git, fzf, yazi, one-off commands
```

### 5. Terminal file navigation

Common tools people pair with Ghostty:

| Tool | Use |
|---|---|
| `zoxide` | smarter `cd` |
| `fzf` | fuzzy file/history/session picker |
| `eza` | readable `ls` replacement |
| `bat` | readable `cat` replacement |
| `ripgrep` | fast code search |
| `fd` | fast file search |
| `yazi` | terminal file manager |
| `bottom` / `btm` | process/system monitor |
| `lazygit` | terminal Git UI |
| `delta` | better Git diffs |
| `fastfetch` | system info / quick visual check |

Minimal install ideas:

macOS:

```bash
brew install starship zoxide fzf eza bat ripgrep fd yazi bottom lazygit git-delta
```

Debian/Ubuntu package names vary, but a useful baseline is:

```bash
sudo apt update
sudo apt install fzf ripgrep fd-find bat zoxide
```

Arch:

```bash
sudo pacman -S starship zoxide fzf eza bat ripgrep fd yazi bottom lazygit git-delta
```

### 6. Font debugging

If a font name does not work, list fonts the way Ghostty sees them:

```bash
ghostty +list-fonts
```

Filter a family:

```bash
ghostty +list-fonts --family "JetBrainsMono Nerd Font"
```

Then copy the exact family name into `local.ghostty`:

```ghostty
font-family = JetBrainsMono Nerd Font
```

Recommended approach:

1. Install one Nerd Font.
2. Verify it with `ghostty +list-fonts`.
3. Set it in `local.ghostty`.
4. Restart or reload Ghostty.
5. Test prompt glyphs.

### 7. Shell integration

Ghostty can auto-inject shell integration for common shells including bash, zsh, fish, nushell, and elvish. If it is working, Ghostty can understand prompt boundaries and working directories.

Useful shell-integration features:

- new tabs/splits can inherit the previous working directory
- close confirmation can be smarter when the shell is idle
- complex prompts redraw better on resize
- prompt jumping can work through command history
- prompt output selection becomes easier
- click-to-move can work at prompts when prompt marking is available

For bash, source the integration early when needed:

```bash
if [ -n "${GHOSTTY_RESOURCES_DIR:-}" ]; then
  builtin source "${GHOSTTY_RESOURCES_DIR}/shell-integration/bash/ghostty.bash"
fi
```

For zsh:

```zsh
if [[ -n "${GHOSTTY_RESOURCES_DIR:-}" ]]; then
  source "${GHOSTTY_RESOURCES_DIR}/shell-integration/zsh/ghostty-integration"
fi
```

Put these before heavy prompt frameworks when troubleshooting.

### 8. Keybindings people tend to care about

Keep keybinds boring and memorable.

Useful actions to bind or learn:

- new tab
- new split right/down
- focus split left/right/up/down
- resize split
- next/previous tab
- reload config
- open command palette
- jump to previous/next prompt
- clear screen
- reset font size

Ghostty also has a command palette, so rarely used actions do not always need permanent keybindings.

### 9. Command palette habit

Use the command palette for actions you need occasionally but do not want to memorize.

Defaults documented by Ghostty:

```text
macOS: cmd+shift+p
Linux/GTK: ctrl+shift+p
```

Good command-palette actions to search for:

- split
- tab
- move tab
- reload config
- font size
- reset
- prompt jump

### 10. Shaders and visual effects

People experiment with Ghostty shaders for retro CRT effects, animated backgrounds, and ricing. Keep these opt-in.

Practical guidance:

- do not enable shaders in the shared base config
- put shaders in `local.ghostty`
- expect platform-specific behavior, especially on Linux/Wayland/GPU-driver combinations
- avoid shaders during interviews, pair programming, screen sharing, and long coding sessions

Optional local-only example:

```ghostty
# local.ghostty only
# custom-shader = shaders/example.glsl
```

### 11. Dotfile management

Common ways to manage this repo across machines:

| Tool | Fit |
|---|---|
| `git` only | simplest |
| GNU `stow` | good for dotfiles symlinks |
| `chezmoi` | best if machines need templates/secrets/conditions |
| Nix / home-manager | best for NixOS or deeply reproducible systems |

This repo's installer is intentionally plain shell so it can work before adopting a larger dotfiles framework.

### 12. tmux/zellij caveats

Ghostty provides tabs/splits, but many developers still use tmux or zellij because sessions can survive terminal restarts or SSH disconnects.

Reasonable rule:

- use Ghostty tabs/splits for local, temporary layouts
- use tmux/zellij for project sessions, remote work, and long-running processes

Watch for these issues:

- keybinding conflicts between Ghostty and tmux/zellij
- URL detection or mouse behavior can differ inside multiplexers
- terminal type/terminfo may need setup on remote hosts
- nested prompts can get visually noisy

### 13. macOS privacy prompts

On macOS, tools that scan directories through `fzf`, session managers, or shell startup scripts can trigger permission prompts. If the prompt is caused by normal terminal workflows, review whether Ghostty needs broader file access in System Settings.

Do not grant broad access automatically. Grant it only when you understand which workflow requires it.

### 14. Linux packaging notes

Linux packaging varies by distribution. Community reports often depend heavily on package source, desktop environment, Wayland/X11, GPU drivers, and GTK versions.

Troubleshooting checklist:

```bash
ghostty --version
ghostty +show-config
ghostty +validate-config --config-file ~/.config/ghostty/config.ghostty
ghostty +list-fonts
ghostty +list-themes --plain
ghostty +list-keybinds --plain
```

## Recommended coding display policy

Default prompt should show only information that changes coding decisions.

Show by default:

```text
directory, git branch, git status, upstream ahead/behind, Python env, last command failure
```

Show when useful:

```text
Node version, package version, command duration, direnv, Nix shell, Terraform workspace
```

Hide unless actively needed:

```text
Kubernetes context, cloud account/profile, Docker context, hostname, username, battery, time
```

Reason: cloud and cluster context are critical when active, but they add noise and can expose sensitive information during screenshots or screen sharing.

## Local-only examples

### Slight transparency

```ghostty
background-opacity = 0.96
background-blur = true
```

### Larger font for screen sharing

```ghostty
font-size = 15
window-padding-x = 10
window-padding-y = 10
```

### Dense coding layout

```ghostty
font-size = 12
window-padding-x = 4
window-padding-y = 4
```

### Enable prompt-aware cursor click-to-move

```ghostty
cursor-click-to-move = true
```

This works best when shell integration/prompt marking is working.

## Sources reviewed

Official/reference sources:

- Ghostty configuration reference: https://ghostty.org/docs/config/reference
- Ghostty shell integration docs: https://ghostty.org/docs/features/shell-integration
- Ghostty keybinding docs: https://ghostty.org/docs/config/keybind
- Ghostty release notes for command palette and newer application behavior: https://ghostty.org/docs/install/release-notes/1-2-0 and https://ghostty.org/docs/install/release-notes/1-3-0
- Ghostty Arch manual page, useful for CLI commands like `+list-fonts`, `+list-keybinds`, and `+list-themes`: https://man.archlinux.org/man/ghostty.1

Community sources and examples:

- r/Ghostty font troubleshooting discussions: https://www.reddit.com/r/Ghostty/comments/1l8q6z0/i_cant_get_ghostty_to_use_the_font_set_in_the/
- r/Ghostty theme/config generator discussions: https://www.reddit.com/r/Ghostty/comments/1sy3wny/built_a_live_theme_font_mixer_for_ghostty_16/
- r/Ghostty config sharing thread: https://www.reddit.com/r/Ghostty/comments/1loux3c/share_your_ghostty_config/
- r/commandline Ghostty + Starship + zoxide + eza setup: https://www.reddit.com/r/commandline/comments/1rp9i2f/my_terminal_setup_with_ghostty_starship_zoxide/
- r/commandline terminal-feature discussion mentioning Ghostty tradeoffs: https://www.reddit.com/r/commandline/comments/1hpxpjl/in_2025_what_features_do_you_want_in_a_terminal/
- r/unixporn Ghostty setups with zellij, shaders, and ricing examples: https://www.reddit.com/r/unixporn/search/?q=ghostty
- Ghostty GitHub Discussion #3527, fzf config switching: https://github.com/ghostty-org/ghostty/discussions/3527
- Ghostty GitHub Discussion #3577, fzf theme browsing workaround: https://github.com/ghostty-org/ghostty/discussions/3577
- Ghostty GitHub Discussion #3358, session manager workflow: https://github.com/ghostty-org/ghostty/discussions/3358
- Ghostty GitHub Discussion #4496, macOS permissions and fzf/session tools: https://github.com/ghostty-org/ghostty/discussions/4496
- Ghostty GitHub Discussion #9057, shader/platform troubleshooting example: https://github.com/ghostty-org/ghostty/discussions/9057

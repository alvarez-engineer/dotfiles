# CLI tools module

Configuration and theming for the "modern Unix" command-line stack.

## bat

- `cli/bat/config` → `~/.config/bat/config`: uses the `muted-ink` theme, shows
  line numbers + git changes, italic text, 2-space tabs.
- `cli/bat/themes/muted-ink.tmTheme` → `~/.config/bat/themes/`: the syntax theme.

After installing, the module runs `bat cache --build` so bat sees the custom
theme. bat is also wired up as the man pager (see `shell/exports.sh`), and
`cat` is aliased to `bat --paging=never`.

> The same `muted-ink.tmTheme` is reused by git-delta via
> `syntax-theme = muted-ink`, so diffs and `bat` output match.

## ripgrep

- `cli/ripgrep/ripgreprc` → `~/.config/ripgrep/ripgreprc`, activated by
  `RIPGREP_CONFIG_PATH` (set in `shell/exports.sh`).
- Searches hidden files, skips `.git`, smart-case, muted-ink match colors.

ripgrep also powers Telescope's file and grep pickers in Neovim.

## fzf

fzf has no config file — it's configured through environment variables in
`shell/exports.sh`:

- `FZF_DEFAULT_OPTS` — muted-ink colors, reverse layout, rounded border.
- `FZF_DEFAULT_COMMAND` / `FZF_CTRL_T_COMMAND` — use ripgrep for file lists.

Key bindings (`Ctrl-T`, `Ctrl-R`, `Alt-C`) are loaded by the shell rc files when
fzf is installed. The `fkill` function (in `functions.sh`) uses fzf to pick a
process to kill.

## eza

Not configured via files — the `ls`/`ll`/`la`/`lt` aliases in `shell/aliases.sh`
use `eza` when present and fall back to coloured `ls` otherwise.

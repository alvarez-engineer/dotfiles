# Themes

This repo ships one custom theme:

- `muted-ink`

**[Open the preview](muted-ink-preview.html)** to see it: a mock VS Code workbench,
the palette, the ANSI strip, and the syntax token table. It is a standalone HTML file
with no external assets — open it straight from disk, there is nothing to build.

The palette is defined in:

```text
ghostty/themes/muted-ink
```

Ghostty searches the `themes/` subdirectory of the Ghostty config directory before built-in themes.

Every other tool **re-expresses** that palette in its own format, so changing a
color means editing each of these:

```text
ghostty/themes/muted-ink                                   the palette itself
nvim/colors/muted-ink.lua
nvim/lua/plugins/lualine.lua
cli/bat/themes/muted-ink.tmTheme                           also git-delta's syntax-theme
git/gitconfig                                              the [delta] block
tmux/tmux.conf                                             status colors
cli/ripgrep/ripgreprc                                      --colors
shell/exports.sh                                           FZF_DEFAULT_OPTS
opencode/themes/muted-ink.json
vscode/extensions/muted-ink/themes/muted-ink-color-theme.json
```

The opencode and VS Code themes share one token→color table on purpose — a
comment is `dim` italic and a keyword is `purple` in both, as in Neovim. Keep
them in step.

## Design goal

`muted-ink` is dark-only. It uses:

- near-black background
- soft gray foreground
- muted blue/green accents
- low-glare red/yellow warnings
- restrained selection and split colors

The goal is coding comfort, not a bright neon terminal.

## Change theme

In `local.ghostty`:

```ghostty
theme = muted-ink
```

or use a built-in theme:

```ghostty
theme = Catppuccin Frappe
```

## List themes

```bash
ghostty +list-themes
```

## Theme safety

A Ghostty theme file uses the same syntax as the main config and can set many configuration options. Avoid random theme files unless you trust the source. This repo's theme only sets colors and contrast.

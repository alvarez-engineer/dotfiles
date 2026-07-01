# Themes

This repo ships one custom theme:

- `muted-ink`

It lives in:

```text
ghostty/themes/muted-ink
```

Ghostty searches the `themes/` subdirectory of the Ghostty config directory before built-in themes.

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

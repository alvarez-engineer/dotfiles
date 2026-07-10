# Fonts

This repo uses **JetBrainsMono Nerd Font Mono** — plain JetBrains Mono's letterforms
plus the Powerline/branch/icon glyphs, forced to a single cell so columns never
shift. `scripts/bootstrap.sh` installs it (rootless: it fetches the pinned Nerd Fonts
release into `~/.local/share/fonts` when no package provides it), and both
`ghostty/config.ghostty` and `vscode/settings.json` name it first, falling back to
plain JetBrains Mono.

It buys one thing over plain JetBrains Mono: the glyphs. Ghostty renders them with
or without it (it embeds JetBrains Mono and has a built-in Nerd Font symbol
fallback), but **VS Code's integrated terminal needs a real Nerd Font installed** —
without one, the claude status line's opt-in glyph mode
(`DOTFILES_STATUSLINE_GLYPHS=nerd`, see [Claude Code](CLAUDE_CODE.md)) tofu-boxes.

Verify it registered:

```bash
fc-match "JetBrainsMono Nerd Font Mono" family    # should echo the family back
```

## Check available fonts

```bash
ghostty +list-fonts
```

## Recommended developer fonts

Good options:

- JetBrains Mono
- Berkeley Mono
- SF Mono on macOS
- Monaspace
- Iosevka
- Fira Code
- Cascadia Code

## Use a font override

Add this to `local.ghostty`:

```ghostty
font-family = JetBrains Mono
font-size = 13
```

Or:

```ghostty
font-family = Monaspace Neon
font-size = 14
```

## Fallbacks

Ghostty supports repeated `font-family` entries for fallbacks. Keep the shared config simple; add specialized language or icon fallback fonts in `local.ghostty` only when needed.

Example:

```ghostty
font-family = JetBrains Mono
font-family = Noto Color Emoji
font-family = Symbols Nerd Font Mono
```

## Ligatures

This repo leaves ligatures as font defaults. To disable common programming ligatures:

```ghostty
font-feature = -calt
font-feature = -liga
font-feature = -dlig
```

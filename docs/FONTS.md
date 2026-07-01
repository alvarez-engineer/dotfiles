# Fonts

Ghostty includes a strong default font baseline, so this repo uses JetBrains Mono.

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

# macOS setup

## Install Ghostty

Preferred options:

```bash
brew install --cask ghostty
```

or download the official `.dmg` from Ghostty's website and drag the app into `/Applications`.

## Install this config

```bash
git clone <your-repo-url> ghostty-config
cd ghostty-config
./scripts/install.sh --profile macos
./scripts/install-prompt.sh --shell zsh
```

The repo installs to:

```text
~/.config/ghostty/config.ghostty
```

macOS also supports:

```text
~/Library/Application Support/com.mitchellh.ghostty/config.ghostty
```

This repo intentionally uses the XDG path because it works on both macOS and Linux.

## Reload

In Ghostty:

```text
cmd+shift+,
```

or restart the app.

Restart the shell after installing the prompt, or run:

```zsh
source ~/.zshrc
```

## Quick terminal permission

The macOS profile includes:

```ghostty
keybind = global:cmd+backquote=toggle_quick_terminal
```

Global keybinds require Accessibility permission:

```text
System Settings → Privacy & Security → Accessibility → Ghostty
```

If the shortcut conflicts with another app, override it in `local.ghostty`.

## Recommended local overrides

For laptop display:

```ghostty
font-size = 13
window-padding-x = 8
window-padding-y = 6
```

For external monitor:

```ghostty
font-size = 14
window-width = 132
window-height = 40
```

For fully opaque windows:

```ghostty
background-opacity = 1
background-blur = false
```

## macOS notes

- `macos-titlebar-style = transparent` gives a native-looking window while keeping standard window behavior.
- `macos-option-as-alt = true` makes Option work as Alt in terminal applications.
- The quick terminal uses one global instance and does not restore like normal terminal windows.
- The default macOS shell is usually zsh, so `install-prompt.sh --shell zsh` is the safest explicit option.

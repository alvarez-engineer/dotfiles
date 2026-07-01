# Keybindings

## Main shared bindings

| Shortcut | Action |
|---|---|
| `ctrl+shift+r` | Reload config |
| `ctrl+shift+o` | Open config |
| `ctrl+shift+c` | Copy |
| `ctrl+shift+v` | Paste |
| `ctrl+shift+n` | New window |
| `ctrl+shift+t` | New tab |
| `ctrl+shift+w` | Close surface |
| `ctrl+shift+left/right` | Previous/next tab |
| `ctrl+shift+enter` | Split right |
| `ctrl+shift+backslash` | Split down |
| `ctrl+shift+z` | Toggle split zoom |
| `ctrl+shift+e` | Equalize splits |
| `ctrl+shift+f` | Search |
| `ctrl+shift+up/down` | Jump to previous/next shell prompt |
| `ctrl+shift+equal/minus/zero` | Font size up/down/reset |
| `ctrl+shift+p` | Command palette |
| `ctrl+shift+u` | Open scrollback in editor |
| `ctrl+shift+backspace` | Clear screen and scrollback |

## macOS overlay bindings

| Shortcut | Action |
|---|---|
| `cmd+backquote` | Toggle quick terminal globally |
| `cmd+t` | New tab |
| `cmd+n` | New window |
| `cmd+w` | Close surface |
| `cmd+shift+r` | Reload config |
| `cmd+shift+o` | Open config |
| `cmd+shift+f` | Search |
| `cmd+shift+p` | Command palette |
| `cmd+enter` | Toggle split zoom |
| `cmd+d` | Split right |
| `cmd+shift+d` | Split down |
| `cmd+left/right` | Previous/next tab |

## Linux overlay bindings

| Shortcut | Action |
|---|---|
| `ctrl+grave` | Toggle quick terminal |

## Inspect current keybinds

```bash
ghostty +list-keybinds
```

Default keybinds:

```bash
ghostty +list-keybinds --default
```

## Disable a binding

In `local.ghostty`:

```ghostty
keybind = ctrl+shift+u=unbind
```

## Add a tmux-oriented binding

Example for sending tmux prefix plus `z` to zoom a pane, assuming prefix is `ctrl+a`:

```ghostty
keybind = cmd+b=text:\x01\x7a
```

Keep these in `local.ghostty` because tmux prefixes are personal.

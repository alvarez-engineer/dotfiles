# Linux setup

## Install Ghostty

Install method depends on your distro. Common options from Ghostty's install docs:

```bash
# Arch
sudo pacman -S ghostty

# Alpine testing repository
sudo apk add ghostty

# Gentoo
sudo emerge -av ghostty

# Snap
sudo snap install ghostty --classic

# Void
sudo xbps-install ghostty
```

Fedora, Debian, Ubuntu, and AppImage options may use community-maintained packages. Prefer distro repositories when available, and review trust boundaries before using community binary repositories.

## Install this config

```bash
git clone <your-repo-url> dotfiles
cd dotfiles
./install.sh ghostty shell     # Linux profile is auto-detected
```

To force a specific Ghostty profile later: `./ghostty/use-profile.sh linux`.

The installed path is:

```text
${XDG_CONFIG_HOME:-$HOME/.config}/ghostty/config.ghostty
```

## Reload

In Ghostty:

```text
ctrl+shift+,
```

or restart Ghostty.

Restart the shell after installing the prompt, or run one of:

```bash
source ~/.bashrc
source ~/.zshrc
```

## Wayland / quick terminal notes

The Linux profile includes:

```ghostty
keybind = ctrl+grave=toggle_quick_terminal
quick-terminal-position = top
quick-terminal-size = 45%
```

Quick terminal support depends on Wayland and compositor support. On some desktop environments, the keybind may work only when Ghostty has focus, or the compositor may need its own global shortcut binding.

## GTK notes

The Linux overlay uses GTK-oriented settings:

```ghostty
gtk-titlebar = true
gtk-tabs-location = top
gtk-wide-tabs = false
```

If these cause issues on your build, switch to the minimal profile:

```bash
./ghostty/use-profile.sh minimal
```

## Recommended local overrides

For tiling window managers:

```ghostty
window-decoration = none
background-opacity = 1
```

For KDE with blur enabled:

```ghostty
background-opacity = 0.90
background-blur = true
```

For low-memory systems:

```ghostty
scrollback-limit = 33554432
```

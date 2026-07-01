# Troubleshooting

## Run the doctor script

```bash
make doctor
```

## Validate config

```bash
make validate
```

or:

```bash
ghostty +validate-config --config-file ~/.config/ghostty/config.ghostty
```

## Config is not loading

Check paths:

```bash
./scripts/print-paths.sh
```

Preferred path:

```text
~/.config/ghostty/config.ghostty
```

On macOS, Ghostty may also load Application Support config files after XDG files, with later conflicting values overriding earlier values. If behavior is unexpected, check both locations.

## A setting is not changing after reload

Some settings require new windows or a full restart. Examples include platform/window behavior, some transparency settings, and quick terminal settings.

Try:

1. Save config.
2. Reload config.
3. Open a new Ghostty window.
4. If still unchanged, fully quit and restart Ghostty.

## Fonts look wrong

Check available fonts:

```bash
ghostty +list-fonts
```

Then set a known font in `local.ghostty`:

```ghostty
font-family = JetBrains Mono
font-size = 14
```

## Git branch is not showing

The Git branch appears only when the shell prompt snippet is installed and the current directory is inside a Git worktree.

Check that the managed block exists in `~/.zshrc` or `~/.bashrc`:

```bash
grep -n "ghostty muted coding prompt" ~/.zshrc ~/.bashrc 2>/dev/null
```

Confirm the prompt files exist:

```bash
ls ~/.config/ghostty/shell/
```

Then restart the shell or source the relevant rc file:

```bash
source ~/.zshrc
source ~/.bashrc
```

## Prompt is slow

Likely causes:

- very large Git repository
- network filesystem
- expensive language/toolchain version checks
- Kubernetes/cloud context checks from a separate prompt framework

Use the no-dependency prompt for the fastest baseline. Keep Kubernetes, cloud profile, and Terraform workspace display disabled unless needed.

## Quick terminal does not work

macOS:

- Grant Accessibility permission to Ghostty.
- Check shortcut conflict with other apps.
- Restart Ghostty after changing quick terminal settings.

Linux:

- Prefer Wayland.
- Some compositors do not support the needed layer-shell behavior.
- Try using your compositor's global shortcut system to launch or focus Ghostty.

## Shell integration not working

Use manual shell sourcing from `docs/SHELL_INTEGRATION.md`.

Also check:

```bash
echo "$GHOSTTY_RESOURCES_DIR"
```

inside Ghostty.

## Revert to minimal profile

```bash
./scripts/use-profile.sh minimal
```

Then reload Ghostty.

## Fully reset this repo's install

```bash
rm -rf ~/.config/ghostty
./scripts/install.sh --profile minimal
```

Only do this after backing up your existing config.

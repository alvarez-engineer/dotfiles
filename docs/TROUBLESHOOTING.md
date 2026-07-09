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
./ghostty/print-paths.sh
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

The branch appears only inside a git worktree, and only once a prompt is active.
`~/.bashrc` / `~/.zshrc` use starship when it is installed and otherwise source
the bundled prompt from the repo — there is no "managed block" pasted into your
rc file, and no `~/.config/ghostty/shell/` directory.

Check which prompt you are getting:

```bash
command -v starship             # if present, starship owns the prompt
ls ~/projects/dotfiles/shell/prompt/   # the bundled fallback lives in the repo
```

Confirm the rc files are the managed symlinks, then restart the shell:

```bash
make doctor          # ~/.bashrc and ~/.zshrc should read "-> repo"
exec "$SHELL" -l     # or: reload
```

If starship is installed but the prompt looks unstyled, check
`STARSHIP_CONFIG` (set in `shell/exports.sh`) points at an existing
`~/.config/starship.toml`.

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
./ghostty/use-profile.sh minimal
```

Then reload Ghostty.

## Fully reset this repo's install

```bash
rm -rf ~/.config/ghostty
./install.sh ghostty
./ghostty/use-profile.sh minimal
```

Only do this after backing up your existing config.

## `ls somedir` lists the wrong directory

Fixed — but if you are running an old checkout, this is the symptom of a
fallback written *inside* the `ls` alias body. See
[SHELL.md](SHELL.md#the-ls-fallback-and-why-it-is-not-written-inside-the-alias).
Update and `reload`.

## Git ignores what I set in `~/.gitconfig.local`

The `[include]` in `git/gitconfig` must be the **last** line of the file, or the
settings above it win. Verify the value git actually resolves:

```bash
git config --show-origin --get core.editor
```

## `bdsplit` did not route anything

Routing is the "I'm finished" signal, so a dump with prose but **no markers** is
left in `inbox/` on purpose and reported as `skip:`. If the dump really is
finished and produced nothing worth routing, say that with `~` — it routes to
`optimizations.md` and the dump gets archived like any other. A dump holding
nothing but frontmatter is reported as `empty:` and archived without routing.

Check the grammar with:

```bash
bdsplit --dry-run     # prints every routing decision, changes nothing
```

Markers must start the line with at most 3 leading spaces (4+ is a markdown code
block). Lines inside ``` fences and in YAML frontmatter are ignored, as are the
checked `[x]` and `- [x]`. A dump already routed lives in `archive/<YYYY-MM>/` —
that is what makes re-running safe.

## `make check` passes but something is obviously broken

Each linter is *skipped when its binary is absent*, so a bare machine exits 0
having checked very little. Install the linters and re-run:

```bash
make bootstrap-dev    # shellcheck + luacheck
make check
```

Any script not listed in `SH_FILES` in the `Makefile` is never linted at all.

# Maintenance workflow

## Daily usage

Use the shared config as stable baseline. Put personal, machine-specific, or experimental Ghostty changes in `local.ghostty`.

```bash
cp ~/.config/ghostty/local.example.ghostty ~/.config/ghostty/local.ghostty
$EDITOR ~/.config/ghostty/local.ghostty
```

Prompt changes live in:

```text
shell/prompt/bash_prompt.sh
shell/prompt/zsh_prompt.zsh
shell/starship.toml
```

## Before committing changes

```bash
make check
make validate
make doctor
```

If `ghostty` is not installed in the environment where you are editing the repo, at least run:

```bash
bash -n scripts/*.sh
bash -n shell/prompt/bash_prompt.sh
find config -maxdepth 4 -type f -print
```

## Updating Ghostty

After upgrading Ghostty:

```bash
ghostty +version
ghostty +show-config --default --docs | less
ghostty +validate-config --config-file ~/.config/ghostty/config.ghostty
```

Review the official release notes for renamed, deprecated, or newly supported options.

## Adding a new profile

1. Add `ghostty/profiles/<name>.ghostty`.
2. Update `install.sh ghostty` and `ghostty/use-profile.sh` allowed profile list.
3. Document it in `README.md`.
4. Validate the selected profile after install.

## Changing the theme

1. Edit `ghostty/themes/muted-ink`.
2. Set only colors and contrast in the theme file.
3. Run:

```bash
ghostty +validate-config --config-file ~/.config/ghostty/config.ghostty
```

## Backup

```bash
make backup
```

Backups are written to `./backups/` and ignored by Git.

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
make check     # the gate: bash -n, zsh -n, shellcheck, luacheck
make doctor    # what is linked, what tools are missing
make validate  # ghostty +validate-config (only if the ghostty CLI is present)
```

`make check` is the one that matters, and it is safe to run anywhere: each
linter is skipped when its binary is absent, so it exits 0 on a bare machine
and runs in full in CI. If you add a new shell script, add it to `SH_FILES` in
the `Makefile` or it escapes the gate entirely.

Do **not** hand-roll a syntax check as `bash -n a b c` — bash parses only the
first argument and treats the rest as positional parameters, so the other files
are never checked. Loop, one file per invocation:

```bash
for f in scripts/*.sh notes/bin/*; do bash -n "$f" || break; done
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

## Adding a new module

A module is a top-level directory plus its own `install.sh`. To wire one in:

1. Create `<module>/install.sh`; source `lib/common.sh` and mutate the
   filesystem only through `link_file` / `run`, or `--dry-run` and `--copy`
   silently stop working.
2. Add it to `ALL_MODULES` in `install.sh` and to the `usage()` module line.
3. Add an `install-<module>` target and `.PHONY` entry in the `Makefile`.
4. If it ships shell scripts outside the existing globs, add them to `SH_FILES`.
5. Add its targets to `scripts/doctor.sh` and `scripts/uninstall.sh`, and any
   irreplaceable user files to `scripts/backup.sh`.
6. Document it in `README.md`, `CLAUDE.md`, and `docs/ARCHITECTURE.md`.

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

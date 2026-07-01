# Git module

A managed `~/.gitconfig` with sensible defaults, aliases, a muted-ink
[delta](https://github.com/dandavison/delta) pager, and a global ignore file.

## What gets installed

| Source (repo)            | Destination                 |
|--------------------------|-----------------------------|
| `git/gitconfig`          | `~/.gitconfig` (symlink)    |
| `git/gitignore_global`   | `~/.config/git/ignore`      |
| generated template       | `~/.gitconfig.local` (identity) |

## Identity lives in `~/.gitconfig.local`

The tracked `gitconfig` contains **no name or email** — it `[include]`s
`~/.gitconfig.local`, which the installer seeds with a template on first run:

```ini
[user]
	name = Your Name
	email = you@example.com
```

Edit that file (untracked) with your real identity, signing key, or per-machine
work overrides. This keeps personal data out of a public repo.

## Delta pager

`core.pager` is set to `delta || less`, so if delta isn't installed git quietly
falls back to `less`. When delta is present you get line-numbered, syntax-
highlighted diffs themed to muted-ink (it reuses bat's `muted-ink.tmTheme`).

## Selected defaults

- `init.defaultBranch = main`, `pull.ff = only`, `push.autoSetupRemote = true`
- `fetch.prune = true`, `rebase.autosquash/autostash = true`
- `merge.conflictstyle = zdiff3`, `diff.algorithm = histogram`

## Aliases

`st`, `co`, `sw`, `br`, `ci`, `ca`, `unstage`, `last`, `lg` (pretty graph),
`ll`, `amend`, `undo`, `aliases`. Run `git aliases` to list them. Matching
shell aliases (`gs`, `ga`, `gc`, …) live in `shell/aliases.sh`.

## Credential helpers

The GitHub/gist `gh auth git-credential` helpers are carried over from the
previous config so `gh`-based auth keeps working.

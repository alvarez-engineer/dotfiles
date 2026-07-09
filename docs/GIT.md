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
#	name = Your Name
#	email = you@example.com
```

The placeholders are **commented out on purpose.** A live `name = Your Name`
would not fail loudly; git would simply author every commit as
`Your Name <you@example.com>`. Left commented, git refuses to commit until you
supply a real identity — which is what you want on a machine you just set up.

Edit that file (untracked) with your real identity, signing key, or per-machine
work overrides. This keeps personal data out of a public repo.

### Why the `[include]` is the last line

Git applies an include *where it appears*, and for a single-valued key the last
value read wins. An `[include]` at the top of `gitconfig` would therefore be
overridden by everything below it: setting `core.editor` in `~/.gitconfig.local`
would silently lose to the `editor = nvim` in the tracked file. Keeping the
include last is what makes "local overrides win" actually true — the same
ordering `~/.bashrc.local` and `local.ghostty` rely on.

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

GitHub and gist auth go through `gh auth git-credential`, so `gh`-based login
keeps working. The helper invokes `gh` **by name, resolved through `PATH`** —
not by absolute path. Homebrew installs `gh` to `/opt/homebrew/bin` on Apple
Silicon and `/usr/local/bin` on Intel, so a hardcoded `/usr/bin/gh` works only
on Linux and fails at push time everywhere else.

If you do not use `gh`, you can ignore them — they stay inert until git actually
needs credentials for github.com. To remove them, edit `git/gitconfig`.

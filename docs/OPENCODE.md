# opencode module

[opencode](https://opencode.ai) is an open-source AI coding agent for the
terminal. This module manages its config and ships a muted-ink theme.

## What gets installed

| Source (repo)                    | Destination                                  |
|----------------------------------|----------------------------------------------|
| `opencode/opencode.json`         | `~/.config/opencode/opencode.json`           |
| `opencode/tui.json`              | `~/.config/opencode/tui.json`                |
| `opencode/themes/muted-ink.json` | `~/.config/opencode/themes/muted-ink.json`   |

Files are symlinked individually so opencode's own state — notably
`auth.json`, where credentials live — is never touched by this repo.

## Credentials are not in the repo

API keys are **not** stored in the config. Authenticate once:

```bash
opencode auth login          # stores keys under opencode's data dir, outside git
```

That keeps the tracked config safe to publish.

## Default model

`opencode.json` sets:

```json
{
  "model": "anthropic/claude-sonnet-4-6",
  "small_model": "anthropic/claude-haiku-4-5"
}
```

Sonnet is a good default for a coding agent; Haiku handles cheap background
tasks (titles, summaries). Prefer Opus? Change `model` to
`anthropic/claude-opus-4-6`, or switch interactively in the TUI with `/models`
(model ids resolve against the models.dev registry). To use a different
provider entirely, set `model` to `provider/model` and authenticate for it.

`permission` defaults to asking before edits and shell commands
(`"edit": "ask"`, `"bash": "ask"`) — loosen per project via an `opencode.json`
in the repo root.

## Theme

`tui.json` selects `"theme": "muted-ink"`, which resolves to
`themes/muted-ink.json`. The theme reuses the shared muted-ink palette (defined
once in `defs`, referenced by name) and sets `"background": "none"` so opencode
inherits the terminal background — matching Ghostty's translucency. It covers
the full schema: UI, diff, markdown, and syntax colors. Switch themes live with
`/theme`.

## Install

```bash
./install.sh opencode     # or: make install-opencode
```

`scripts/bootstrap.sh` installs the opencode binary itself (via the official
`curl | bash` installer on Linux, or `brew install opencode` on macOS).

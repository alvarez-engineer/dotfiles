# Coding prompt

Ghostty controls the terminal window. The shell controls the prompt. This repo includes prompt snippets so a fresh macOS or Linux machine can show useful coding context without requiring a full shell framework.

## Default prompt information

The included bash and zsh prompts show:

| Segment | Example | Purpose |
|---|---:|---|
| Current directory | `~/projects/app` | Keep orientation while moving through repos |
| Git branch | `git:main` | Avoid committing or deploying from the wrong branch |
| Modified files | `*` | Working tree has unstaged changes |
| Staged files | `+` | Index has staged changes |
| Untracked files | `?` | New files are not tracked |
| Ahead of upstream | `↑2` | Local commits have not been pushed |
| Behind upstream | `↓1` | Remote has commits not pulled locally |
| Python virtualenv | `py:.venv` | Shows active Python environment |
| Conda environment | `conda:base` | Shows active Conda environment |
| Exit status | `exit:1` | Last command failed |

Example:

```text
~/projects/api git:feature/auth*+?↑1 py:.venv
❯
```

## Install the no-dependency prompt

Install Ghostty config first:

```bash
./scripts/install.sh
```

Then install the shell prompt block:

```bash
./scripts/install-prompt.sh
```

Force a shell when needed:

```bash
./scripts/install-prompt.sh --shell zsh
./scripts/install-prompt.sh --shell bash
```

The script backs up `~/.zshrc` or `~/.bashrc` before editing it.

## Manual install

Bash:

```bash
source "${XDG_CONFIG_HOME:-$HOME/.config}/ghostty/shell/bash_prompt.sh"
```

Zsh:

```zsh
source "${XDG_CONFIG_HOME:-$HOME/.config}/ghostty/shell/zsh_prompt.zsh"
```

## Optional Starship prompt

Use Starship if you want more coding context and are comfortable with an external dependency.

Install Starship, then copy or symlink the included config:

```bash
mkdir -p ~/.config
ln -sf ~/.config/ghostty/shell/starship.toml ~/.config/starship.toml
```

Initialize Starship from your shell.

Bash:

```bash
eval "$(starship init bash)"
```

Zsh:

```zsh
eval "$(starship init zsh)"
```

The included Starship config adds:

- command duration for slow commands
- Node.js version when relevant
- Docker context when relevant
- optional Kubernetes context, disabled by default

## Other useful coding info

Recommended default-on:

- **Git branch/status**: high signal, low noise.
- **Exit status**: catches failed commands when logs scroll quickly.
- **Python virtualenv / Conda env**: prevents running migrations or installs in the wrong environment.
- **Command duration**: useful for tests, builds, and deploy commands; best handled by Starship or a shell framework.

Useful but usually default-off:

- **Node version**: useful in frontend repos, but can add prompt latency if implemented poorly.
- **Docker context**: useful when switching between local and remote Docker engines.
- **Kubernetes context/namespace**: high value but risky/noisy. Enable only if you work with clusters regularly. Use a warning color.
- **Terraform workspace**: useful for infrastructure repos, but should be repo-scoped.
- **AWS/GCP profile**: useful for cloud work, but can expose sensitive environment names in screenshots.
- **Current time**: useful for logs and pairing, but often visual noise.
- **Battery/network/VPN**: better suited to a system status bar than a terminal prompt.

## Prompt performance rules

Keep the default prompt fast:

- Avoid network calls.
- Avoid recursive repo scans.
- Avoid `git status --porcelain=v2 --branch` in very large repos unless cached.
- Keep Kubernetes/cloud metadata disabled unless needed.
- Put expensive language version checks behind file detection or use Starship.

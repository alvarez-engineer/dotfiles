# Shell integration

Ghostty shell integration and your shell prompt are related but separate.

- Ghostty shell integration helps the terminal understand prompts, working directories, cursor changes, and SSH terminfo.
- The shell prompt controls what text is displayed before each command.

This repo enables Ghostty shell integration and also includes optional bash/zsh prompt snippets in `config/shell/`.

## Ghostty integration

Ghostty can automatically inject shell integration for:

- bash
- elvish
- fish
- nushell
- zsh

The shared config uses:

```ghostty
shell-integration = detect
shell-integration-features = cursor,title,ssh-env,ssh-terminfo
```

## What this enables

- New tabs and splits can inherit the working directory.
- Prompt navigation can use `jump_to_prompt`.
- Prompt resizing behaves better.
- Closing a terminal at an idle prompt is less annoying.
- SSH terminfo handling is improved.
- Window title handling can follow the active shell context.

## Git branch prompt

To display the current Git branch and coding context, install the prompt block:

```bash
./scripts/install-prompt.sh
```

This sources one of:

```text
~/.config/ghostty/shell/bash_prompt.sh
~/.config/ghostty/shell/zsh_prompt.zsh
```

See [Coding prompt](PROMPT.md) for the full prompt behavior.

## Manual Ghostty shell integration

Automatic injection is enough for most users. Manual sourcing is useful if:

- you switch shells inside Ghostty;
- macOS `/bin/bash` fails automatic integration;
- you use custom shell launch wrappers;
- you use `nix-shell` or development shells.

### Bash

Add near the top of `~/.bashrc`:

```bash
if [ -n "${GHOSTTY_RESOURCES_DIR:-}" ]; then
  builtin source "${GHOSTTY_RESOURCES_DIR}/shell-integration/bash/ghostty.bash"
fi
```

### Zsh

Add near the top of `~/.zshrc`:

```zsh
if [[ -n "${GHOSTTY_RESOURCES_DIR:-}" ]]; then
  source "${GHOSTTY_RESOURCES_DIR}/shell-integration/zsh/ghostty-integration"
fi
```

### Fish

Add to `~/.config/fish/config.fish`:

```fish
if set -q GHOSTTY_RESOURCES_DIR
    source "$GHOSTTY_RESOURCES_DIR/shell-integration/fish/vendor_conf.d/ghostty-shell-integration.fish"
end
```

## Disable Ghostty shell integration

In `local.ghostty`:

```ghostty
shell-integration = none
```

Or disable only cursor changes:

```ghostty
shell-integration-features = no-cursor,title,ssh-env,ssh-terminfo
```

## Disable this repo's prompt

Remove the managed block from `~/.zshrc` or `~/.bashrc`:

```text
# >>> ghostty muted coding prompt >>>
...
# <<< ghostty muted coding prompt <<<
```

Then restart the shell.

## Troubleshooting

If Ghostty logs show `ghostty terminfo not found, using xterm-256color`, inspect whether Ghostty was installed correctly and whether `GHOSTTY_RESOURCES_DIR` points to a valid resources directory.

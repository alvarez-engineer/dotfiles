# tmux module

A single themed `tmux.conf` installed to `~/.config/tmux/tmux.conf` (tmux ≥ 3.1
reads it there natively — no `~/.tmux.conf` needed).

## Key bindings

Prefix is remapped to **`Ctrl-a`** (press `Ctrl-a` then the key). `Ctrl-b` is
unbound.

| Binding        | Action                              |
|----------------|-------------------------------------|
| `prefix` `\|`   | Split vertically (keep cwd)         |
| `prefix` `-`   | Split horizontally (keep cwd)       |
| `prefix` `c`   | New window (keep cwd)               |
| `prefix` `h/j/k/l` | Move between panes (vim-style)  |
| `prefix` `H/J/K/L` | Resize panes (repeatable)       |
| `prefix` `Enter`   | Enter copy mode                 |
| `v` / `y` (copy mode) | Begin selection / yank       |
| `prefix` `r`   | Reload the config                   |

## Behaviour

- Mouse mode on; vi-style copy mode; `set-clipboard on`.
- Windows/panes are 1-indexed and renumber on close.
- 50k line history, fast escape time, focus events, and truecolor overrides
  (`Tc`) including `xterm-ghostty`.

## Theme

The status line uses the muted-ink palette: teal session badge, dim inactive
windows, a `#263241` highlight for the active window, teal active pane borders,
and a `^A` indicator when the prefix is pressed.

## Install / reload

```bash
./install.sh tmux      # or: make install-tmux
```

Inside a running tmux, reload with `prefix` + `r`.

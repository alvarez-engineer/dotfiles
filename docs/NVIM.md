# Neovim module

A deliberately small, fast Neovim config built on
[lazy.nvim](https://github.com/folke/lazy.nvim). Symlinked to `~/.config/nvim`.

## Layout

```text
nvim/
├── init.lua                 # leader + requires
├── lua/config/
│   ├── options.lua          # editor options
│   ├── keymaps.lua          # non-plugin key maps
│   └── lazy.lua             # bootstrap + plugin loading + colorscheme
├── lua/plugins/
│   ├── treesitter.lua       # syntax/indent/textobjects
│   ├── telescope.lua        # fuzzy finder (uses ripgrep)
│   ├── gitsigns.lua         # gutter git signs + hunk nav
│   └── lualine.lua          # statusline (muted-ink theme)
└── colors/muted-ink.lua     # colorscheme
```

## First launch

Run `nvim` once. lazy.nvim clones itself, installs the plugins, and treesitter
compiles its parsers. Manage plugins with `:Lazy`, parsers with `:TSUpdate`.
Plugin versions are pinned in `nvim/lazy-lock.json` (tracked in the repo).

## Defaults worth knowing

- **Leader** is `Space`.
- 2-space indent, relative + absolute line numbers, `cursorline`, true colors.
- System clipboard (`unnamedplus`), persistent undo, no swapfiles.
- Search is case-smart; `<Esc>` clears highlight.

## Key maps (leader = Space)

| Keys          | Action                          |
|---------------|---------------------------------|
| `<leader>ff`  | Find files (Telescope)          |
| `<leader>fg`  | Live grep                       |
| `<leader>fb`  | Buffers                         |
| `<leader>fr`  | Recent files                    |
| `<leader>/`   | Fuzzy search current buffer     |
| `]h` / `[h`   | Next / previous git hunk        |
| `<leader>hs/hr/hp` | Stage / reset / preview hunk |
| `<C-h/j/k/l>` | Move between splits             |
| `J` / `K` (visual) | Move selected lines          |
| `<leader>w` / `<leader>q` | Save / quit          |

## Extending

Add a file under `lua/plugins/` returning a lazy.nvim spec table; it's picked up
automatically. Keep it minimal — this config is meant to boot fast and stay
legible. For a full IDE (LSP, completion, DAP) build on top deliberately.

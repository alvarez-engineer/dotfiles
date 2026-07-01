-- Managed Neovim config — symlinked from the dotfiles repo (nvim module).
-- Minimal & tasteful: sane defaults, a few QoL plugins, muted-ink theme.
-- Leader must be set before lazy.nvim loads.
vim.g.mapleader = " "
vim.g.maplocalleader = " "

require("config.options")
require("config.keymaps")
require("config.lazy")

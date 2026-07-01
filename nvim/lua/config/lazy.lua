-- Bootstrap lazy.nvim (plugin manager) and load plugin specs from lua/plugins/.
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local repo = "https://github.com/folke/lazy.nvim.git"
  local out = vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", repo, lazypath })
  if vim.v.shell_error ~= 0 then
    vim.api.nvim_echo({
      { "Failed to clone lazy.nvim:\n", "ErrorMsg" },
      { out, "WarningMsg" },
      { "\nInstall git and restart Neovim.", nil },
    }, true, {})
    return
  end
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
  spec = { { import = "plugins" } },
  install = { colorscheme = { "muted-ink", "habamax" } },
  checker = { enabled = false },      -- don't auto-check for updates
  change_detection = { notify = false },
  ui = { border = "rounded" },
})

-- Apply the local colorscheme (colors/muted-ink.lua). Fall back gracefully.
pcall(vim.cmd.colorscheme, "muted-ink")

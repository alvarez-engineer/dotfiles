-- Syntax-aware highlighting, indentation, and text objects.
return {
  "nvim-treesitter/nvim-treesitter",
  build = ":TSUpdate",
  event = { "BufReadPost", "BufNewFile" },
  main = "nvim-treesitter.configs",
  opts = {
    ensure_installed = {
      "bash", "c", "lua", "luadoc", "vim", "vimdoc", "query",
      "json", "yaml", "toml", "markdown", "markdown_inline",
      "python", "javascript", "typescript", "tsx", "html", "css",
      "go", "rust", "gitcommit", "diff", "dockerfile",
    },
    auto_install = true,
    highlight = { enable = true },
    indent = { enable = true },
    incremental_selection = {
      enable = true,
      keymaps = {
        init_selection = "<CR>",
        node_incremental = "<CR>",
        node_decremental = "<BS>",
      },
    },
  },
}

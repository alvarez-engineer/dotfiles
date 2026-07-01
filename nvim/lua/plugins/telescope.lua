-- Fuzzy finder for files, buffers, grep, help, etc.
return {
  "nvim-telescope/telescope.nvim",
  cmd = "Telescope",
  dependencies = { "nvim-lua/plenary.nvim" },
  keys = {
    { "<leader>ff", "<cmd>Telescope find_files<CR>", desc = "Find files" },
    { "<leader>fg", "<cmd>Telescope live_grep<CR>", desc = "Live grep" },
    { "<leader>fb", "<cmd>Telescope buffers<CR>", desc = "Buffers" },
    { "<leader>fh", "<cmd>Telescope help_tags<CR>", desc = "Help tags" },
    { "<leader>fr", "<cmd>Telescope oldfiles<CR>", desc = "Recent files" },
    { "<leader>fw", "<cmd>Telescope grep_string<CR>", desc = "Grep word under cursor" },
    { "<leader>/",  "<cmd>Telescope current_buffer_fuzzy_find<CR>", desc = "Search in buffer" },
  },
  opts = {
    defaults = {
      prompt_prefix = "  ",
      selection_caret = " ",
      path_display = { "truncate" },
      layout_config = { prompt_position = "top" },
      sorting_strategy = "ascending",
      vimgrep_arguments = {
        "rg", "--color=never", "--no-heading", "--with-filename",
        "--line-number", "--column", "--smart-case", "--hidden",
        "--glob", "!.git/*",
      },
    },
    pickers = {
      find_files = { hidden = true, find_command = { "rg", "--files", "--hidden", "--glob", "!.git/*" } },
    },
  },
}

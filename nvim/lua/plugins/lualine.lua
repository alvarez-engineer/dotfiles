-- Statusline, themed to match muted-ink.
return {
  "nvim-lualine/lualine.nvim",
  event = "VeryLazy",
  opts = function()
    local c = {
      bg = "#0d1117", bg2 = "#161b22", sel = "#263241",
      fg = "#c9d1d9", dim = "#6b7280",
      teal = "#7aa2a5", green = "#8ba88b", yellow = "#b8a06a",
      red = "#b26a6a", purple = "#9a7eaa", blue = "#7e9fbc",
    }
    local muted_ink = {
      normal = {
        a = { bg = c.teal, fg = c.bg, gui = "bold" },
        b = { bg = c.sel, fg = c.fg },
        c = { bg = c.bg2, fg = c.dim },
      },
      insert = { a = { bg = c.green, fg = c.bg, gui = "bold" } },
      visual = { a = { bg = c.yellow, fg = c.bg, gui = "bold" } },
      replace = { a = { bg = c.red, fg = c.bg, gui = "bold" } },
      command = { a = { bg = c.purple, fg = c.bg, gui = "bold" } },
      inactive = {
        a = { bg = c.bg2, fg = c.dim },
        b = { bg = c.bg2, fg = c.dim },
        c = { bg = c.bg2, fg = c.dim },
      },
    }
    return {
      options = {
        theme = muted_ink,
        globalstatus = true,
        component_separators = "",
        section_separators = "",
        icons_enabled = false,
      },
      sections = {
        lualine_a = { "mode" },
        lualine_b = { "branch", "diff", "diagnostics" },
        lualine_c = { { "filename", path = 1 } },
        lualine_x = { "filetype" },
        lualine_y = { "progress" },
        lualine_z = { "location" },
      },
    }
  end,
}

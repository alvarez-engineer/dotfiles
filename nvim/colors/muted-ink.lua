-- muted-ink — Neovim colorscheme derived from the Ghostty muted-ink palette.
-- Load with :colorscheme muted-ink
vim.cmd("highlight clear")
if vim.fn.exists("syntax_on") == 1 then vim.cmd("syntax reset") end
vim.o.background = "dark"
vim.g.colors_name = "muted-ink"

local p = {
  bg     = "#0d1117",
  bg2    = "#161b22",
  sel    = "#263241",
  fg     = "#c9d1d9",
  fg2    = "#e6edf3",
  dim    = "#6b7280",
  gutter = "#4b5563",

  red    = "#b26a6a",
  green  = "#7a9b76",
  yellow = "#b8a06a",
  blue   = "#6f8faf",
  purple = "#9a7eaa",
  cyan   = "#6e9a9a",

  bred    = "#c47a7a",
  bgreen  = "#8baf87",
  byellow = "#c7ae77",
  bblue   = "#7e9fbc",
  bpurple = "#aa8cbc",
  bcyan   = "#7dabab",

  teal   = "#7aa2a5",
}

local function hl(group, spec) vim.api.nvim_set_hl(0, group, spec) end

-- Editor UI
hl("Normal", { fg = p.fg, bg = p.bg })
hl("NormalFloat", { fg = p.fg, bg = p.bg2 })
hl("FloatBorder", { fg = p.sel, bg = p.bg2 })
hl("ColorColumn", { bg = p.bg2 })
hl("Cursor", { fg = p.bg, bg = p.teal })
hl("CursorLine", { bg = p.bg2 })
hl("CursorLineNr", { fg = p.teal, bold = true })
hl("LineNr", { fg = p.gutter })
hl("SignColumn", { bg = p.bg })
hl("VertSplit", { fg = p.sel })
hl("WinSeparator", { fg = p.sel })
hl("Folded", { fg = p.dim, bg = p.bg2 })
hl("Visual", { bg = p.sel })
hl("Search", { fg = p.bg, bg = p.byellow })
hl("IncSearch", { fg = p.bg, bg = p.teal })
hl("CurSearch", { fg = p.bg, bg = p.teal })
hl("MatchParen", { fg = p.teal, bold = true, underline = true })
hl("Pmenu", { fg = p.fg, bg = p.bg2 })
hl("PmenuSel", { fg = p.fg2, bg = p.sel })
hl("PmenuSbar", { bg = p.bg2 })
hl("PmenuThumb", { bg = p.gutter })
hl("StatusLine", { fg = p.fg, bg = p.sel })
hl("StatusLineNC", { fg = p.dim, bg = p.bg2 })
hl("TabLine", { fg = p.dim, bg = p.bg2 })
hl("TabLineSel", { fg = p.fg2, bg = p.sel })
hl("TabLineFill", { bg = p.bg })
hl("Whitespace", { fg = p.gutter })
hl("NonText", { fg = p.gutter })
hl("EndOfBuffer", { fg = p.bg })
hl("Title", { fg = p.teal, bold = true })
hl("Directory", { fg = p.bblue })
hl("WildMenu", { fg = p.bg, bg = p.teal })

-- Messages / diagnostics
hl("ErrorMsg", { fg = p.bred })
hl("WarningMsg", { fg = p.byellow })
hl("ModeMsg", { fg = p.dim })
hl("Question", { fg = p.bgreen })
hl("DiagnosticError", { fg = p.bred })
hl("DiagnosticWarn", { fg = p.byellow })
hl("DiagnosticInfo", { fg = p.bblue })
hl("DiagnosticHint", { fg = p.bcyan })
hl("DiagnosticUnderlineError", { undercurl = true, sp = p.bred })
hl("DiagnosticUnderlineWarn", { undercurl = true, sp = p.byellow })

-- Syntax
hl("Comment", { fg = p.dim, italic = true })
hl("Constant", { fg = p.bcyan })
hl("String", { fg = p.green })
hl("Character", { fg = p.green })
hl("Number", { fg = p.byellow })
hl("Boolean", { fg = p.byellow })
hl("Float", { fg = p.byellow })
hl("Identifier", { fg = p.fg })
hl("Function", { fg = p.bblue })
hl("Statement", { fg = p.purple })
hl("Conditional", { fg = p.purple })
hl("Repeat", { fg = p.purple })
hl("Label", { fg = p.purple })
hl("Operator", { fg = p.teal })
hl("Keyword", { fg = p.purple })
hl("Exception", { fg = p.purple })
hl("PreProc", { fg = p.bcyan })
hl("Include", { fg = p.bcyan })
hl("Define", { fg = p.bcyan })
hl("Macro", { fg = p.bcyan })
hl("Type", { fg = p.byellow })
hl("StorageClass", { fg = p.byellow })
hl("Structure", { fg = p.byellow })
hl("Typedef", { fg = p.byellow })
hl("Special", { fg = p.teal })
hl("SpecialChar", { fg = p.bred })
hl("Delimiter", { fg = p.fg })
hl("Todo", { fg = p.bg, bg = p.byellow, bold = true })
hl("Error", { fg = p.bred })
hl("Underlined", { underline = true })

-- Treesitter
hl("@variable", { fg = p.fg })
hl("@variable.builtin", { fg = p.bred })
hl("@variable.parameter", { fg = p.fg })
hl("@variable.member", { fg = p.bblue })
hl("@property", { fg = p.bblue })
hl("@function", { fg = p.bblue })
hl("@function.builtin", { fg = p.bcyan })
hl("@function.call", { fg = p.bblue })
hl("@function.method", { fg = p.bblue })
hl("@constructor", { fg = p.byellow })
hl("@keyword", { fg = p.purple })
hl("@keyword.function", { fg = p.purple })
hl("@keyword.return", { fg = p.purple })
hl("@keyword.import", { fg = p.bcyan })
hl("@type", { fg = p.byellow })
hl("@type.builtin", { fg = p.byellow })
hl("@string", { fg = p.green })
hl("@string.escape", { fg = p.bred })
hl("@number", { fg = p.byellow })
hl("@boolean", { fg = p.byellow })
hl("@comment", { fg = p.dim, italic = true })
hl("@punctuation.delimiter", { fg = p.fg })
hl("@punctuation.bracket", { fg = p.dim })
hl("@tag", { fg = p.purple })
hl("@tag.attribute", { fg = p.bblue })
hl("@tag.delimiter", { fg = p.dim })
hl("@markup.heading", { fg = p.teal, bold = true })
hl("@markup.link", { fg = p.bblue, underline = true })
hl("@markup.raw", { fg = p.green })

-- git / diff
hl("DiffAdd", { fg = p.bgreen, bg = "#16301c" })
hl("DiffChange", { fg = p.byellow, bg = "#2a2616" })
hl("DiffDelete", { fg = p.bred, bg = "#3a1d1d" })
hl("DiffText", { fg = p.fg2, bg = "#1f4a2c" })
hl("Added", { fg = p.bgreen })
hl("Changed", { fg = p.byellow })
hl("Removed", { fg = p.bred })
hl("GitSignsAdd", { fg = p.green })
hl("GitSignsChange", { fg = p.yellow })
hl("GitSignsDelete", { fg = p.red })

-- Telescope
hl("TelescopeBorder", { fg = p.sel, bg = p.bg2 })
hl("TelescopeNormal", { fg = p.fg, bg = p.bg2 })
hl("TelescopePromptBorder", { fg = p.sel, bg = p.bg2 })
hl("TelescopeSelection", { fg = p.fg2, bg = p.sel })
hl("TelescopeMatching", { fg = p.teal, bold = true })
hl("TelescopePromptPrefix", { fg = p.bgreen })

-- Notes-aware markdown buffers.
--
-- Only applies to files under $NOTES_DIR (default ~/notes) — markdown anywhere
-- else is left alone. See the `notes` module for the marker grammar these maps
-- insert; `bdsplit` routes the marked lines out into the standing lists.

local notes = vim.env.NOTES_DIR
if notes == nil or notes == "" then
  notes = vim.env.HOME .. "/notes"
end

local file = vim.api.nvim_buf_get_name(0)
if file == "" then
  return
end

-- resolve() so a symlinked notes dir still matches.
notes = vim.fn.resolve(vim.fn.fnamemodify(vim.fn.expand(notes), ":p")):gsub("/$", "")
file = vim.fn.resolve(file)

if file:sub(1, #notes + 1) ~= notes .. "/" then
  return
end

vim.opt_local.spell = true
vim.opt_local.wrap = true
vim.opt_local.linebreak = true
vim.opt_local.conceallevel = 2
vim.opt_local.textwidth = 0

-- Prepend a marker to the current line. maplocalleader is <Space> (nvim/init.lua),
-- so these are normal-mode maps — an insert-mode <localleader> map would swallow
-- the spacebar while typing.
local function prepend(marker)
  return function()
    local row = vim.api.nvim_win_get_cursor(0)[1]
    local line = vim.api.nvim_get_current_line()
    -- Replace an existing marker rather than stacking them.
    local body = line:gsub("^(%s*)%- %[[ xX]%] ", "%1"):gsub("^(%s*)[?!] ", "%1")
    local indent, rest = body:match("^(%s*)(.*)$")
    vim.api.nvim_set_current_line(indent .. marker .. rest)
    vim.api.nvim_win_set_cursor(0, { row, #(indent .. marker) })
  end
end

local map = function(lhs, marker, desc)
  vim.keymap.set("n", lhs, prepend(marker), { buffer = true, desc = desc })
end

map("<localleader>t", "- [ ] ", "Note: mark line as todo")
map("<localleader>q", "? ", "Note: mark line as question")
map("<localleader>r", "! ", "Note: mark line as remember")

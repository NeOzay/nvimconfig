local lspkind = require "lspkind"
local symbol_map = lspkind.symbol_map
local keymap = vim.keymap.set
--require('lspsaga.lspkind')

local util = require("ozay.util")

local kind = {
  Object = "@property",
  Array = "@property",
  Function = { symbol_map.Function, "@function" },
  Method = { symbol_map.Method, "@function" },
  Class = { symbol_map.Class, "@class" },
  Package = { symbol_map.Module, "Label" },
  Module = { symbol_map.Module, "Exception" },
  Field = { symbol_map.Field, "@field" },
  Enum = { symbol_map.Enum, "@lsp.type.enum" },
  Interface = { symbol_map.Interface, "Identifier" },
  Variable = { symbol_map.Variable, "@variable" },
  Constant = { symbol_map.Constant, "@lsp.type.readonly" },
  Struct = { symbol_map.Struct, "Type" },
  Event = { symbol_map.Event, "Constant" },
}

for key, value in pairs(kind) do
  if type(value) == "table" then
    value[1] = value[1].." "
  end
end

local saga = require('lspsaga').setup {
  symbol_in_winbar = {
    enable = false,
    separator = " ",
    hide_keyword = true,
    show_file = false,
    folder_level = 2,
    respect_root = false,
    color_mode = true,
  },
  definition = {
    keys = {
    edit = "<C-o>",
    vsplit = "<C-v>",
    split = "<C-i>",
    tabe = "<C-t>",
    quit = "q",
    close = "<Esc>",
    }
  },
  ui = {
    kind = kind
  }

}


-- LSP finder - Find the symbol's definition
-- If there is no definition, it will instead be hidden
-- When you use an action in finder like "open vsplit",
-- you can use <C-t> to jump back
util.nnoremap("gh", "<cmd>Lspsaga lsp_finder<CR>", 'lsp finder')

-- Code action
util.nnoremap("<leader>a", "<cmd>Lspsaga code_action<CR>", 'code action')
util.vnoremap("<leader>a", "<cmd>Lspsaga code_action<CR>", 'code action')

-- Rename all occurrences of the hovered word for the entire file
util.nnoremap("gr", "<cmd>Lspsaga rename<CR>", "rename")

-- Rename all occurrences of the hovered word for the selected files
--keymap("n", "gr", "<cmd>Lspsaga rename ++project<CR>")

-- Peek definition
-- You can edit the file containing the definition in the floating window
-- It also supports open/vsplit/etc operations, do refer to "definition_action_keys"
-- It also supports tagstack
-- Use <C-t> to jump back
util.nnoremap("gd", "<cmd>Lspsaga peek_definition<CR>", "peek definition")

-- Go to definition
--keymap("n","gd", "<cmd>Lspsaga goto_definition<CR>")

util.nnoremap("gt", "<cmd>Lspsaga peek_type_definition<CR>", "peek type def")

-- Show line diagnostics
-- You can pass argument ++unfocus to
-- unfocus the show_line_diagnostics floating window
util.nnoremap("<leader>sl", "<cmd>Lspsaga show_line_diagnostics<CR>", "diagnostic (line)")

-- Show cursor diagnostics
-- Like show_line_diagnostics, it supports passing the ++unfocus argument
util.nnoremap("<leader>sc", "<cmd>Lspsaga show_cursor_diagnostics<CR>", "diagnostic (cursor)")

-- Show buffer diagnostics
util.nnoremap("<leader>sb", "<cmd>Lspsaga show_buf_diagnostics<CR>", "diagnostic")

-- Diagnostic jump
-- You can use <C-o> to jump back to your previous location
util.nnoremap("[e", "<cmd>Lspsaga diagnostic_jump_prev<CR>", "diagnostic prev")
util.nnoremap("]e", "<cmd>Lspsaga diagnostic_jump_next<CR>", "diagnostic next")

-- Diagnostic jump with filters such as only jumping to an error
util.nnoremap("[E", function()
  require("lspsaga.diagnostic"):goto_prev({ severity = vim.diagnostic.severity.ERROR })
end, "error prev")
util.nnoremap("]E", function()
  require("lspsaga.diagnostic"):goto_next({ severity = vim.diagnostic.severity.ERROR })
end, "error next")

-- Toggle outline
util.nnoremap("<leader>o", "<cmd>Lspsaga outline<CR>", "outline")


-- Hover Doc
-- If there is no hover doc,
-- there will be a notification stating that
-- there is no information available.
-- To disable it just use ":Lspsaga hover_doc ++quiet"
-- Pressing the key twice will enter the hover window
util.nnoremap("K", "<cmd>Lspsaga hover_doc<CR>", "hover")

-- If you want to keep the hover window in the top right hand corner,
-- you can pass the ++keep argument
-- Note that if you use hover with ++keep, pressing this key again will
-- close the hover window. If you want to jump to the hover window
-- you should use the wincmd command "<C-w>w"
--keymap("n", "K", "<cmd>Lspsaga hover_doc ++keep<CR>")

-- Call hierarchy
util.nnoremap("<Leader>si", "<cmd>Lspsaga incoming_calls<CR>")
util.nnoremap("<Leader>so", "<cmd>Lspsaga outgoing_calls<CR>")

-- Floating terminal
keymap({ "n", "t" }, "<A-d>", "<cmd>Lspsaga term_toggle<CR>")

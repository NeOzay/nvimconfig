vim.g.barbar_auto_setup = false -- disable auto-setup
vim.g.mapleader = " "
require "ozay.plugins_loader"
require "ozay.plugins"
--require "ozay.test"

local function T(...)
  local t = {}
  for _, v in ipairs({ ... }) do
    t[v] = true
  end
  return t
end

vim.opt.encoding = "utf-8"
vim.opt.shortmess:append({ c = true })
vim.opt.hidden = true
vim.opt.signcolumn = "number"
vim.opt.virtualedit = "block"
vim.opt.whichwrap = T("b", "s", "[", "]", "<", ">")
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.formatoptions:append(T('m', "M", "j"))
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.mouse = "a"
vim.opt.cursorline = true
vim.opt.autoindent = true
vim.opt.expandtab = true
vim.opt.tabstop = 2
vim.opt.shiftwidth = 2
vim.opt.smartindent = true
vim.opt.wrap = false
vim.opt.sidescrolloff = 15
vim.opt.scrolloff = 2
vim.opt.foldmethod = "indent"
vim.opt.foldlevelstart = 20
vim.opt.termguicolors = true
vim.opt.updatetime = 250
vim.opt.showtabline = 2
vim.cmd 'set guicursor+=a:Cursor/lCursor'
vim.cmd [[
augroup OzayAuto
autocmd!
au Filetype lua setlocal formatoptions-=cro
augroup end
]]
vim.o.foldcolumn = '1' -- '0' is not bad
vim.o.foldlevel = 99 -- Using ufo provider need a large value, feel free to decrease the value
vim.o.foldlevelstart = 99
vim.o.foldenable = true

-- Using ufo provider need remap `zR` and `zM`. If Neovim is 0.6.1, remap yourself
vim.keymap.set('n', 'zR', require('ufo').openAllFolds)
vim.keymap.set('n', 'zM', require('ufo').closeAllFolds)

vim.opt.completeopt = T("menu", "menuone", "noselect")

vim.g.vimsyn_embed = 'l'

local fn = vim.fn
local api = vim.api


api.nvim_create_user_command("Trim", function()
  local view = fn.winsaveview()
  vim.cmd([[keeppatterns %s/\s\+$//e]])
  fn.winrestview(view)
end, { desc = "trim all lines of current buffer" })

local keymap = vim.keymap.set

local function newMapType(char)
  ---@param lhs string
  ---@param rhs string|fun():string?
  ---@param opts table|nil
  return function(lhs, rhs, opts)
    keymap(char, lhs, rhs, opts)
  end
end

local nnoremap = newMapType("n")
local cnoremap = newMapType("c")

nnoremap("i", function()
  if #api.nvim_get_current_line() == 0 then
    return [["_cc]]
  else
    return "i"
  end
end, { expr = true })
nnoremap("a", function()
  if #api.nvim_get_current_line() == 0 then
    return [["_cc]]
  else
    return "a"
  end
end, { expr = true })
nnoremap("<C-S>", "<Cmd>w<CR>")
nnoremap(" ", "<Nop>")
nnoremap("<leader>j", "<cmd>Inspect<cr>")
--nnoremap("<leader>n", "<cmd>tabn<cr>")
--nnoremap("<leader>p", "<cmd>tabp<cr>")
nnoremap("<leader>c", "ciw", { nowait = true })
--nnoremap("<leader>h", "<cmd>tab help <C-R><C-W><cr>")
nnoremap("<leader>h", ":tab help <C-R><C-W><CR>")
nnoremap(":", ": <BS>")
nnoremap("<leader>d", function()
  vim.diagnostic.open_float(nil, { focus = false })
end)

vim.cmd [[
if &wildoptions =~ "pum"
cnoremap <expr> <up> pumvisible() ? "<C-p>" : "<up>"
cnoremap <expr> <down> pumvisible() ? "<C-n>": "<down>"
endif
]]


vim.lsp.handlers["textDocument/publishDiagnostics"] = vim.lsp.with(
  vim.lsp.diagnostic.on_publish_diagnostics, {
    underline = true,
    virtual_text = false,
    signs = true,
    update_in_insert = false,
  }
)

vim.diagnostic.config {
  float = { border = "rounded" },
  signs = false,
  close_events = { "BufHidden", "InsertLeave" },
}
vim.lsp.handlers['textDocument/signatureHelp'] = vim.lsp.with(
  vim.lsp.handlers.signature_help, {
    border = 'rounded',
    close_events = { "BufHidden", "InsertLeave" },
  }
)

vim.lsp.handlers['textDocument/hover'] = vim.lsp.with(
  vim.lsp.handlers.hover, {
    border = 'rounded',
  }
)

api.nvim_create_user_command("Format", "lua vim.lsp.buf.format()", {})
api.nvim_create_user_command("Luarc", "!cp /home/ozay/.config/nvim/.luarc.json .", {})

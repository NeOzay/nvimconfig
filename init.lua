vim.g.barbar_auto_setup = false -- disable auto-setup
vim.g.mapleader = " "
require "ozay.plugins_loader"
require "ozay.plugins"


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
vim.cmd 'set guicursor+=a:Cursor/lCursor'
vim.cmd [[
augroup OzayAuto
autocmd!
au Filetype lua setlocal formatoptions-=cro
augroup end
]]

vim.opt.completeopt = T("menu", "menuone", "noselect")

vim.g.vimsyn_embed = 'l'

local fn = vim.fn
local api = vim.api

function SynGroup()
  local token = vim.lsp.semantic_tokens.get_at_pos()
  token = token and token[1]
  if token then
    local info = ("%s@%s"):format(token.type, table.concat(token.modifiers, ","))
    print(info)
  else
    local pos = api.nvim_win_get_cursor(0)
    local s = fn.synID(pos[1], pos[2] + 1, 1)
    local t = fn.synIDattr(s, 'name') .. " -> " .. fn.synIDattr(fn.synIDtrans(s), "name")
    print(t)
  end
end

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
nnoremap("<C-S>", "<Cmd>w<Cr>")
nnoremap(" ", "<Nop>")
nnoremap("<leader>j", "<cmd>Inspect<cr>")
--nnoremap("<leader>n", "<cmd>tabn<cr>")
--nnoremap("<leader>p", "<cmd>tabp<cr>")
nnoremap("<leader>c", "ciw", { nowait = true })
--nnoremap("<leader>h", "<cmd>tab help <C-R><C-W><cr>")
nnoremap("<leader>h", ":tab help <C-R><C-W><cr>")
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
if fn.filereadable "~/win32yank.exe" == 1 then
  vim.cmd [[
  set clipboard+=unnamedplus
  let g:clipboard = {
  \   'name': 'win32yank-wsl',
  \   'copy': {
  \      '+': 'win32yank.exe -i --crlf',
  \      '*': 'win32yank.exe -i --crlf',
  \    },
  \   'paste': {
  \      '+': 'win32yank.exe -o --lf',
  \      '*': 'win32yank.exe -o --lf',
  \   },
  \   'cache_enabled': 0,
  \ }
]]
end


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
  signs = false
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

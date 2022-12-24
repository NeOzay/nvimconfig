require "ozay.plugins_loader"

vim.g.mapleader = " "

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

vim.opt.completeopt = T("menu", "menuone", "noselect")

vim.g.vimsyn_embed = 'l'

vim.diagnostic.config { signs = false }
local fn = vim.fn
local api = vim.api

function SynGroup()
  local pos = api.nvim_win_get_cursor(0)
  local s = fn.synID(pos[1], pos[2] + 1, 1)
  local t = fn.synIDattr(s, 'name') .. " -> " .. fn.synIDattr(fn.synIDtrans(s), "name")
  print(t)
end

api.nvim_create_user_command("Trim", function()
  local view = fn.winsaveview()
  vim.cmd([[keeppatterns %s/\s\+$//e]])
  fn.winrestview(view)
end, { desc = "trim all lines of current buffer" })

local keymap = vim.keymap.set

local function newMapType(char)
  ---@param lhs string
  ---@param rhs string|fun():string
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
nnoremap("<leader>j", "<cmd>call v:lua.SynGroup()<cr>")
nnoremap("<leader>n", "<cmd>tabn<cr>")
nnoremap("<leader>p", "<cmd>tabp<cr>")
nnoremap("<leader>c", "ciw", { nowait = true })
--nnoremap("<leader>h", "<cmd>tab help <C-R><C-W><cr>")
nnoremap("<leader>h", ":tab help <C-R><C-W><cr>")
nnoremap(":", ": <BS>")

vim.cmd [[
if &wildoptions =~ "pum"
  cnoremap <expr> <up> pumvisible() ? "<C-p>" : "<up>"
  cnoremap <expr> <down> pumvisible() ? "<C-n>": "<down>"
endif
]]

--vim.cmd("colorscheme one_monokai")
--vim.g.monokaipro_filter = "spectrum"
vim.g.sonokai_style = 'shusia'
--vim.g.sonokai_style = 'atlantis'
vim.cmd [[colorscheme tokyonight-night]]

vim.lsp.handlers["textDocument/publishDiagnostics"] = vim.lsp.with(
  vim.lsp.diagnostic.on_publish_diagnostics, {
  underline = true,
  virtual_text = false,
  signs = true,
  update_in_insert = false,
}
)

local function goto_definition(split_cmd)
  local util = vim.lsp.util
  local log = require("vim.lsp.log")
  local api = vim.api

  -- note, this handler style is for neovim 0.5.1/0.6, if on 0.5, call with function(_, method, result)
  local handler = function(_, result, ctx)
    if result == nil or vim.tbl_isempty(result) then
      local _ = log.info() and log.info(ctx.method, "No location found")
      return nil
    end

    if split_cmd then
      vim.cmd(split_cmd)
    end

    if vim.tbl_islist(result) then
      util.jump_to_location(result[1])

      if #result > 1 then
        util.set_qflist(util.locations_to_items(result))
        api.nvim_command("copen")
        api.nvim_command("wincmd p")
      end
    else
      util.jump_to_location(result)
    end
  end

  return handler
end

vim.lsp.handlers["textDocument/definition"] = goto_definition('tabnew')
--vim.cmd [[autocmd CursorHold * lua vim.diagnostic.open_float(nil, {focus=false})]]
api.nvim_create_autocmd("CursorHold", {
  callback = function()
    local util = require "ozay.util"
    if not util.popupIsVisible() then
      vim.diagnostic.open_float(nil, { focus = false })
    end
  end
})
vim.diagnostic.config {
float = { border = "rounded" },
}
vim.lsp.handlers['textDocument/signatureHelp'] = vim.lsp.with(
            vim.lsp.handlers.signature_help, {
                border = 'rounded',
                close_events = {"BufHidden", "InsertLeave"},
    }
)

vim.lsp.handlers['textDocument/hover'] = vim.lsp.with(
            vim.lsp.handlers.hover, {
                border = 'rounded',
    }
)

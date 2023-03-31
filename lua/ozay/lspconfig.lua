local navic = require "nvim-navic"
local lspconfig = require "lspconfig"
-- Mappings.
-- See `:help vim.diagnostic.*` for documentation on any of the below functions
local opts = { noremap = true, silent = true }
vim.keymap.set('n', '<leader>e', vim.diagnostic.open_float, opts)
vim.keymap.set('n', '[d', vim.diagnostic.goto_prev, opts)
vim.keymap.set('n', ']d', vim.diagnostic.goto_next, opts)
vim.keymap.set('n', '<leader>q', vim.diagnostic.setloclist, opts)

-- Use an on_attach function to only map the following keys
-- after the language server attaches to the current buffer
local on_attach = function(client, bufnr)
  -- Enable completion triggered by <c-x><c-o>
  vim.api.nvim_buf_set_option(bufnr, 'omnifunc', 'v:lua.vim.lsp.omnifunc')

  if client.server_capabilities.documentSymbolProvider then
    navic.attach(client, bufnr)
  end
end

local lsp_flags = {
  -- This is the default in Nvim 0.7+
  debounce_text_changes = 150,
}
-- Add additional capabilities supported by nvim-cmp
local capabilities = require("cmp_nvim_lsp").default_capabilities()
local function addOption(t)
  t = t or {}
  if t.on_attach then
    local _on_attach = t.on_attach
    t.on_attach = function(c, b)
      on_attach(c, b)
      _on_attach(c, b)
    end
  else
    t.on_attach = on_attach
  end
  t.capabilities = capabilities
  return t
end

lspconfig.lua_ls.setup(addOption(require("ozay.lsp.sumneko_lua")))
lspconfig.jsonls.setup(addOption())
lspconfig.vimls.setup ( addOption() )
local eslintconf = {
  on_attach = function(client, bufnr)
    vim.api.nvim_create_autocmd("BufWritePre", {
      buffer = bufnr,
      command = "EslintFixAll",
    })
  end,
}

lspconfig.eslint.setup(addOption(eslintconf))
lspconfig.tsserver.setup(addOption())

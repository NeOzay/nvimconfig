require "nvchad.autocmds"
vim.o.updatetime = 250

vim.api.nvim_create_autocmd("CursorHold", {
  callback = function()
    vim.diagnostic.open_float({
      scope = "cursor"
    }, { focus = false })
  end,
})

vim.api.nvim_create_autocmd('FileType', {
    pattern = require'nvim-treesitter'.get_installed(),
    callback = function()
      -- syntax highlighting, provided by Neovim
      vim.treesitter.start()
      -- folds, provided by Neovim
      vim.wo.foldexpr = 'v:lua.vim.treesitter.foldexpr()'
      -- vim.wo.foldmethod = 'expr'
      -- indentation, provided by nvim-treesitter
      vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
    end,
  })

vim.api.nvim_create_autocmd('LspTokenUpdate', {
  callback = function(args)
    local token = args.data.token
    if token.type == 'variable' and not token.modifiers.readonly then
      vim.lsp.semantic_tokens.highlight_token(
        token, args.buf, args.data.client_id, 'MyMutableVariableHighlight'
      )
    end
  end,
})

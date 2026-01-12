vim.api.nvim_create_user_command("Format", function()
  vim.lsp.buf.format()
end, {})

vim.api.nvim_create_user_command("TSInstalled", function()
  print(table.concat(require 'nvim-treesitter'.get_installed(), ", "))
end, {})

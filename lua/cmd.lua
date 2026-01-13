local cmd = vim.api.nvim_create_user_command

cmd("Format", function()
  vim.lsp.buf.format()
end, {})

cmd("TSInstalled", function()
  print(table.concat(require 'nvim-treesitter'.get_installed(), ", "))
end, {})

cmd("LspInfo", "checkhealth vim.lsp", {})

cmd('LspLog', function()
  local log_path = vim.lsp.log.get_filename()
  vim.cmd.edit(log_path)
end, {})

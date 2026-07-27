-- Bootstrap for hover-translator plugin
-- This file is loaded automatically by Neovim

-- Prevent loading twice
if vim.g.loaded_hover_translator then
  return
end
vim.g.loaded_hover_translator = true

-- Require Neovim 0.9+
if vim.fn.has("nvim-0.9") ~= 1 then
  vim.notify("hover-translator requires Neovim 0.9 or later", vim.log.levels.ERROR)
  return
end

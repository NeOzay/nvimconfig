-- Load neo-tree highlights
vim.schedule(function()
  local ok, apply_highlights = pcall(require, 'highlights.neo-tree')
  if ok and type(apply_highlights) == 'function' then
    ---@cast apply_highlights function
    apply_highlights()
  end
end)

local api = vim.api
local autocommand = api.nvim_create_autocmd
local group = api.nvim_create_augroup("Ozay", {clear = true})

--local log = require("plenary.log")

autocommand("CursorHold", {
    group = group,
  callback = function()
    if require "ozay.util".popupIsVisible() then
      return
    end
    local cursor = api.nvim_win_get_cursor(0)
    local diagnostics = vim.diagnostic.get(0, {lnum = cursor[1]-1})
    for _, diagnostic in ipairs(diagnostics) do
     if diagnostic.col < cursor[2] + 1 and diagnostic.end_col > cursor[2] then
        vim.diagnostic.open_float(nil, { focus = false })
     end
    end
  end
})

autocommand("OptionSet", {
    group = group,
    pattern = "winbar",
    callback = function (opt)
      local option_old = vim.v.option_old
      local option_new = vim.v.option_new
      if option_old == "" and option_new ~= "" then
        return
        vim.cmd[[normal ]]
      elseif option_new == "" and option_old ~= "" then
        vim.cmd[[normal ]]
      end
      return opt
  end
  })

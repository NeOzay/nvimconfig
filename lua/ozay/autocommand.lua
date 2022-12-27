local api = vim.api
local autocommand = api.nvim_create_autocmd
local group = api.nvim_create_augroup("Ozay", {clear = true})

local log = require("plenary.log")

autocommand("CursorHold", {
    group = group,
  callback = function()
    if require "ozay.util".popupIsVisible() then
      return
    end
    local cursor = api.nvim_win_get_cursor(0)
    local diagnostics = vim.diagnostic.get(0, {lnum = cursor[1]-1})
    for _, diagnostic in ipairs(diagnostics) do
     if diagnostic.col < cursor[2] and diagnostic.end_col > cursor[2] then
        vim.diagnostic.open_float(nil, { focus = false })
     end
    end
  end
})

autocommand("OptionSet", {
    group = group,
    pattern = "winbar",
    callback = function (opt)
      --api.nvim_echo({{vim.inspect(opt)}}, true, {})
      print(vim.v.option_type)
      log.info(vim.v.option_old)
      log.info(vim.v.option_new)
      log.info("")
  end
  })

local api = vim.api
local autocommand = api.nvim_create_autocmd
local group = api.nvim_create_augroup("Ozay", { clear = true })

--local log = require("plenary.log")

autocommand("CursorHold", {
  group = group,
  callback = function()
    if require "ozay.util".popupIsVisible() then
      return
    end
    local cursor = api.nvim_win_get_cursor(0)
    local diagnostics = vim.diagnostic.get(0, { lnum = cursor[1] - 1 })
    for _, diagnostic in ipairs(diagnostics) do
      if diagnostic.col < cursor[2] + 1 and diagnostic.end_col > cursor[2] then
        vim.diagnostic.open_float(nil, { focus = false })
      end
    end
  end
})

autocommand("BufNew", {
  group = group,
  callback = function(a)
    vim.print('trigger')
    autocommand("BufEnter", {
      callback = function ()
        vim.print(api.nvim_buf_get_option(a.buf, "filetype"))
        if api.nvim_buf_get_option(a.buf, "filetype") == "help" then
          vim.notify("iswirk")
          api.nvim_buf_set_option(a.buf, "buflisted", true)
        end
      end,
      once = true,
    })
  end,
  pattern = "*.txt"
})


autocommand("BufEnter", {
  group = group,
  pattern = "*.*",
  callback = function()
    if false then
      vim.cmd [[normal i "_x]]
    end
    --print(api.nvim_buf_get_name(0))
  end
})

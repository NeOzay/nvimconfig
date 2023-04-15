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

--autocommand("OptionSet", {
--    group = group,
--    pattern = "winbar",
--    callback = function ()
--      local option_old = vim.v.option_old
--      local option_new = vim.v.option_new
--      local wininfo = vim.fn.getwininfo(vim.fn.win_getid())[1]
--      local cursor = api.nvim_win_get_cursor(0)
--      print(cursor[1],wininfo.topline, cursor[1] - wininfo.topline)
--      if cursor[1] - wininfo.topline > 2 and  wininfo.botline - cursor[1] > 2 then
--        if option_old == "" and option_new ~= "" then
--          --vim.cmd[[normal ]]
--        elseif option_new == "" and option_old ~= "" then
--          --vim.cmd[[normal ]]
--          pairs(wininfo)
--        end
--      end
--  end
--  })

--autocommand("OptionSet", {
--    group = group,
--    pattern = "winbar",
--    callback = function ()
--      local option = vim.v.option_new
--      if option == "" then
--        vim.opt.winbar = ">"
--      end
--    end
--  })

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

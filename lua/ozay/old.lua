---@diagnostic disable

local function SynGroup()
  local token = vim.lsp.semantic_tokens.get_at_pos()
  token = token and token[1]
  if token then
    local info = ("%s@%s"):format(token.type, table.concat(token.modifiers, ","))
    print(info)
  else
    local pos = api.nvim_win_get_cursor(0)
    local s = fn.synID(pos[1], pos[2] + 1, 1)
    local t = fn.synIDattr(s, 'name') .. " -> " .. fn.synIDattr(fn.synIDtrans(s), "name")
    print(t)
  end
end

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

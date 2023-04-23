local fn = vim.fn

local M = {}
function M.popupIsVisible()
  for _, window_id in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    -- If window is floating
    if vim.api.nvim_win_get_config(window_id)["relative"] ~= '' then -- Force close if called with !
      return true
    end
  end
  return false
end

function M.get_hl(group)
  local c = vim.api.nvim_get_hl(0, { name = group })
  return {
    fg = c.fg and string.format('#%06x', c.fg) or 'NONE',
    bg = c.bg and string.format('#%06x', c.bg) or 'NONE'
  }
end

function M.get_hlFg(group)
  local c = vim.api.nvim_get_hl(0, { name = group })
  return c.fg and string.format('#%06x', c.fg) or 'NONE'
end
function M.get_hlBg(group)
  local c = vim.api.nvim_get_hl(0, { name = group })
  return c.bg and string.format('#%06x', c.bg) or 'NONE'
end

function M.get_hlLink(group)
  local colorsGroup = M.get_hl(group)
  --vim.notify(vim.inspect(colorsGroup))
  if colorsGroup.fg ~= "NONE" or colorsGroup.bg ~= "NONE" then
    return fn.synIDattr(fn.synIDtrans(fn.hlID(group)), "name")
  end
end

function M.isRGBColor(color)
  local reg = "[0-9a-f]"
  return string.match(color, "#"..reg:rep(6)) ~= nil
end

return M

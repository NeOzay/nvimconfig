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

function M.getRGBHighlightColors(group)
  return {
    bg = fn.synIDattr(fn.synIDtrans(fn.hlID(group)), "bg#"),
    fg = fn.synIDattr(fn.synIDtrans(fn.hlID(group)), "fg#"),
  }
end

function M.getRGBHighlightFg(group)
  return fn.synIDattr(fn.synIDtrans(fn.hlID(group)), "fg#")
end
function M.getRGBHighlightBg(group)
  return fn.synIDattr(fn.synIDtrans(fn.hlID(group)), "bg#")
end

function M.getHighlightGroupLink(group)
  local colorsGroup = M.getRGBHighlightColors(group)
  --vim.notify(vim.inspect(colorsGroup))
  if colorsGroup.fg ~= "" or colorsGroup.bg ~= "" then
    return fn.synIDattr(fn.synIDtrans(fn.hlID(group)), "name")
  end
end

function M.isRGBColor(color)
  local reg = "[0-9a-f]"
  return string.match(color, "#"..reg:rep(6)) ~= nil
end

return M

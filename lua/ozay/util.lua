local fn = vim.fn

local M = {}
function M.popupIsVisible()
  for _, window_id in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
        -- If window is floating
        if vim.api.nvim_win_get_config(window_id).relative ~= '' then
            -- Force close if called with !
            return true
        end
    end
    return false
end

function M.getRGBHighlightGroup(group)
  return {
    bg = fn.synIDattr(fn.hlID(group), "bg#"),
    fg = fn.synIDattr(fn.hlID(group), "fg#")
  }
end

return M

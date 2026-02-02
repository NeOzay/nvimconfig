local M = {}
local api = vim.api

---@param s string
---@return boolean
function M.is_blanc_line(s)
	return vim.trim(s) == ""
end

function M.current_line_is_blanc()
	return M.is_blanc_line(api.nvim_get_current_line())
end

---@param nb integer
function M.key_nb_mapping(nb)
	local keys = { "&", "é", '"', "'", "(", "-", "è", "_", "ç", "à" }
	return keys[nb] or error("No mapping for number " .. nb)
end

return M

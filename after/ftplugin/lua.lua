local utils = require("utils")
vim.keymap.set("i", "@", function()
	if utils.current_line_is_blanc() then
		return [[---@]]
	else
		return "@"
	end
end, { expr = true, buffer = true, desc = "Insert @ with auto-comment" })

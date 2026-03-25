local M = {}

--- Get which quadrant to open the window on.
---
--- ```txt
---    top, left ↑ top, right
---            ← █ →
--- bottom, left ↓ bottom, right
--- ```
---@param w integer
---@param h integer
---@return [ "left" | "right" | "center", "top" | "bottom" | "center" ]
local function get_quadrant(w, h)
	local window = vim.api.nvim_get_current_win()
	local src_c = vim.api.nvim_win_get_cursor(window)

	---@type {row: integer, col: integer, endcol: integer, curscol: integer}
	local scr_p = vim.fn.screenpos(window, src_c[1], src_c[2])

	---@type integer, integer Vim's width & height.
	local vW, vH = vim.o.columns, vim.o.lines - (vim.o.cmdheight or 0)
	---@type "left" | "right", "top" | "bottom"
	local x, y

	if scr_p.curscol - w <= 0 then
		if scr_p.curscol + w >= vW then
			return { "center", "center" }
		else
			x = "right"
		end
	else
		x = "left"
	end

	if scr_p.row + h >= vH then
		if scr_p.row - h <= 0 then
			return { "center", "center" }
		else
			y = "top"
		end
	else
		y = "bottom"
	end

	return { x, y }
end

--- Build the base border table.
---@param border_hl string
---@return table[]
function M.build_border(border_hl)
	local hl = border_hl or "FloatBorder"
	return {
		{ "╭", hl },
		{ "─", hl },
		{ "╮", hl },
		{ "│", hl },
		{ "╯", hl },
		{ "─", hl },
		{ "╰", hl },
		{ "│", hl },
	}
end

--- Apply quadrant-based positioning to window config and border.
---@param win_config table Snacks win config to mutate (row, col, relative).
---@param border table[] Border table to mutate (corner characters).
---@param w integer Content width.
---@param h integer Content height.
function M.apply_position(win_config, border, w, h)
	local quad = get_quadrant(w + 2, h + 2)

	if quad[1] == "left" then
		win_config.col = (w * -1) - 1
	elseif quad[1] == "right" then
		win_config.col = 0
	else
		win_config.relative = "editor"
		win_config.col = math.ceil((vim.o.columns - w) / 2)
	end

	if quad[2] == "top" then
		win_config.row = (h * -1) - 2

		if quad[1] == "left" then
			border[5][1] = "┤"
		else
			border[7][1] = "├"
		end
	elseif quad[2] == "bottom" then
		win_config.row = 1

		if quad[1] == "left" then
			border[3][1] = "┤"
		else
			border[1][1] = "├"
		end
	else
		win_config.relative = "editor"
		win_config.row = math.ceil((vim.o.lines - h) / 2)
	end

	win_config.border = border
end

return M

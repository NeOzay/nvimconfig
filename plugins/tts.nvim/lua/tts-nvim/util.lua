---@namespace tts-nvim

---@class Util
local M = {}

---@class util.coordinates
---@field line_start integer
---@field line_end integer
---@field column_start integer
---@field column_end integer

---Lignes couvertes par la dernière sélection visuelle, et ses bornes.
---@return string[] lines, util.coordinates coords
---@nodiscard
function M.getVisualSelection()
	vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<esc>", true, false, true), "nx", false)

	local vstart = vim.fn.getpos("'<")
	local vend = vim.fn.getpos("'>")

	local coordinates = {
		line_start = vstart[2],
		line_end = vend[2],
		column_start = vstart[3],
		column_end = vend[3],
	}

	return vim.fn.getline(coordinates.line_start, coordinates.line_end), coordinates
end

---Découpe les lignes aux colonnes de la sélection.
---@param lines string[]
---@param coords util.coordinates
---@return string
---@nodiscard
function M.getTextFromSelection(lines, coords)
	if #lines == 0 then
		return ""
	end

	if coords.line_start == coords.line_end then
		return string.sub(lines[1], coords.column_start, coords.column_end)
	end

	local parts = { string.sub(lines[1], coords.column_start) } ---@type string[]
	for index = 2, #lines - 1 do
		table.insert(parts, lines[index])
	end
	table.insert(parts, string.sub(lines[#lines], 1, coords.column_end))

	return table.concat(parts, " ")
end

---Texte de la sélection visuelle, nettoyé selon le filetype et la configuration.
---@return string
---@nodiscard
function M.getAndProcessText()
	local text_processor = require("tts-nvim.text_processor")
	local config = require("tts-nvim.config")

	local lines, coords = M.getVisualSelection()
	local text = M.getTextFromSelection(lines, coords)

	return text_processor.process_text(text, vim.bo.filetype, config)
end

return M

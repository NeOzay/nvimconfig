local api = vim.api
local strdisplaywidth = vim.fn.strdisplaywidth
local render = require("plugins.ufo.render")

local M = {}

local langs = {
	python = require("plugins.ufo.langs.python"),
}

--- Comportement par défaut : Première ... Dernière (N lignes)
---@param virt_text table[]
---@param lnum integer
---@param end_lnum integer
---@param width integer
---@param truncate_fn function
---@param bufnr integer
---@param num_lines integer
---@return table[]
function M.default_handler(virt_text, lnum, end_lnum, width, truncate_fn, bufnr, num_lines)
	local suffix = (" (%d lignes)"):format(num_lines)
	local suffix_w = strdisplaywidth(suffix)
	local ellipsis_w = strdisplaywidth(render.ELLIPSIS)

	local end_virt, end_w = render.get_line_virt(bufnr, end_lnum - 1)
	local mid_virt, mid_w = nil, 0
	if num_lines == 2 then
		mid_virt, mid_w = render.get_line_virt(bufnr, lnum)
	end

	local available = width - suffix_w - ellipsis_w
	local include_mid = mid_virt and (mid_w + end_w + 2 <= width - suffix_w)

	if include_mid then
		available = width - suffix_w - 2
	end

	local first_w = math.max(0, available - (include_mid and mid_w + end_w or end_w))

	local result = render.truncate(virt_text, first_w, truncate_fn)

	if include_mid then
		result[#result + 1] = { render.SPACE, "Normal" }
		vim.list_extend(result, render.truncate(mid_virt, available - render.virt_width(result), truncate_fn))
		result[#result + 1] = { render.SPACE, "Normal" }
		vim.list_extend(result, render.truncate(end_virt, available - render.virt_width(result), truncate_fn))
	else
		result[#result + 1] = { render.ELLIPSIS, "Comment" }
		vim.list_extend(result, render.truncate(end_virt, available - render.virt_width(result) + ellipsis_w, truncate_fn))
	end

	result[#result + 1] = { suffix, "UfoFoldCount" }
	return result
end

--- Handler principal pour le texte virtuel des folds
---@param virt_text table[]
---@param lnum integer
---@param end_lnum integer
---@param width integer
---@param truncate_fn function
---@return table[]
function M.fold_handler(virt_text, lnum, end_lnum, width, truncate_fn)
	local bufnr = api.nvim_get_current_buf()
	local num_lines = end_lnum - lnum
	local ft = vim.bo[bufnr].filetype

	-- Dispatch au handler de langage
	local lang = langs[ft]
	if lang then
		local ctx = {
			bufnr = bufnr,
			lnum = lnum,
			end_lnum = end_lnum,
			num_lines = num_lines,
			width = width,
			virt_text = virt_text,
			first_line = api.nvim_buf_get_lines(bufnr, lnum - 1, lnum, false)[1] or "",
			truncate_fn = truncate_fn,
			render = render,
		}
		local result = lang.handle(ctx)
		if result then return result end
	end

	-- Comportement par défaut
	return M.default_handler(virt_text, lnum, end_lnum, width, truncate_fn, bufnr, num_lines)
end

return M

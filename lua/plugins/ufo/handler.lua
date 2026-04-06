local api = vim.api
local strdisplaywidth = vim.fn.strdisplaywidth
local render = require("plugins.ufo.render")

-- Remplace le virt_text UFO par notre propre rendu pour avoir les semantic
-- tokens superposés correctement (couleur + italic, etc.).
-- L'indentation est réinjectée en préfixe car UFO positionne le virt_text
-- à virt_text_win_col=0 et s'attend à ce que l'indentation soit incluse.
local function regen_first_line(bufnr, lnum)
	local raw = api.nvim_buf_get_lines(bufnr, lnum - 1, lnum, false)[1] or ""
	local indent = raw:match("^(%s*)") or ""
	local virt = render.get_line_virt(bufnr, lnum - 1)
	if #indent > 0 then
		table.insert(virt, 1, { indent, "Normal" })
	end
	return virt
end

local M = {}

local langs = {
	python = require("plugins.ufo.langs.python"),
}

--- Comportement par défaut : Première ... Dernière (N lignes)
---@param virt_text Ozay.VirtChunk[]
---@param lnum integer
---@param end_lnum integer
---@param width integer
---@param truncate_fn Ozay.TruncateFn
---@param bufnr integer
---@param num_lines integer
---@return Ozay.VirtChunk[]
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
	local include_mid = mid_virt and (mid_w + end_w + 2 <= width - suffix_w) or false

	if include_mid then
		available = width - suffix_w - 2
	end

	local first_w = math.max(0, available - (include_mid and mid_w + end_w or end_w))

	local result = render.truncate(virt_text, first_w, truncate_fn)

	if include_mid and mid_virt then
		result[#result + 1] = { render.SPACE, "Normal" }
		vim.list_extend(result, render.truncate(mid_virt, available - render.virt_width(result), truncate_fn))
		result[#result + 1] = { render.SPACE, "Normal" }
		vim.list_extend(result, render.truncate(end_virt, available - render.virt_width(result), truncate_fn))
	else
		result[#result + 1] = { render.ELLIPSIS, "Comment" }
		vim.list_extend(
			result,
			render.truncate(end_virt, available - render.virt_width(result) + ellipsis_w, truncate_fn)
		)
	end

	result[#result + 1] = { suffix, "UfoFoldCount" }
	return result
end

--- Handler principal pour le texte virtuel des folds
---@param virt_text Ozay.VirtChunk[]
---@param lnum integer
---@param end_lnum integer
---@param width integer
---@param truncate_fn Ozay.TruncateFn
---@return Ozay.VirtChunk[]
function M.fold_handler(virt_text, lnum, end_lnum, width, truncate_fn)
	local bufnr = api.nvim_get_current_buf()
	local num_lines = end_lnum - lnum
	local ft = vim.bo[bufnr].filetype

	-- Remplacer le virt_text d'UFO par notre rendu (gestion des highlights superposés)
	virt_text = regen_first_line(bufnr, lnum)

	-- Dispatch au handler de langage
	local lang = langs[ft]
	if lang then
		---@class Ozay.FoldContext
		---@field bufnr integer
		---@field lnum integer          -- 1-indexed
		---@field end_lnum integer      -- 1-indexed
		---@field num_lines integer
		---@field width integer
		---@field virt_text Ozay.VirtChunk[]  -- première ligne colorée
		---@field first_line string           -- texte brut première ligne
		---@field truncate_fn Ozay.TruncateFn
		---@field render Ozay.UfoRender       -- module render

		---@type Ozay.FoldContext
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
		if result then
			return result
		end
	end

	-- Comportement par défaut
	return M.default_handler(virt_text, lnum, end_lnum, width, truncate_fn, bufnr, num_lines)
end

return M

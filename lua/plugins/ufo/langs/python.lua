local api = vim.api
local strdisplaywidth = vim.fn.strdisplaywidth

local M = {}

---@class FoldContext
---@field bufnr integer
---@field lnum integer          -- 1-indexed
---@field end_lnum integer      -- 1-indexed
---@field num_lines integer
---@field width integer
---@field virt_text table[]     -- première ligne colorée
---@field first_line string     -- texte brut première ligne
---@field truncate_fn function
---@field render table          -- module render

--- Handler Python pour le texte virtuel des folds
--- Retourne table[] | nil (nil = utiliser le rendu par défaut)
---@param ctx FoldContext
---@return table[]|nil
function M.handle(ctx)
	local render = ctx.render
	local first_line = ctx.first_line

	-- Docstrings
	if first_line:match('^%s*"""') or first_line:match("^%s*'''") then
		local indent = first_line:match("^(%s*)") or ""
		local suffix = ("  (%d lignes)"):format(ctx.num_lines)
		return {
			{ indent .. '""" ', "Comment" },
			{ "Docstring", "@string.documentation.python" },
			{ ' """', "Comment" },
			{ suffix, "UfoFoldCount" },
		}
	end

	-- Déclarations multi-lignes
	if
		(first_line:match("^%s*def%s") or first_line:match("^%s*class%s"))
		and not first_line:match(":%s*$")
		and not first_line:match(":%s*#")
	then
		-- Scanner pour trouver la ligne ): qui ferme la signature
		local sig_end
		for i = ctx.lnum, ctx.end_lnum - 1 do
			local line = api.nvim_buf_get_lines(ctx.bufnr, i, i + 1, false)[1] or ""
			if line:match(":%s*$") or line:match(":%s*#") then
				sig_end = i
				break
			end
		end
		if sig_end then
			local suffix = (" (%d lignes)"):format(ctx.num_lines)
			local suffix_w = strdisplaywidth(suffix)
			-- Collecter les lignes intermédiaires
			local mid_parts = {}
			local mid_total_w = 0
			for i = ctx.lnum, sig_end do
				local line = vim.trim(api.nvim_buf_get_lines(ctx.bufnr, i, i + 1, false)[1] or "")
				local w = strdisplaywidth(line)
				mid_total_w = mid_total_w + w + 1
				mid_parts[#mid_parts + 1] = { text = line, row = i }
			end
			local full_w = render.virt_width(ctx.virt_text) + mid_total_w + suffix_w
			if full_w <= ctx.width then
				-- Tout tient sur une ligne
				local result = { unpack(ctx.virt_text) }
				for _, part in ipairs(mid_parts) do
					local part_virt = render.get_line_virt(ctx.bufnr, part.row)
					result[#result + 1] = { " ", "Normal" }
					vim.list_extend(result, part_virt)
				end
				result[#result + 1] = { suffix, "UfoFoldCount" }
				return result
			else
				-- Ne tient pas
				local end_virt, end_w = render.get_line_virt(ctx.bufnr, sig_end)
				local available = ctx.width - suffix_w - strdisplaywidth(render.ELLIPSIS)
				local first_w = math.max(0, available - end_w)
				local result = render.truncate(ctx.virt_text, first_w, ctx.truncate_fn)
				result[#result + 1] = { render.ELLIPSIS, "Comment" }
				vim.list_extend(
					result,
					render.truncate(
						end_virt,
						available - render.virt_width(result) + strdisplaywidth(render.ELLIPSIS),
						ctx.truncate_fn
					)
				)
				result[#result + 1] = { suffix, "UfoFoldCount" }
				return result
			end
		end
	-- Instanciations de tuple/dict/array → fall-through au défaut
	elseif first_line:match("[%(%[{]%s*$") or first_line:match("[%(%[{]%s*#") then
		return nil
	-- Autres blocs → première ligne + compteur
	else
		local suffix = (" (%d lignes)"):format(ctx.num_lines)
		local suffix_w = strdisplaywidth(suffix)
		local result = render.truncate(ctx.virt_text, ctx.width - suffix_w, ctx.truncate_fn)
		result[#result + 1] = { suffix, "UfoFoldCount" }
		return result
	end
end

--- Fold toutes les docstrings Python multi-lignes du buffer
function M.fold_docstrings()
	local bufnr = api.nvim_get_current_buf()
	if vim.bo[bufnr].filetype ~= "python" then
		return
	end
	local parser = vim.treesitter.get_parser(bufnr, "python")
	if not parser then
		return
	end
	local tree = parser:parse()[1]
	if not tree then
		return
	end
	local query = vim.treesitter.query.parse("python", "(expression_statement (string) @docstring)")
	for _, node in query:iter_captures(tree:root(), bufnr) do
		local start_row, _, end_row, _ = node:range()
		if end_row > start_row then
			local lnum = start_row + 1
			local end_lnum = end_row + 1
			vim.cmd(lnum .. "," .. end_lnum .. "fold")
			local fb = require("ufo.fold").get(bufnr)
			if fb then
				fb:closeFold(lnum, end_lnum)
			end
		end
	end
end

return M

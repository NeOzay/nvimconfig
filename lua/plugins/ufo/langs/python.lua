local api = vim.api
local strdisplaywidth = vim.fn.strdisplaywidth

local M = {}

---@param ctx Ozay.FoldContext
---@return Ozay.VirtChunk[]
local function handle_docstring(ctx)
	local indent = ctx.first_line:match("^(%s*)") or ""
	local suffix = ("  (%d lignes)"):format(ctx.num_lines)
	return {
		{ indent .. '""" ', "Comment" },
		{ "Docstring", "@string.documentation.python" },
		{ ' """', "Comment" },
		{ suffix, "UfoFoldCount" },
	}
end

--- Trouve la ligne de fin de signature (celle qui se termine par `:`)
---@param ctx Ozay.FoldContext
---@return integer|nil
local function find_sig_end(ctx)
	for i = ctx.lnum, ctx.end_lnum - 1 do
		local line = api.nvim_buf_get_lines(ctx.bufnr, i, i + 1, false)[1] or ""
		if line:match(":%s*$") or line:match(":%s*#") then
			return i
		end
	end
end

---@param ctx Ozay.FoldContext
---@param sig_end integer
---@return Ozay.VirtChunk[]
local function render_multiline_def_fits(ctx, sig_end)
	local render = ctx.render
	local suffix = (" (%d lignes)"):format(ctx.num_lines)
	local result = { unpack(ctx.virt_text) }
	for i = ctx.lnum, sig_end do
		local part_virt = render.get_line_virt(ctx.bufnr, i)
		result[#result + 1] = { " ", "Normal" }
		vim.list_extend(result, part_virt)
	end
	result[#result + 1] = { suffix, "UfoFoldCount" }
	return result
end

---@param ctx Ozay.FoldContext
---@param sig_end integer
---@return Ozay.VirtChunk[]
local function render_multiline_def_truncated(ctx, sig_end)
	local render = ctx.render
	local suffix = (" (%d lignes)"):format(ctx.num_lines)
	local suffix_w = strdisplaywidth(suffix)
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

---@param ctx Ozay.FoldContext
---@return Ozay.VirtChunk[]|nil
local function handle_multiline_def(ctx)
	local sig_end = find_sig_end(ctx)
	if not sig_end then
		return nil
	end
	local render = ctx.render
	local suffix_w = strdisplaywidth((" (%d lignes)"):format(ctx.num_lines))
	local mid_total_w = 0
	for i = ctx.lnum, sig_end do
		local line = vim.trim(api.nvim_buf_get_lines(ctx.bufnr, i, i + 1, false)[1] or "")
		mid_total_w = mid_total_w + strdisplaywidth(line) + 1
	end
	local full_w = render.virt_width(ctx.virt_text) + mid_total_w + suffix_w
	if full_w <= ctx.width then
		return render_multiline_def_fits(ctx, sig_end)
	else
		return render_multiline_def_truncated(ctx, sig_end)
	end
end

---@param ctx Ozay.FoldContext
---@return Ozay.VirtChunk[]
local function handle_simple_block(ctx)
	local render = ctx.render
	local suffix = (" (%d lignes)"):format(ctx.num_lines)
	local result = render.truncate(ctx.virt_text, ctx.width - strdisplaywidth(suffix), ctx.truncate_fn)
	result[#result + 1] = { suffix, "UfoFoldCount" }
	return result
end

--- Handler Python pour le texte virtuel des folds
--- Retourne Ozay.VirtChunk[] | nil (nil = utiliser le rendu par défaut)
---@param ctx Ozay.FoldContext
---@return Ozay.VirtChunk[]|nil
function M.handle(ctx)
	local first_line = ctx.first_line

	if first_line:match('^%s*"""') or first_line:match("^%s*'''") then
		return handle_docstring(ctx)
	end

	if
		(first_line:match("^%s*def%s") or first_line:match("^%s*class%s"))
		and not first_line:match(":%s*$")
		and not first_line:match(":%s*#")
	then
		return handle_multiline_def(ctx)
	end

	-- Instanciations de tuple/dict/array → fall-through au défaut
	if first_line:match("[%(%[{]%s*$") or first_line:match("[%(%[{]%s*#") then
		return nil
	end

	return handle_simple_block(ctx)
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
	local fb = require("ufo.fold").get(bufnr)
	local cmds = {}
	for _, node in query:iter_captures(tree:root(), bufnr) do
		local start_row, _, end_row, _ = node:range()
		if end_row > start_row then
			local lnum = start_row + 1
			local end_lnum = end_row + 1
			if vim.fn.foldclosed(lnum) == -1 then
				if fb then
					fb:closeFold(lnum, end_lnum)
				end
				table.insert(cmds, lnum .. "foldclose")
			end
		end
	end
	if #cmds > 0 then
		vim.cmd("silent! " .. table.concat(cmds, "|"))
	end
end

return M

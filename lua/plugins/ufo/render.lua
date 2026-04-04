local api, fn = vim.api, vim.fn
local strdisplaywidth = fn.strdisplaywidth

local M = {}

-- Constantes
M.ELLIPSIS = " ... "
M.SPACE = " "

local LSP_PRIORITY, TS_PRIORITY = 2, 1

-- Highlight pour le compteur de lignes des folds
api.nvim_set_hl(0, "UfoFoldCount", { fg = require("base46.colors").get_hi_attr("Comment", "fg"), italic = true })

-- Cache des namespaces LSP
local lsp_ns_cache = nil

api.nvim_create_autocmd("LspAttach", {
	callback = function()
		lsp_ns_cache = nil
	end,
})
--
-- -- Rafraîchir les folds quand les semantic tokens sont mis à jour
-- api.nvim_create_autocmd("LspTokenUpdate", {
-- 	callback = function(args)
-- 		lsp_ns_cache = nil
-- 		local ufo, ok = pRequire("ufo")
-- 		if ok then
-- 			ufo.disableFold(args.buf)
-- 			ufo.enableFold(args.buf)
-- 		end
-- 	end,
-- 	once = true,
-- })

---@class FoldHighlight
---@field start_col number
---@field end_col number
---@field hl string
---@field priority number

--- Vérifie si un highlight group existe
---@param name string?
---@return boolean
local function hl_exists(name)
	if not name then
		return false
	end
	local hl = api.nvim_get_hl(0, { name = name, link = false, create = false })
	return hl and next(hl) ~= nil
end

--- Calcule la largeur d'un texte virtuel
---@param chunks table[]
---@return number
function M.virt_width(chunks)
	local w = 0
	for _, c in ipairs(chunks) do
		w = w + strdisplaywidth(c[1])
	end
	return w
end

--- Tronque un texte virtuel à une largeur max
---@param chunks table[]
---@param max_w number
---@param truncate_fn function
---@return table[]
function M.truncate(chunks, max_w, truncate_fn)
	local result, w = {}, 0
	for _, chunk in ipairs(chunks) do
		local text, hl = chunk[1], chunk[2]
		local cw = strdisplaywidth(text)
		if w + cw <= max_w then
			result[#result + 1] = chunk
			w = w + cw
		else
			text = truncate_fn(text, max_w - w)
			if text and #text > 0 then
				result[#result + 1] = { text, hl }
			end
			break
		end
	end
	return result
end

--- Récupère les namespaces LSP (avec cache)
---@return table<string, integer>
local function get_lsp_ns()
	if not lsp_ns_cache then
		lsp_ns_cache = {}
		for name, id in pairs(api.nvim_get_namespaces()) do
			if name:match("semantic_tokens") or name:match("lsp") then
				lsp_ns_cache[name] = id
			end
		end
	end
	return lsp_ns_cache
end

--- Récupère les highlights LSP pour une ligne
---@param bufnr integer
---@param row integer
---@return FoldHighlight[]
local function get_lsp_hl(bufnr, row)
	local result = {}
	for _, ns_id in pairs(get_lsp_ns()) do
		local marks = api.nvim_buf_get_extmarks(bufnr, ns_id, { row, 0 }, { row, -1 }, { details = true })
		for _, mark in ipairs(marks) do
			local col, details = mark[3], mark[4]
			if details and details.hl_group and hl_exists(details.hl_group) then
				result[#result + 1] = {
					start_col = col,
					end_col = details.end_col or col + 1,
					hl = details.hl_group,
					priority = LSP_PRIORITY,
				}
			end
		end
	end
	return result
end

--- Récupère les highlights treesitter pour une ligne
---@param bufnr integer
---@param row integer
---@return FoldHighlight[]
local function get_ts_hl(bufnr, row)
	local result = {}
	local line = api.nvim_buf_get_lines(bufnr, row, row + 1, false)[1]
	if not line then
		return result
	end

	local ok = pcall(vim.treesitter.get_captures_at_pos, bufnr, row, 0)
	if not ok then
		return result
	end

	for col = 0, #line - 1 do
		local caps = vim.treesitter.get_captures_at_pos(bufnr, row, col)
		if caps and #caps > 0 then
			local hl = "@" .. caps[#caps].capture
			local last = result[#result]
			if last and last.hl == hl and last.end_col == col then
				last.end_col = col + 1
			else
				result[#result + 1] = { start_col = col, end_col = col + 1, hl = hl, priority = TS_PRIORITY }
			end
		end
	end
	return result
end

--- Fusionne et trie les highlights (LSP prioritaire)
---@param bufnr integer
---@param row integer
---@return FoldHighlight[]
local function get_highlights(bufnr, row)
	local hl = get_lsp_hl(bufnr, row)
	vim.list_extend(hl, get_ts_hl(bufnr, row))
	table.sort(hl, function(a, b)
		if a.start_col ~= b.start_col then
			return a.start_col < b.start_col
		end
		return a.priority > b.priority
	end)
	return hl
end

--- Construit le texte virtuel coloré pour une ligne
---@param bufnr integer
---@param row integer
---@param offset integer
---@param text string
---@return table[]
function M.build_virt_text(bufnr, row, offset, text)
	local highlights = get_highlights(bufnr, row)
	if #highlights == 0 then
		return { { text, "Normal" } }
	end

	local result, pos, seen = {}, 0, {}
	for _, hl in ipairs(highlights) do
		local s, e = math.max(0, hl.start_col - offset), math.max(0, hl.end_col - offset)
		local key = s .. ":" .. e .. ":" .. hl.hl

		if not seen[key] and e > s and s < #text then
			if s > pos then
				result[#result + 1] = { text:sub(pos + 1, s), "Normal" }
			end
			local chunk = text:sub(math.max(pos, s) + 1, math.min(e, #text))
			if #chunk > 0 then
				result[#result + 1] = { chunk, hl.hl }
				pos = math.min(e, #text)
				seen[key] = true
			end
		end
	end

	if pos < #text then
		result[#result + 1] = { text:sub(pos + 1), "Normal" }
	end
	return #result > 0 and result or { { text, "Normal" } }
end

--- Récupère le texte virtuel coloré d'une ligne avec sa largeur
---@param bufnr integer
---@param row integer
---@return table[] virt_text
---@return number width
function M.get_line_virt(bufnr, row)
	local raw = api.nvim_buf_get_lines(bufnr, row, row + 1, false)[1] or ""
	local trimmed = vim.trim(raw)
	local offset = #raw - #raw:gsub("^%s+", "")
	local virt = M.build_virt_text(bufnr, row, offset, trimmed)
	return virt, M.virt_width(virt)
end

return M

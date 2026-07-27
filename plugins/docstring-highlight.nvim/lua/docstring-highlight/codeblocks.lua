---@namespace docstring-highlight
--- Highlights fenced code blocks inside Python docstrings.
---
--- Detects ```language ... ``` blocks within docstring content,
--- parses the code with treesitter in a scratch buffer, and copies
--- the resulting highlights back to the original buffer via extmarks.
---
--- ## Plan d'implémentation
---
--- ### Étape 1 : Détection des blocs
---
--- Scanner les lignes d'une docstring pour trouver les paires de délimiteurs :
---   - Ouverture : ligne matchant `^%s*```(%w+)` → capture le langage
---   - Fermeture : ligne matchant `^%s*```%s*$`
---   - Résultat : liste de { lang, start_row, end_row, lines, indent }
---
--- ### Étape 2 : Buffer scratch + treesitter
---
--- Pour chaque bloc détecté :
---   1. Créer un buffer scratch invisible (`nvim_create_buf(false, true)`)
---   2. Écrire les lignes de code (dé-indentées) dans le scratch
---   3. Assigner le filetype (`vim.bo[scratch].filetype = lang`)
---   4. Parser avec `vim.treesitter.get_parser(scratch, lang)`
---   5. Récupérer les highlights via `iter_matches` sur la query `highlights`
---   6. Supprimer le buffer scratch
---
--- ### Étape 3 : Report des highlights
---
--- Pour chaque highlight obtenu du scratch :
---   - Mapper (scratch_row, scratch_col) → (buf_row, buf_col + indent)
---   - Appliquer via `nvim_buf_set_extmark` dans le namespace du plugin
---   - Utiliser une priorité légèrement inférieure aux highlights de docstring
---     pour ne pas interférer avec les marqueurs ``` eux-mêmes
---
--- ### Intégration avec init.lua
---
--- `refresh()` dans init.lua appellera `codeblocks.highlight(bufnr, ns, docstring_node)`
--- après le parcours ligne par ligne, pour chaque docstring détectée.
--- Le module est autonome : il reçoit le bufnr, le namespace, et le range
--- de la docstring (start_row, end_row).
---
--- ### Gestion du cache
---
--- Le buffer scratch est réutilisé (un seul par session) pour éviter les
--- allocations répétées. Il est nettoyé entre chaque bloc.
---
--- ### Langages supportés
---
--- Tout langage pour lequel un parseur treesitter est installé.
--- Le bloc doit spécifier le langage : ```python, ```lua, ```json, etc.
--- Les blocs sans langage (``` seul) sont ignorés.

local config = require("docstring-highlight.config")

local M = {}

-- Reusable scratch buffer (created lazily)
---@type integer?
local scratch_buf = nil

-- Cache for blended highlight groups: { [ts_group] = combined_group_name }
local blend_cache = {}

--- Resolve a highlight group to its effective attributes (follows links).
---@param name string
---@return vim.api.keyset.get_hl_info
local function resolve_hl(name)
	return vim.api.nvim_get_hl(0, { name = name, link = false })
end

--- Blend two RGB integer colors. factor: 0 = pure c1, 100 = pure c2.
---@param c1 integer
---@param c2 integer
---@param factor number 0-100
---@return integer
local function blend_color(c1, c2, factor)
	local f = factor / 100
	local r1, g1, b1 = bit.rshift(c1, 16), bit.band(bit.rshift(c1, 8), 0xFF), bit.band(c1, 0xFF)
	local r2, g2, b2 = bit.rshift(c2, 16), bit.band(bit.rshift(c2, 8), 0xFF), bit.band(c2, 0xFF)
	local r = math.floor(r1 * (1 - f) + r2 * f + 0.5)
	local g = math.floor(g1 * (1 - f) + g2 * f + 0.5)
	local b = math.floor(b1 * (1 - f) + b2 * f + 0.5)
	return bit.bor(bit.lshift(r, 16), bit.lshift(g, 8), b)
end

--- Get or create a blended highlight group combining a treesitter group with DocstringCodeBlock.
---@param ts_group string e.g. "@keyword.python"
---@param block_hl vim.api.keyset.get_hl_info Resolved DocstringCodeBlock attributes
---@param blend_factor number 0-100
---@return string group_name
local function get_blended_group(ts_group, block_hl, blend_factor)
	if blend_cache[ts_group] then
		return blend_cache[ts_group]
	end

	local ts_hl = resolve_hl(ts_group)
	local combined_name = "DocstringCB_" .. ts_group:gsub("[%.@]", "_")

	local def = {}

	-- fg: blend treesitter fg towards DocstringCodeBlock fg
	if ts_hl.fg then
		if blend_factor > 0 and block_hl.fg then
			def.fg = blend_color(ts_hl.fg, block_hl.fg, blend_factor)
		else
			def.fg = ts_hl.fg
		end
	elseif block_hl.fg then
		def.fg = block_hl.fg
	end

	-- bg: always use DocstringCodeBlock bg
	if block_hl.bg then
		def.bg = block_hl.bg
	end

	-- Preserve style attributes from treesitter
	for _, attr in ipairs({ "bold", "italic", "underline", "strikethrough", "undercurl" }) do
		if ts_hl[attr] then
			def[attr] = ts_hl[attr]
		end
	end

	vim.api.nvim_set_hl(0, combined_name, def)
	blend_cache[ts_group] = combined_name
	return combined_name
end

--- Clear the blended highlight cache (call on ColorScheme change).
function M.clear_cache()
	blend_cache = {}
end

--- Get or create the scratch buffer for parsing code blocks.
---@return integer bufnr
local function get_scratch()
	if scratch_buf and vim.api.nvim_buf_is_valid(scratch_buf) then
		return scratch_buf
	end
	scratch_buf = vim.api.nvim_create_buf(false, true)
	vim.bo[scratch_buf].bufhidden = "hide"
	return scratch_buf
end

--- Find fenced code blocks within a range of lines.
---@param bufnr integer
---@param start_row integer 0-indexed first line of docstring content
---@param end_row integer 0-indexed last line of docstring content
---@return { lang: string, fence_start: integer, code_start: integer, code_end: integer, fence_end: integer, indent: integer }[]
function M.find_blocks(bufnr, start_row, end_row)
	local lines = vim.api.nvim_buf_get_lines(bufnr, start_row, end_row + 1, false)
	local blocks = {}
	local open = nil

	for i, line in ipairs(lines) do
		if not open then
			-- Look for opening fence: ```lang
			local indent, lang = line:match("^(%s*)```(%w+)")
			if lang then
				open = {
					lang = lang,
					fence_start = start_row + i - 1, -- the ``` line itself
					code_start = start_row + i, -- line after the fence
					indent = #indent,
				}
			end
		else
			-- Look for closing fence: ```
			if line:match("^%s*```%s*$") then
				open.code_end = start_row + i - 2 -- line before the fence
				open.fence_end = start_row + i - 1 -- the closing ``` line
				if open.code_end >= open.code_start then
					table.insert(blocks, open)
				end
				open = nil
			end
		end
	end

	return blocks
end

--- Highlight a single code block by parsing it in a scratch buffer.
--- Applies DocstringCodeBlock bg on all lines (fences + code), and
--- blended treesitter highlights on code tokens.
---@param bufnr integer Target buffer
---@param ns integer Namespace for extmarks
---@param block { lang: string, fence_start: integer, code_start: integer, code_end: integer, fence_end: integer, indent: integer }
function M.highlight_block(bufnr, ns, block)
	local block_hl = resolve_hl("DocstringCodeBlock")
	local blend_factor = config.codeblock_blend or 0

	-- Apply DocstringCodeBlock on entire block (fences + code) for background
	for row = block.fence_start, block.fence_end do
		pcall(vim.api.nvim_buf_set_extmark, bufnr, ns, row, 0, {
			end_row = row + 1,
			hl_group = "DocstringCodeBlock",
			hl_eol = true,
			priority = config.priority - 2,
		})
	end

	-- Check if treesitter parser is available for this language
	local lang_ok = pcall(vim.treesitter.language.add, block.lang)
	if not lang_ok then
		return
	end

	-- Get code lines and strip common indent
	local raw_lines = vim.api.nvim_buf_get_lines(bufnr, block.code_start, block.code_end + 1, false)
	local code_lines = {}
	for _, line in ipairs(raw_lines) do
		local stripped = line:sub(block.indent + 1)
		table.insert(code_lines, stripped)
	end

	-- Write to scratch buffer
	local scratch = get_scratch()
	vim.api.nvim_buf_set_lines(scratch, 0, -1, false, code_lines)
	vim.bo[scratch].filetype = block.lang

	-- Parse with treesitter
	local ok, parser = pcall(vim.treesitter.get_parser, scratch, block.lang)
	if not ok or not parser then
		return
	end

	local trees = parser:parse()
	if not trees or not trees[1] then
		return
	end

	-- Get the highlight query for this language
	local qok, query = pcall(vim.treesitter.query.get, block.lang, "highlights")
	if not qok or not query then
		return
	end

	-- Collect captures, keeping only the most specific per range.
	-- Treesitter emits captures from generic to specific, so later wins.
	local highlights = {}
	for id, node in query:iter_captures(trees[1]:root(), scratch) do
		local name = query.captures[id]
		local sr, sc, er, ec = node:range()
		if sr == er then
			local key = ("%d:%d:%d"):format(sr, sc, ec)
			highlights[key] = { row = sr, sc = sc, ec = ec, name = name }
		end
	end

	-- Apply blended extmarks to the real buffer
	for _, hl in pairs(highlights) do
		local real_row = block.code_start + hl.row
		local real_sc = hl.sc + block.indent
		local real_ec = hl.ec + block.indent
		local ts_group = "@" .. hl.name .. "." .. block.lang
		local hl_group = get_blended_group(ts_group, block_hl, blend_factor)
		pcall(vim.api.nvim_buf_set_extmark, bufnr, ns, real_row, real_sc, {
			end_col = real_ec,
			hl_group = hl_group,
			priority = config.priority - 1,
		})
	end
end

--- Highlight all fenced code blocks within a docstring range.
---@param bufnr integer Target buffer
---@param ns integer Namespace for extmarks
---@param start_row integer 0-indexed first line of docstring content
---@param end_row integer 0-indexed last line of docstring content
function M.highlight(bufnr, ns, start_row, end_row)
	local blocks = M.find_blocks(bufnr, start_row, end_row)
	for _, block in ipairs(blocks) do
		M.highlight_block(bufnr, ns, block)
	end
end

return M

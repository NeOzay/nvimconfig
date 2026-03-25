---@namespace Ozay.Hover
--- Extmark-based syntax highlighting for code blocks in hover windows.
--- Dispatches to per-language tokenizers in `lsp.hover.highlight.<lang>`.
local M = {}

local ns = vim.api.nvim_create_namespace("hover_hl")

---@type table<string, table|false>
local tokenizers = {}

---@param lang string
---@return table|false
local function get_tokenizer(lang)
	if tokenizers[lang] == nil then
		local ok, mod = pcall(require, "lsp.hover.highlight." .. lang)
		tokenizers[lang] = ok and mod or false
	end
	return tokenizers[lang]
end

--- Find the first fenced code block (always at the top of the buffer).
---@param bufnr integer
---@return { lang: string, end_line: integer }?
local function find_first_code_block(bufnr)
	local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)

	local lang = lines[1] and lines[1]:match("^```(%w+)")
	if not lang then
		return nil
	end

	for i = 2, #lines do
		if lines[i]:match("^```%s*$") then
			return { lang = lang, end_line = i - 1 } -- 0-indexed, exclusive
		end
	end

	return nil
end

--- Apply syntax highlighting extmarks on the first code block,
--- strip the language from fences and conceal them.
---@param bufnr integer
---@return integer removed  number of fence lines concealed
function M.apply(bufnr)
	vim.api.nvim_buf_clear_namespace(bufnr, ns, 0, -1)

	local block = find_first_code_block(bufnr)
	if not block then
		return 0
	end

	local tok = get_tokenizer(block.lang)
	if tok then
		-- Content lines start at line 1 (0-indexed), after the opening fence at line 0
		tok.highlight(bufnr, ns, 1, block.end_line)

		-- Replace language-tagged fences with plain fences (prevents TS injection)
		vim.api.nvim_buf_set_lines(bufnr, 0, 1, false, { "```" })
		-- Conceal both fence lines
		vim.api.nvim_buf_set_extmark(bufnr, ns, 0, 0, { conceal_lines = "" })
		vim.api.nvim_buf_set_extmark(bufnr, ns, block.end_line, 0, { conceal_lines = "" })
		return 2
	end

	return 0
end

return M

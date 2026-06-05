---@namespace Ozay.Hover
--- Tokenizer for Python signatures in hover code blocks.
--- Treesitter handles most highlighting; this adds labels and function names
--- that Treesitter can't parse due to the `(label) def ...` prefix format.
local M = {}

-- stylua: ignore start
local KEYWORD     = "@keyword.python"
local FUNC        = "@function.python"
local FUNC_METHOD = "@function.method.python"
local PARAM       = "@variable.parameter.python"
-- stylua: ignore end

---@type table<string, true>
local LABELS = {
	method = true,
	["function"] = true,
	variable = true,
	class = true,
	parameter = true,
	module = true,
	property = true,
	overload = true,
}

---@param bufnr integer
---@param ns integer
---@param start_line integer  0-indexed, first content line
---@param end_line integer    0-indexed, exclusive
function M.highlight(bufnr, ns, start_line, end_line)
	local lines = vim.api.nvim_buf_get_lines(bufnr, start_line, end_line, false)

	for i, line in ipairs(lines) do
		local row = start_line + i - 1
		local is_method = false

		-- 1. Label (method), (variable), (class), etc. au début de la ligne
		local ls, le, label = line:find("^%s*%((%a+)%)")
		if ls and LABELS[label] then
			vim.api.nvim_buf_set_extmark(bufnr, ns, row, ls - 1, {
				end_col = le,
				hl_group = KEYWORD,
				priority = 200,
			})
			is_method = (label == "method")

			-- 1b. Nom du paramètre après "(parameter) "
			if label == "parameter" then
				local name = line:sub(le + 1):match("^%s*([%a_][%w_]*)")
				if name then
					local name_col = le + (line:sub(le + 1):find("[%a_]") or 1) - 1
					vim.api.nvim_buf_set_extmark(bufnr, ns, row, name_col, {
						end_col = name_col + #name,
						hl_group = PARAM,
						priority = 200,
					})
				end
			end
		end

		-- 2. Nom de la fonction/méthode après `def`
		local _, def_e = line:find("def%s+")
		if def_e then
			local name = line:sub(def_e + 1):match("^([%a_][%w_]*)")
			if name then
				-- def_e est 1-based ; col extmark est 0-based → def_e = col du 1er char du nom
				vim.api.nvim_buf_set_extmark(bufnr, ns, row, def_e, {
					end_col = def_e + #name,
					hl_group = is_method and FUNC_METHOD or FUNC,
					priority = 200,
				})
			end
		end
	end
end

return M

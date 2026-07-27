local new_set = MiniTest.new_set
local expect = MiniTest.expect

local M = require("docstring-highlight")
local highlight_line = M._highlight_line
local ns = M._ns

local buf

--- Get extmarks set on a given row.
local function get_marks(row)
	local marks = vim.api.nvim_buf_get_extmarks(buf, ns, { row, 0 }, { row, -1 }, { details = true })
	local result = {}
	for _, m in ipairs(marks) do
		table.insert(result, {
			col_start = m[3],
			col_end = m[4].end_col,
			hl_group = m[4].hl_group,
		})
	end
	return result
end

--- Run highlight_line on a single line and return its extmarks.
local function test_line(line)
	vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)
	vim.api.nvim_buf_set_lines(buf, 0, -1, false, { line })
	highlight_line(buf, 0, line)
	return get_marks(0)
end

--- Filter marks by highlight group.
local function marks_by_group(marks, group)
	return vim.tbl_filter(function(m)
		return m.hl_group == group
	end, marks)
end

local T = new_set({
	hooks = {
		pre_once = function()
			buf = vim.api.nvim_create_buf(false, true)
		end,
		pre_case = function()
			vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)
		end,
		post_once = function()
			vim.api.nvim_buf_delete(buf, { force = true })
		end,
	},
})

-- =============================================================================
-- Section headers
-- =============================================================================

T["section headers"] = new_set()

T["section headers"]["Args:"] = function()
	local marks = test_line("    Args:")
	expect.equality(#marks, 1)
	expect.equality(marks[1], { col_start = 4, col_end = 9, hl_group = "DocstringSection" })
end

T["section headers"]["Returns:"] = function()
	local marks = test_line("    Returns:")
	expect.equality(#marks, 1)
	expect.equality(marks[1], { col_start = 4, col_end = 12, hl_group = "DocstringSection" })
end

T["section headers"]["See Also:"] = function()
	local marks = test_line("    See Also:")
	expect.equality(#marks, 1)
	expect.equality(marks[1], { col_start = 4, col_end = 13, hl_group = "DocstringSection" })
end

T["section headers"]["Keyword Arguments:"] = function()
	local marks = test_line("    Keyword Arguments:")
	expect.equality(#marks, 1)
	expect.equality(marks[1], { col_start = 4, col_end = 22, hl_group = "DocstringSection" })
end

T["section headers"]["Examples:"] = function()
	local marks = test_line("    Examples:")
	expect.equality(#marks, 1)
	expect.equality(marks[1], { col_start = 4, col_end = 13, hl_group = "DocstringSection" })
end

T["section headers"]["Example:"] = function()
	local marks = test_line("    Example:")
	expect.equality(#marks, 1)
	expect.equality(marks[1], { col_start = 4, col_end = 12, hl_group = "DocstringSection" })
end

T["section headers"]["Yields:"] = function()
	local marks = test_line("    Yields:")
	expect.equality(#marks, 1)
	expect.equality(marks[1], { col_start = 4, col_end = 11, hl_group = "DocstringSection" })
end

T["section headers"]["no indent"] = function()
	local marks = test_line("Args:")
	expect.equality(#marks, 1)
	expect.equality(marks[1], { col_start = 0, col_end = 5, hl_group = "DocstringSection" })
end

T["section headers"]["not a keyword"] = function()
	local marks = test_line("    Hello:")
	expect.equality(#marks_by_group(marks, "DocstringSection"), 0)
end

T["section headers"]["lowercase rejected"] = function()
	local marks = test_line("    args:")
	expect.equality(#marks_by_group(marks, "DocstringSection"), 0)
end

T["section headers"]["section wins over param pattern"] = function()
	local marks = test_line("    Raises:")
	expect.equality(#marks, 1)
	expect.equality(marks[1], { col_start = 4, col_end = 11, hl_group = "DocstringSection" })
end

-- =============================================================================
-- Generic headings
-- =============================================================================

T["generic heading"] = new_set()

T["generic heading"]["OBLIGATOIRE:"] = function()
	local marks = test_line("        OBLIGATOIRE: Doit être implémenté par toutes les sous-classes.")
	local hm = marks_by_group(marks, "DocstringHeading")
	expect.equality(#hm, 1)
	expect.equality(hm[1], { col_start = 8, col_end = 20, hl_group = "DocstringHeading" })
end

T["generic heading"]["Important:"] = function()
	local marks = test_line("        Important: This is critical.")
	local hm = marks_by_group(marks, "DocstringHeading")
	expect.equality(#hm, 1)
	expect.equality(hm[1], { col_start = 8, col_end = 18, hl_group = "DocstringHeading" })
end

T["generic heading"]["not triggered on bare word"] = function()
	local marks = test_line("    Hello:")
	expect.equality(#marks_by_group(marks, "DocstringHeading"), 0)
end

T["generic heading"]["not triggered on lowercase"] = function()
	local marks = test_line("        obligatoire: Doit être implémenté.")
	expect.equality(#marks_by_group(marks, "DocstringHeading"), 0)
end

T["generic heading"]["not triggered without text after colon"] = function()
	local marks = test_line("        OBLIGATOIRE:")
	expect.equality(#marks_by_group(marks, "DocstringHeading"), 0)
end

-- =============================================================================
-- Param with type
-- =============================================================================

T["param with type"] = new_set()

T["param with type"]["param (type):"] = function()
	local marks = test_line("        param1 (int): The first parameter.")
	expect.equality(marks[1], { col_start = 8, col_end = 14, hl_group = "DocstringParam" })
	expect.equality(marks[2], { col_start = 16, col_end = 19, hl_group = "DocstringType" })
end

T["param with type"]["param (Optional[str]):"] = function()
	local marks = test_line("        param2 (Optional[str]): The second parameter.")
	expect.equality(marks[1], { col_start = 8, col_end = 14, hl_group = "DocstringParam" })
	expect.equality(marks[2], { col_start = 16, col_end = 29, hl_group = "DocstringType" })
end

T["param with type"]["*args (tuple):"] = function()
	local marks = test_line("        *args (tuple): Variable length.")
	expect.equality(marks[1], { col_start = 8, col_end = 13, hl_group = "DocstringParam" })
	expect.equality(marks[2], { col_start = 15, col_end = 20, hl_group = "DocstringType" })
end

T["param with type"]["**kwargs (dict):"] = function()
	local marks = test_line("        **kwargs (dict): Keyword args.")
	expect.equality(marks[1], { col_start = 8, col_end = 16, hl_group = "DocstringParam" })
	expect.equality(marks[2], { col_start = 18, col_end = 22, hl_group = "DocstringType" })
end

T["param with type"]["- item (str):"] = function()
	local marks = test_line("        - item (str): A list item.")
	expect.equality(marks[1], { col_start = 10, col_end = 14, hl_group = "DocstringParam" })
	expect.equality(marks[2], { col_start = 16, col_end = 19, hl_group = "DocstringType" })
end

T["param with type"]["param[0] (int):"] = function()
	local marks = test_line("        param[0] (int): Subscript param.")
	expect.equality(marks[1], { col_start = 8, col_end = 16, hl_group = "DocstringParam" })
	expect.equality(marks[2], { col_start = 18, col_end = 21, hl_group = "DocstringType" })
end

T["param with type"]["param (List[str]):"] = function()
	local marks = test_line("        param3 (List[str]): Description.")
	expect.equality(marks[1], { col_start = 8, col_end = 14, hl_group = "DocstringParam" })
	expect.equality(marks[2], { col_start = 16, col_end = 25, hl_group = "DocstringType" })
end

T["param with type"]["underscore name with type: final_result (dict):"] = function()
	local marks = test_line("        final_result (dict): Dictionnaire des traductions.")
	expect.equality(marks[1], { col_start = 8, col_end = 20, hl_group = "DocstringParam" })
	expect.equality(marks[2], { col_start = 22, col_end = 26, hl_group = "DocstringType" })
end

-- =============================================================================
-- Param without type
-- =============================================================================

T["param without type"] = new_set()

T["param without type"]["param:"] = function()
	local marks = test_line("        param1: The first parameter.")
	local pm = marks_by_group(marks, "DocstringParam")
	expect.equality(#pm, 1)
	expect.equality(pm[1], { col_start = 8, col_end = 14, hl_group = "DocstringParam" })
end

T["param without type"]["*args:"] = function()
	local marks = test_line("        *args: Variable length argument list.")
	local pm = marks_by_group(marks, "DocstringParam")
	expect.equality(#pm, 1)
	expect.equality(pm[1], { col_start = 8, col_end = 13, hl_group = "DocstringParam" })
end

T["param without type"]["**kwargs:"] = function()
	local marks = test_line("        **kwargs: Miscellaneous.")
	local pm = marks_by_group(marks, "DocstringParam")
	expect.equality(#pm, 1)
	expect.equality(pm[1], { col_start = 8, col_end = 16, hl_group = "DocstringParam" })
end

T["param without type"]["- item:"] = function()
	local marks = test_line("        - item: A list item.")
	local pm = marks_by_group(marks, "DocstringParam")
	expect.equality(#pm, 1)
	expect.equality(pm[1], { col_start = 10, col_end = 14, hl_group = "DocstringParam" })
end

T["param without type"]["param[key]:"] = function()
	local marks = test_line("        param[key]: Subscript param.")
	local pm = marks_by_group(marks, "DocstringParam")
	expect.equality(#pm, 1)
	expect.equality(pm[1], { col_start = 8, col_end = 18, hl_group = "DocstringParam" })
end

T["param without type"]["underscore name: final_result"] = function()
	local marks = test_line("        final_result: Dictionnaire des traductions.")
	local pm = marks_by_group(marks, "DocstringParam")
	expect.equality(#pm, 1)
	expect.equality(pm[1], { col_start = 8, col_end = 20, hl_group = "DocstringParam" })
end

T["param without type"]["single char rejected"] = function()
	local marks = test_line("        x: Too short.")
	expect.equality(#marks_by_group(marks, "DocstringParam"), 0)
end

T["param without type"]["ALLCAPS rejected"] = function()
	local marks = test_line("        OK: Not a param.")
	expect.equality(#marks_by_group(marks, "DocstringParam"), 0)
end

T["param without type"]["ALLCAPS with underscore rejected"] = function()
	local marks = test_line("        OBLIGATOIRE: Doit être implémenté.")
	expect.equality(#marks_by_group(marks, "DocstringParam"), 0)
end

T["param without type"]["insufficient indent rejected"] = function()
	local marks = test_line("  x: Not enough indent.")
	expect.equality(#marks_by_group(marks, "DocstringParam"), 0)
end

-- =============================================================================
-- Inline code
-- =============================================================================

T["inline code"] = new_set()

T["inline code"]["single inline code"] = function()
	local marks = test_line("    Use `param1` for this.")
	local cm = marks_by_group(marks, "DocstringInlineCode")
	expect.equality(#cm, 1)
	expect.equality(cm[1], { col_start = 8, col_end = 16, hl_group = "DocstringInlineCode" })
end

T["inline code"]["multiple inline codes"] = function()
	local marks = test_line("    Use `param1` and `param2` here.")
	local cm = marks_by_group(marks, "DocstringInlineCode")
	expect.equality(#cm, 2)
	expect.equality(cm[1], { col_start = 8, col_end = 16, hl_group = "DocstringInlineCode" })
	expect.equality(cm[2], { col_start = 21, col_end = 29, hl_group = "DocstringInlineCode" })
end

T["inline code"]["no inline code in plain text"] = function()
	local marks = test_line("    Just some regular text here.")
	expect.equality(#marks_by_group(marks, "DocstringInlineCode"), 0)
end

T["inline code"]["empty backticks ignored"] = function()
	local marks = test_line("    Empty `` should not match.")
	expect.equality(#marks_by_group(marks, "DocstringInlineCode"), 0)
end

T["inline code"]["param line also has inline code"] = function()
	local marks = test_line("        param1: The `value` to use.")
	expect.equality(#marks_by_group(marks, "DocstringParam"), 1)
	expect.equality(#marks_by_group(marks, "DocstringInlineCode"), 1)
end

T["inline code"]["double backticks"] = function()
	local marks = test_line("    Use ``param1`` for this.")
	local cm = marks_by_group(marks, "DocstringInlineCode")
	expect.equality(#cm, 1)
	expect.equality(cm[1], { col_start = 8, col_end = 18, hl_group = "DocstringInlineCode" })
end

T["inline code"]["multiple double backticks"] = function()
	local marks = test_line("    Use ``foo`` and ``bar`` here.")
	local cm = marks_by_group(marks, "DocstringInlineCode")
	expect.equality(#cm, 2)
	expect.equality(cm[1], { col_start = 8, col_end = 15, hl_group = "DocstringInlineCode" })
	expect.equality(cm[2], { col_start = 20, col_end = 27, hl_group = "DocstringInlineCode" })
end

T["inline code"]["mixed single and double backticks"] = function()
	local marks = test_line("    Use ``foo`` and `bar` here.")
	local cm = marks_by_group(marks, "DocstringInlineCode")
	expect.equality(#cm, 2)
	expect.equality(cm[1], { col_start = 8, col_end = 15, hl_group = "DocstringInlineCode" })
	expect.equality(cm[2], { col_start = 20, col_end = 25, hl_group = "DocstringInlineCode" })
end

T["inline code"]["double before single in scan order"] = function()
	local marks = test_line("    Use `foo` and ``bar`` here.")
	local cm = marks_by_group(marks, "DocstringInlineCode")
	expect.equality(#cm, 2)
	expect.equality(cm[1], { col_start = 8, col_end = 13, hl_group = "DocstringInlineCode" })
	expect.equality(cm[2], { col_start = 18, col_end = 25, hl_group = "DocstringInlineCode" })
end

T["inline code"]["empty double backticks ignored"] = function()
	local marks = test_line("    Empty ```` should not match.")
	expect.equality(#marks_by_group(marks, "DocstringInlineCode"), 0)
end

return T

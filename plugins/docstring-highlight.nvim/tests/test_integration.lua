local new_set = MiniTest.new_set
local expect = MiniTest.expect

local M = require("docstring-highlight")
local ns = M._ns
local refresh = M._refresh

--- Create a scratch Python buffer with given lines.
---@param lines string[]
---@return integer bufnr
local function make_py_buf(lines)
	local buf = vim.api.nvim_create_buf(false, true)
	vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
	vim.bo[buf].filetype = "python"
	return buf
end

--- Return all extmarks on a buffer, sorted by row then col.
---@param bufnr integer
---@return table[]
local function get_all_marks(bufnr)
	local marks = vim.api.nvim_buf_get_extmarks(bufnr, ns, 0, -1, { details = true })
	local result = {}
	for _, m in ipairs(marks) do
		table.insert(result, {
			row = m[2],
			col_start = m[3],
			col_end = m[4].end_col,
			hl_group = m[4].hl_group,
		})
	end
	return result
end

--- Filter marks by highlight group.
---@param marks table[]
---@param group string
---@return table[]
local function by_group(marks, group)
	return vim.tbl_filter(function(m)
		return m.hl_group == group
	end, marks)
end

local T = new_set({
	hooks = {
		post_case = function()
			vim.cmd("%bwipeout!")
		end,
	},
})

-- =============================================================================
-- Détection treesitter : quels strings sont des docstrings
-- =============================================================================

T["treesitter detection"] = new_set()

T["treesitter detection"]["function docstring detected"] = function()
	local buf = make_py_buf({
		"def foo():",
		'    """',
		"    Args:",
		"        x (int): The value.",
		'    """',
		"    pass",
	})
	refresh(buf)
	local marks = get_all_marks(buf)
	expect.no_equality(#marks, 0)
	local sections = by_group(marks, "DocstringSection")
	expect.equality(#sections, 1)
	expect.equality(sections[1].row, 2)
end

T["treesitter detection"]["class docstring detected"] = function()
	local buf = make_py_buf({
		"class Foo:",
		'    """',
		"    Attributes:",
		"        x (int): A field.",
		'    """',
		"    pass",
	})
	refresh(buf)
	local sections = by_group(get_all_marks(buf), "DocstringSection")
	expect.equality(#sections, 1)
	expect.equality(sections[1].row, 2)
end

T["treesitter detection"]["module docstring detected"] = function()
	local buf = make_py_buf({
		'"""',
		"Module description.",
		"",
		"Returns:",
		'"""',
	})
	refresh(buf)
	local sections = by_group(get_all_marks(buf), "DocstringSection")
	expect.equality(#sections, 1)
	expect.equality(sections[1].row, 3)
end

T["treesitter detection"]["second string in function NOT a docstring"] = function()
	local buf = make_py_buf({
		"def foo():",
		"    x = 1",
		'    """',
		"    Args:",
		'    """',
	})
	refresh(buf)
	-- The string is NOT the first statement, so no docstring detection
	local sections = by_group(get_all_marks(buf), "DocstringSection")
	expect.equality(#sections, 0)
end

T["treesitter detection"]["standalone string NOT a docstring"] = function()
	local buf = make_py_buf({
		"x = 1",
		'y = """',
		"Args:",
		'"""',
	})
	refresh(buf)
	local sections = by_group(get_all_marks(buf), "DocstringSection")
	expect.equality(#sections, 0)
end

T["treesitter detection"]["nested function docstring detected"] = function()
	local buf = make_py_buf({
		"def outer():",
		'    """Outer."""',
		"    def inner():",
		'        """',
		"        Returns:",
		'        """',
		"        pass",
	})
	refresh(buf)
	local sections = by_group(get_all_marks(buf), "DocstringSection")
	expect.equality(#sections, 1)
	expect.equality(sections[1].row, 4)
end

-- =============================================================================
-- Positionnement des extmarks (intégration ligne × colonne)
-- =============================================================================

T["extmark positions"] = new_set()

T["extmark positions"]["section header row and col"] = function()
	local buf = make_py_buf({
		"def foo():",      -- row 0
		'    """',         -- row 1
		"    Args:",       -- row 2
		'    """',         -- row 3
	})
	refresh(buf)
	local sections = by_group(get_all_marks(buf), "DocstringSection")
	expect.equality(#sections, 1)
	expect.equality(sections[1], { row = 2, col_start = 4, col_end = 9, hl_group = "DocstringSection" })
end

T["extmark positions"]["param name and type on correct row"] = function()
	local buf = make_py_buf({
		"def foo():",              -- row 0
		'    """',                 -- row 1
		"    Args:",               -- row 2
		"        x (int): Val.",   -- row 3
		'    """',                 -- row 4
	})
	refresh(buf)
	local marks = get_all_marks(buf)
	local params = by_group(marks, "DocstringParam")
	local types = by_group(marks, "DocstringType")
	expect.equality(#params, 1)
	expect.equality(params[1].row, 3)
	expect.equality(params[1].col_start, 8)
	expect.equality(params[1].col_end, 9)
	expect.equality(#types, 1)
	expect.equality(types[1].row, 3)
end

T["extmark positions"]["inline code on correct row"] = function()
	local buf = make_py_buf({
		"def foo():",              -- row 0
		'    """',                 -- row 1
		"    Use `bar` here.",     -- row 2
		'    """',                 -- row 3
	})
	refresh(buf)
	local codes = by_group(get_all_marks(buf), "DocstringInlineCode")
	expect.equality(#codes, 1)
	expect.equality(codes[1].row, 2)
	expect.equality(codes[1].col_start, 8)
	expect.equality(codes[1].col_end, 13)
end

T["extmark positions"]["multiple sections across rows"] = function()
	local buf = make_py_buf({
		"def foo():",         -- row 0
		'    """',            -- row 1
		"    Args:",          -- row 2
		"        x: Val.",    -- row 3
		"    Returns:",       -- row 4
		"        int.",       -- row 5
		"    Raises:",        -- row 6
		'    """',            -- row 7
	})
	refresh(buf)
	local sections = by_group(get_all_marks(buf), "DocstringSection")
	expect.equality(#sections, 3)
	expect.equality(sections[1].row, 2)
	expect.equality(sections[2].row, 4)
	expect.equality(sections[3].row, 6)
end

-- =============================================================================
-- Refresh idempotent (pas de doublon sur re-parse)
-- =============================================================================

T["refresh is idempotent"] = new_set()

T["refresh is idempotent"]["calling refresh twice gives same marks"] = function()
	local buf = make_py_buf({
		"def foo():",
		'    """',
		"    Args:",
		"        x (int): Val.",
		'    """',
	})
	refresh(buf)
	local marks1 = get_all_marks(buf)
	refresh(buf)
	local marks2 = get_all_marks(buf)
	expect.equality(marks1, marks2)
end

-- =============================================================================
-- Style Google : cas complets
-- =============================================================================

T["google style full docstring"] = new_set()

T["google style full docstring"]["all elements highlighted correctly"] = function()
	-- Note: Returns/Raises descriptions use forms that don't trigger the param
	-- pattern: "The ..." has no colon, "IOError" starts with two uppercase letters
	-- (matched by ^%u%u so rejected as param).
	local buf = make_py_buf({
		"def process(value, items):",      -- row 0
		'    """Process items.',            -- row 1
		"",                                 -- row 2
		"    Args:",                        -- row 3
		"        value (int): The val.",    -- row 4
		"        items: A list.",           -- row 5
		"",                                 -- row 6
		"    Returns:",                     -- row 7
		"        The processed list.",      -- row 8
		"",                                 -- row 9
		"    Raises:",                      -- row 10
		"        IOError: If bad.",         -- row 11
		'    """',                          -- row 12
	})
	refresh(buf)
	local marks = get_all_marks(buf)

	local sections = by_group(marks, "DocstringSection")
	expect.equality(#sections, 3)
	local section_rows = vim.tbl_map(function(m) return m.row end, sections)
	expect.equality(section_rows, { 3, 7, 10 })

	local params = by_group(marks, "DocstringParam")
	expect.equality(#params, 2)
	expect.equality(params[1].row, 4)
	expect.equality(params[2].row, 5)

	local types = by_group(marks, "DocstringType")
	expect.equality(#types, 1)
	expect.equality(types[1].row, 4)
end

T["google style full docstring"]["*args and **kwargs detected"] = function()
	local buf = make_py_buf({
		"def foo(*args, **kwargs):",      -- row 0
		'    """',                         -- row 1
		"    Args:",                       -- row 2
		"        *args (tuple): Pos.",     -- row 3
		"        **kwargs (dict): Kw.",    -- row 4
		'    """',                         -- row 5
	})
	refresh(buf)
	local marks = get_all_marks(buf)
	local params = by_group(marks, "DocstringParam")
	expect.equality(#params, 2)
	expect.equality(params[1].row, 3)
	expect.equality(params[2].row, 4)
end

T["google style full docstring"]["inline code in description"] = function()
	local buf = make_py_buf({
		"def foo():",                         -- row 0
		'    """',                             -- row 1
		"    Use `None` or `True` here.",      -- row 2
		'    """',                             -- row 3
	})
	refresh(buf)
	local codes = by_group(get_all_marks(buf), "DocstringInlineCode")
	expect.equality(#codes, 2)
end

return T

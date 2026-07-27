local new_set = MiniTest.new_set
local expect = MiniTest.expect

local codeblocks = require("docstring-highlight.codeblocks")

local function make_buf(lines)
	local buf = vim.api.nvim_create_buf(false, true)
	vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
	return buf
end

local T = new_set()

-- =============================================================================
-- find_blocks
-- =============================================================================

T["find_blocks"] = new_set()

T["find_blocks"]["detects a single python block"] = function()
	local lines = {
		"    Docstring text.",
		"    ```python",
		"        x = 1",
		"        y = 2",
		"    ```",
		"    More text.",
	}
	local buf = make_buf(lines)
	local blocks = codeblocks.find_blocks(buf, 0, #lines - 1)
	expect.equality(#blocks, 1)
	expect.equality(blocks[1].lang, "python")
	expect.equality(blocks[1].code_start, 2)
	expect.equality(blocks[1].code_end, 3)
	expect.equality(blocks[1].indent, 4)
	vim.api.nvim_buf_delete(buf, { force = true })
end

T["find_blocks"]["detects multiple blocks"] = function()
	local lines = {
		"    ```python",
		"        pass",
		"    ```",
		"    text",
		"    ```lua",
		"        local x = 1",
		"    ```",
	}
	local buf = make_buf(lines)
	local blocks = codeblocks.find_blocks(buf, 0, #lines - 1)
	expect.equality(#blocks, 2)
	expect.equality(blocks[1].lang, "python")
	expect.equality(blocks[2].lang, "lua")
	vim.api.nvim_buf_delete(buf, { force = true })
end

T["find_blocks"]["ignores block without language"] = function()
	local lines = {
		"    ```",
		"        x = 1",
		"    ```",
	}
	local buf = make_buf(lines)
	local blocks = codeblocks.find_blocks(buf, 0, #lines - 1)
	expect.equality(#blocks, 0)
	vim.api.nvim_buf_delete(buf, { force = true })
end

T["find_blocks"]["ignores unclosed block"] = function()
	local lines = {
		"    ```python",
		"        x = 1",
		"    no closing fence",
	}
	local buf = make_buf(lines)
	local blocks = codeblocks.find_blocks(buf, 0, #lines - 1)
	expect.equality(#blocks, 0)
	vim.api.nvim_buf_delete(buf, { force = true })
end

T["find_blocks"]["handles empty block"] = function()
	local lines = {
		"    ```python",
		"    ```",
	}
	local buf = make_buf(lines)
	local blocks = codeblocks.find_blocks(buf, 0, #lines - 1)
	expect.equality(#blocks, 0)
	vim.api.nvim_buf_delete(buf, { force = true })
end

-- =============================================================================
-- highlight_block
-- =============================================================================

T["highlight_block"] = new_set()

T["highlight_block"]["applies treesitter highlights to python code"] = function()
	local test_ns = vim.api.nvim_create_namespace("test_codeblocks")
	local lines = {
		"    Docstring.",
		"    ```python",
		"        def foo():",
		"            pass",
		"    ```",
	}
	local buf = make_buf(lines)
	local blocks = codeblocks.find_blocks(buf, 0, #lines - 1)
	expect.equality(#blocks, 1)

	codeblocks.highlight_block(buf, test_ns, blocks[1])

	local marks = vim.api.nvim_buf_get_extmarks(buf, test_ns, 0, -1, { details = true })
	expect.no_equality(#marks, 0)

	local bg_marks = vim.tbl_filter(function(m)
		return m[4].hl_group == "DocstringCodeBlock"
	end, marks)
	local syntax_marks = vim.tbl_filter(function(m)
		return m[4].hl_group ~= "DocstringCodeBlock"
	end, marks)
	expect.equality(#bg_marks, 4)
	expect.no_equality(#syntax_marks, 0)
	for _, m in ipairs(syntax_marks) do
		local row = m[2]
		expect.equality(row >= 2 and row <= 3, true)
	end

	vim.api.nvim_buf_delete(buf, { force = true })
end

T["highlight_block"]["skips unknown language gracefully"] = function()
	local test_ns = vim.api.nvim_create_namespace("test_codeblocks_unknown")
	local lines = {
		"    ```unknownlang",
		"        something",
		"    ```",
	}
	local buf = make_buf(lines)
	local blocks = codeblocks.find_blocks(buf, 0, #lines - 1)
	expect.equality(#blocks, 1)

	-- Should not error
	codeblocks.highlight_block(buf, test_ns, blocks[1])

	local marks = vim.api.nvim_buf_get_extmarks(buf, test_ns, 0, -1, { details = true })
	local syntax_marks = vim.tbl_filter(function(m)
		return m[4].hl_group ~= "DocstringCodeBlock"
	end, marks)
	expect.equality(#syntax_marks, 0)
	vim.api.nvim_buf_delete(buf, { force = true })
end

T["highlight_block"]["blended groups combine fg and bg"] = function()
	local test_ns = vim.api.nvim_create_namespace("test_codeblocks_blend")
	vim.api.nvim_set_hl(0, "DocstringCodeBlock", { bg = 0x1a1a2e })
	local lines = {
		"    ```python",
		"        def foo():",
		"    ```",
	}
	local buf = make_buf(lines)
	local blocks = codeblocks.find_blocks(buf, 0, #lines - 1)
	codeblocks.clear_cache()
	codeblocks.highlight_block(buf, test_ns, blocks[1])

	local marks = vim.api.nvim_buf_get_extmarks(buf, test_ns, 0, -1, { details = true })
	local blended = vim.tbl_filter(function(m)
		return m[4].hl_group:match("^DocstringCB_")
	end, marks)
	expect.no_equality(#blended, 0)

	local hl = vim.api.nvim_get_hl(0, { name = blended[1][4].hl_group, link = false })
	expect.equality(hl.bg, 0x1a1a2e)

	vim.api.nvim_buf_delete(buf, { force = true })
end

return T

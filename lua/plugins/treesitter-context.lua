---@type LazySpec
return {
	"nvim-treesitter/nvim-treesitter-context",
	-- enabled = false,
	event = "BufEnter",
	opts = {
		enable = true,
		max_lines = 0,
		min_window_height = 0,
		line_numbers = true,
		multiline_threshold = 20,
		trim_scope = "outer",
		mode = "topline",
		separator = nil,
		zindex = 20,
		on_attach = function(bufnr)
			return vim.bo[bufnr].filetype ~= "markdown"
		end,
	},
	config = function(_, opts)
		local tsc = require("treesitter-context")
		tsc.setup(opts)

		-- Monkey-patch context.get to support LuaDoc @class/@field annotations
		local context = require("treesitter-context.context")
		local original_get = context.get

		context.get = function(winid)
			local ranges, lines = original_get(winid)

			-- Only process Lua files
			winid = winid or vim.api.nvim_get_current_win()
			local bufnr = vim.api.nvim_win_get_buf(winid)
			if vim.bo[bufnr].filetype ~= "lua" then
				return ranges, lines
			end

			-- Get topline (first visible line) - this is what treesitter-context uses in topline mode
			local top_line = vim.fn.line("w0", winid) - 1 -- 0-indexed

			-- Check lines starting from topline
			local check_line = top_line
			local line_count = vim.api.nvim_buf_line_count(bufnr)

			-- Find if we're in a @field block by checking lines from topline
			local current_line_text = ""
			if check_line >= 0 and check_line < line_count then
				current_line_text = vim.api.nvim_buf_get_lines(bufnr, check_line, check_line + 1, false)[1] or ""
			end

			-- Check if the topline is a LuaDoc line (@field, comment, or empty ---)
			local is_luadoc_line = current_line_text:match("^%s*%-%-%-")
			local is_class_line = current_line_text:match("^%s*%-%-%-@class")
			if not is_luadoc_line or is_class_line then
				return ranges, lines
			end

			-- Find the @class line above
			local class_line_num = nil
			local class_line_text = nil
			for i = check_line - 1, 0, -1 do
				local line = vim.api.nvim_buf_get_lines(bufnr, i, i + 1, false)[1] or ""
				if line:match("^%s*%-%-%-@class") then
					class_line_num = i
					class_line_text = line
					break
				elseif not line:match("^%s*%-%-%-") then
					-- Stop if we hit a non-LuaDoc line (not starting with ---)
					break
				end
				-- Continue for @field, @param, comments (---text), empty (---)
			end

			if not class_line_num or not class_line_text then
				return ranges, lines
			end

			-- Create new context with @class line
			local class_range = { class_line_num, 0, class_line_num + 1, 0 }

			-- Initialize if nil
			ranges = ranges or {}
			lines = lines or {}

			-- Check if @class is not already in context
			local already_included = false
			for _, r in ipairs(ranges) do
				if r[1] == class_line_num then
					already_included = true
					break
				end
			end

			if not already_included then
				table.insert(ranges, 1, class_range)
				table.insert(lines, 1, class_line_text)
			end

			return ranges, lines
		end
	end,
}

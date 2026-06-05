local function setup_indent_guides()
	local ns = vim.api.nvim_create_namespace("ozay_tscontext_indent")
	local rainbow_hls = {
		"RainbowIndentGray",
		"RainbowIndentRed",
		"RainbowIndentYellow",
		"RainbowIndentBlue",
		"RainbowIndentOrange",
		"RainbowIndentGreen",
		"RainbowIndentViolet",
		"RainbowIndentCyan",
	}
	local rainbow_scope_hls = {
		"RainbowScopeGray",
		"RainbowScopeRed",
		"RainbowScopeYellow",
		"RainbowScopeBlue",
		"RainbowScopeOrange",
		"RainbowScopeGreen",
		"RainbowScopeViolet",
		"RainbowScopeCyan",
	}

	---@param buf integer
	---@return integer
	local function get_shiftwidth(buf)
		local sw = vim.bo[buf].shiftwidth
		if sw == 0 then
			sw = vim.bo[buf].tabstop
		end
		return sw > 0 and sw or 4
	end

	---@type table<string, boolean>
	local scope_hl_set = {}
	for _, hl in ipairs(rainbow_scope_hls) do
		scope_hl_set[hl] = true
	end

	-- Lit les extmarks ibl sur les premières lignes visibles pour trouver la colonne scope active.
	---@param src_buf integer
	---@param src_win integer
	---@return integer? scope_col byte-column where ibl draws RainbowScope*, nil if not found
	local function get_scope_col(src_buf, src_win)
		local namespaces = vim.api.nvim_get_namespaces()
		local ibl_ns = namespaces["indent_blankline"]
		if not ibl_ns then
			return nil
		end
		local topline = vim.api.nvim_win_call(src_win, function()
			return vim.fn.line("w0") - 1
		end)
		local marks = vim.api.nvim_buf_get_extmarks(
			src_buf,
			ibl_ns,
			{ topline, 0 },
			{ topline + 15, -1 },
			{ details = true }
		)
		for _, mark in ipairs(marks) do
			local details = mark[4]
			if details and details.virt_text then
				for _, vt in ipairs(details.virt_text) do
					if vt[2] and scope_hl_set[vt[2]] then
						return mark[3]
					end
				end
			end
		end
		return nil
	end

	---@param ctx_win integer
	---@param src_win integer
	local function draw_guides(ctx_win, src_win)
		local src_buf = vim.api.nvim_win_get_buf(src_win)
		local ctx_buf = vim.api.nvim_win_get_buf(ctx_win)
		vim.api.nvim_buf_clear_namespace(ctx_buf, ns, 0, -1)

		local sw = get_shiftwidth(src_buf)
		local ts = vim.bo[src_buf].tabstop > 0 and vim.bo[src_buf].tabstop or 8
		local scope_col = get_scope_col(src_buf, src_win)
		local lines = vim.api.nvim_buf_get_lines(ctx_buf, 0, -1, false)

		for lnum, line in ipairs(lines) do
			local level = 0
			local byte_col = 0
			local display_col = 0
			local next_stop = sw

			while byte_col < #line do
				local ch = line:sub(byte_col + 1, byte_col + 1)
				if ch == " " then
					if display_col == next_stop - sw then
						local hl = byte_col == scope_col
							and rainbow_scope_hls[(level % #rainbow_scope_hls) + 1]
							or rainbow_hls[(level % #rainbow_hls) + 1]
						vim.api.nvim_buf_set_extmark(ctx_buf, ns, lnum - 1, byte_col, {
							virt_text = { { "▎", hl } },
							virt_text_pos = "overlay",
							hl_mode = "combine",
							priority = 1,
						})
						level = level + 1
						next_stop = next_stop + sw
					end
					display_col = display_col + 1
					byte_col = byte_col + 1
				elseif ch == "\t" then
					local tab_width = ts - (display_col % ts)
					if display_col == next_stop - sw then
						local hl = byte_col == scope_col
							and rainbow_scope_hls[(level % #rainbow_scope_hls) + 1]
							or rainbow_hls[(level % #rainbow_hls) + 1]
						vim.api.nvim_buf_set_extmark(ctx_buf, ns, lnum - 1, byte_col, {
							virt_text = { { "▎", hl } },
							virt_text_pos = "overlay",
							hl_mode = "combine",
							priority = 1,
						})
						level = level + 1
						next_stop = next_stop + sw
					end
					display_col = display_col + tab_width
					byte_col = byte_col + 1
				else
					break
				end
			end
		end
	end

	---@type table<integer, boolean>
	local attached = {}

	---@param ctx_win integer
	local function attach_buf(ctx_win)
		local ctx_buf = vim.api.nvim_win_get_buf(ctx_win)
		if attached[ctx_buf] then
			return
		end
		attached[ctx_buf] = true

		vim.api.nvim_buf_attach(ctx_buf, false, {
			on_lines = vim.schedule_wrap(function(_, buf)
				if not vim.api.nvim_buf_is_valid(buf) then
					return
				end
				for _, win in ipairs(vim.api.nvim_list_wins()) do
					---@diagnostic disable-next-line: undefined-field
					if vim.w[win].treesitter_context and vim.api.nvim_win_get_buf(win) == buf then
						local cfg = vim.api.nvim_win_get_config(win)
						local src_win = cfg.win
						if src_win and vim.api.nvim_win_is_valid(src_win) then
							draw_guides(win, src_win)
						end
						return
					end
				end
			end),
			on_detach = function(_, buf)
				attached[buf] = nil
			end,
		})
	end

	local group = vim.api.nvim_create_augroup("OzayTSContextIndent", { clear = true })

	-- Découverte des nouvelles fenêtres contexte
	vim.api.nvim_create_autocmd({ "WinScrolled", "BufEnter" }, {
		group = group,
		callback = function()
			for _, win in ipairs(vim.api.nvim_list_wins()) do
				---@diagnostic disable-next-line: undefined-field
				if vim.w[win].treesitter_context then
					attach_buf(win)
				end
			end
		end,
	})

	-- Redessiner le scope quand le curseur bouge (scope change sans que le buffer contexte change)
	vim.api.nvim_create_autocmd("CursorMoved", {
		group = group,
		callback = vim.schedule_wrap(function()
			for _, win in ipairs(vim.api.nvim_list_wins()) do
				---@diagnostic disable-next-line: undefined-field
				if vim.w[win].treesitter_context then
					local cfg = vim.api.nvim_win_get_config(win)
					local src_win = cfg.win
					if src_win and vim.api.nvim_win_is_valid(src_win) then
						draw_guides(win, src_win)
					end
				end
			end
		end),
	})
end

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
		multiline_threshold = 1,
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
		setup_indent_guides()

		-- Monkey-patch context.get to support LuaDoc @class/@field annotations
		-- local context = require("treesitter-context.context")
		-- local original_get = context.get
		--
		-- context.get = function(winid)
		-- 	local ranges, lines = original_get(winid)
		--
		-- 	-- Only process Lua files
		-- 	winid = winid or vim.api.nvim_get_current_win()
		-- 	local bufnr = vim.api.nvim_win_get_buf(winid)
		-- 	if vim.bo[bufnr].filetype ~= "lua" then
		-- 		return ranges, lines
		-- 	end
		--
		-- 	-- Get topline (first visible line) - this is what treesitter-context uses in topline mode
		-- 	local top_line = vim.fn.line("w0", winid) - 1 -- 0-indexed
		--
		-- 	-- Check lines starting from topline
		-- 	local check_line = top_line
		-- 	local line_count = vim.api.nvim_buf_line_count(bufnr)
		--
		-- 	-- Find if we're in a @field block by checking lines from topline
		-- 	local current_line_text = ""
		-- 	if check_line >= 0 and check_line < line_count then
		-- 		current_line_text = vim.api.nvim_buf_get_lines(bufnr, check_line, check_line + 1, false)[1] or ""
		-- 	end
		--
		-- 	-- Check if the topline is a LuaDoc line (@field, comment, or empty ---)
		-- 	local is_luadoc_line = current_line_text:match("^%s*%-%-%-")
		-- 	local is_class_line = current_line_text:match("^%s*%-%-%-@class")
		-- 	if not is_luadoc_line or is_class_line then
		-- 		return ranges, lines
		-- 	end
		--
		-- 	-- Find the @class line above
		-- 	local class_line_num = nil
		-- 	local class_line_text = nil
		-- 	for i = check_line - 1, 0, -1 do
		-- 		local line = vim.api.nvim_buf_get_lines(bufnr, i, i + 1, false)[1] or ""
		-- 		if line:match("^%s*%-%-%-@class") then
		-- 			class_line_num = i
		-- 			class_line_text = line
		-- 			break
		-- 		elseif not line:match("^%s*%-%-%-") then
		-- 			-- Stop if we hit a non-LuaDoc line (not starting with ---)
		-- 			break
		-- 		end
		-- 		-- Continue for @field, @param, comments (---text), empty (---)
		-- 	end
		--
		-- 	if not class_line_num or not class_line_text then
		-- 		return ranges, lines
		-- 	end
		--
		-- 	-- Create new context with @class line
		-- 	local class_range = { class_line_num, 0, class_line_num + 1, 0 }
		--
		-- 	-- Initialize if nil
		-- 	ranges = ranges or {}
		-- 	lines = lines or {}
		--
		-- 	-- Check if @class is not already in context
		-- 	local already_included = false
		-- 	for _, r in ipairs(ranges) do
		-- 		if r[1] == class_line_num then
		-- 			already_included = true
		-- 			break
		-- 		end
		-- 	end
		--
		-- 	if not already_included then
		-- 		table.insert(ranges, 1, class_range)
		-- 		table.insert(lines, 1, class_line_text)
		-- 	end
		--
		-- 	return ranges, lines
		-- end
	end,
}

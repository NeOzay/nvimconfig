---@namespace docstring-highlight
--- Highlights Python docstring content (Google style):
--- section headers, parameter names, types, and inline code.
--- Uses treesitter to detect actual docstrings, then applies extmarks.

local config = require("docstring-highlight.config")
local codeblocks = require("docstring-highlight.codeblocks")

local M = {}
local ns = vim.api.nvim_create_namespace("docstring_highlight")

-- Built from config.sections in build_regexes(); matches known section keywords
---@type vim.regex
local section_re

-- Matches any section-like heading: indented capitalized word(s) ending with ":"
local any_section_re = vim.regex([[\v^\s*\u\w+(\s+\u?\w+)*\s*:\s*$]])

-- Sections that document parameters (filtered against function signature)
---@type table<string, true>
local param_sections = {
	["Args"] = true,
	["Arguments"] = true,
	["Parameters"] = true,
	["Params"] = true,
	["Keyword Args"] = true,
	["Keyword Arguments"] = true,
	["Other Parameters"] = true,
	["Attributes"] = true,
}

-- Sections where the leading identifier is a type/exception, not a param name
-- Pattern: "    type: description" or "    ExcType: description"
---@type table<string, true>
local type_sections = {
	["Returns"] = true,
	["Return"] = true,
	["Yields"] = true,
	["Yield"] = true,
	["Raises"] = true,
	["Raise"] = true,
}

local function build_regexes()
	local alts = {}
	for _, kw in ipairs(config.sections) do
		-- Escape magic chars, then replace spaces with \s+
		local escaped = kw:gsub("([%(%)%.%+%-%*%?%[%]%^%$%%])", "\\%1"):gsub("%s+", "\\s+")
		table.insert(alts, escaped)
	end
	section_re = vim.regex([[\v^\s*(]] .. table.concat(alts, "|") .. [[)\s*:\s*$]])
end

--- Extract the section keyword from a known-section line (e.g. "  Args:" → "Args").
---@param line string
---@return string|nil
local function detect_section_name(line)
	local s = section_re:match_str(line)
	if not s then
		return nil
	end
	return line:match("^%s*(.-)%s*:%s*$")
end

--- Walk up the ancestor chain to find the enclosing function_definition node.
---@param node TSNode
---@return TSNode|nil
local function find_function_ancestor(node)
	local current = node:parent()
	while current do
		if current:type() == "function_definition" then
			return current
		end
		current = current:parent()
	end
	return nil
end

---@class FunctionInfo
---@field params table<string, true>  Known param names (for existence filtering)
---@field annotations table<string, string>  Type annotation text per param (may be empty)
---@field has_var_keyword boolean  True if function has **kwargs (disables filtering for Keyword Args section)

--- Extract parameter names and type annotations from a function_definition node.
--- Excludes self/cls.
---@param bufnr number
---@param func_node TSNode
---@return FunctionInfo
local function get_function_params(bufnr, func_node)
	---@type FunctionInfo
	local info = { params = {}, annotations = {}, has_var_keyword = false }
	local params_list = func_node:field("parameters")
	local params_node = params_list and params_list[1]
	if not params_node then
		return info
	end
	for child in params_node:iter_children() do
		local ntype = child:type()
		local id_node
		local type_node ---@type TSNode|nil
		if ntype == "identifier" then
			id_node = child
		elseif ntype == "typed_parameter" or ntype == "typed_default_parameter" then
			local name_list = child:field("name")
			id_node = (name_list and name_list[1]) or child:child(0)
			local type_list = child:field("type")
			type_node = type_list and type_list[1]
		elseif ntype == "default_parameter" then
			local name_list = child:field("name")
			id_node = (name_list and name_list[1]) or child:child(0)
		elseif ntype == "list_splat_pattern" then
			local c0 = child:child(0)
			id_node = (c0 and c0:type() == "identifier") and c0 or child:child(1)
		elseif ntype == "dictionary_splat_pattern" then
			info.has_var_keyword = true
			local c0 = child:child(0)
			id_node = (c0 and c0:type() == "identifier") and c0 or child:child(1)
		end
		if id_node and id_node:type() == "identifier" then
			local name = vim.treesitter.get_node_text(id_node, bufnr)
			if name ~= "self" and name ~= "cls" then
				info.params[name] = true
				if type_node then
					info.annotations[name] = vim.treesitter.get_node_text(type_node, bufnr):match("^%s*(.-)%s*$")
				end
			end
		end
	end
	return info
end

-- Treesitter query: first string expression in function/class/module body
local query_str = [[
(function_definition
  body: (block . (expression_statement (string (string_content) @docstring))))

(class_definition
  body: (block . (expression_statement (string (string_content) @docstring))))

(module . (expression_statement (string (string_content) @docstring)))
]]

local function set_hl(bufnr, row, cs, ce, group)
	pcall(vim.api.nvim_buf_set_extmark, bufnr, ns, row, cs, {
		end_col = ce,
		hl_group = group,
		priority = config.priority,
	})
end

--- Strip markdown backslash escapes (e.g. \_ → _) from a line.
--- Returns the unescaped string and a col map: col_map[unescaped_0based_col + 1] = original_0based_col.
---@param line string
---@return string unescaped
---@return integer[] col_map
local function strip_md_escapes(line)
	local buf, map = {}, {}
	local i, oc = 1, 0
	while i <= #line do
		local ch = line:sub(i, i)
		if ch == "\\" and i < #line then
			i, oc = i + 1, oc + 1
			ch = line:sub(i, i)
		end
		buf[#buf + 1] = ch
		map[#map + 1] = oc
		i, oc = i + 1, oc + 1
	end
	map[#map + 1] = oc -- sentinel for end col
	return table.concat(buf), map
end

--- Parse a Google-style param line. Returns col_start, col_end of param name, and whether type annotation is present.
--- Supports: *args, **kwargs, - prefix, subscript (param[0])
---@param line string
---@return number|nil col_start 0-indexed start of param name (after dash if any)
---@return number|nil col_end 0-indexed end of param name (including prefix and subscript)
---@return boolean|nil has_type whether a (type) annotation follows
local function parse_param(line)
	-- Try with subscript first: "name[...]" or "*name[...]"
	local indent, dash, prefix, pname, subscript = line:match("^(%s%s+)(%-?%s*)(%*?%*?)([%w_]+)(%[.-%])%s*%b()%s*:")
	if pname then
		local col = #indent + #dash
		return col, col + #prefix + #pname + #subscript, true
	end

	-- Without subscript, with type: "name (type):" — param names are plain identifiers
	indent, dash, prefix, pname = line:match("^(%s%s+)(%-?%s*)(%*?%*?)([%w_]+)%s*%b()%s*:")
	if pname then
		local col = #indent + #dash
		return col, col + #prefix + #pname, true
	end

	-- With subscript, no type: "name[...]: desc" (indent >= 4)
	-- Allows dotted names (socket.socket, IO.TextIOWrapper)
	indent, dash, prefix, pname, subscript = line:match("^(%s%s%s%s+)(%-?%s*)(%*?%*?)([%w_%.]+)(%[.-%])%s*:")
	if
		pname and (#prefix > 0 or #dash > 0 or (#pname > 1 and (pname:find("%.", 1, true) or not pname:match("^%u%u"))))
	then
		local col = #indent + #dash
		return col, col + #prefix + #pname + #subscript, false
	end

	-- Without subscript, no type: "name: desc" (indent >= 4)
	-- Allows dotted names (socket.socket, IO.TextIOWrapper)
	indent, dash, prefix, pname = line:match("^(%s%s%s%s+)(%-?%s*)(%*?%*?)([%w_%.]+)%s*:")
	if
		pname and (#prefix > 0 or #dash > 0 or (#pname > 1 and (pname:find("%.", 1, true) or not pname:match("^%u%u"))))
	then
		local col = #indent + #dash
		return col, col + #prefix + #pname, false
	end

	return nil
end

---@class DocstringLineCtx
---@field section string|nil         Current section keyword (e.g. "Args", "Returns")
---@field known_params table<string, true>|nil   Param names from function signature; nil = no filtering
---@field param_annotations table<string, string>|nil  Type annotations from signature; nil = unavailable
---@field has_var_keyword boolean    Whether the function accepts **kwargs
---@field is_function boolean        Whether the docstring belongs to a function_definition

---@param bufnr number
---@param row number
---@param line string
---@param ctx DocstringLineCtx
---@param col_map? integer[]  mapping of unescaped 0-based col → original 0-based col (for markdown hover)
local function highlight_line(bufnr, row, line, ctx, col_map)
	local function remap(c)
		if col_map then
			return col_map[c + 1] or c
		end
		return c
	end

	-- 1) Section headers: known ("    Args:") or unknown ("    Foobar:")
	local s, e = section_re:match_str(line)
	if s then
		local ws = #(line:match("^(%s*)") or "")
		set_hl(bufnr, row, remap(ws), remap(e), "DocstringSection")
		return
	end
	local as, ae = any_section_re:match_str(line)
	if as then
		local ws = #(line:match("^(%s*)") or "")
		set_hl(bufnr, row, remap(ws), remap(ae), "DocstringUnknownSection")
		return
	end

	-- 2) Generic heading: capitalized word followed by ": text" (e.g. OBLIGATOIRE:, Note:, Important:)
	--    Skip in type sections (Returns/Raises/Yields) where the leading word is a type, not a heading.
	local in_type_sec_early = ctx.section ~= nil and type_sections[ctx.section] == true
	if not in_type_sec_early then
		local hw, he = line:match("^%s+()%u[%w_]*()%s*:%s+%S")
		if hw then
			set_hl(bufnr, row, remap(hw - 1), remap(he), "DocstringHeading")
			-- don't return: allow inline code detection on the rest of the line
		end
	end

	-- 3a) Param sections (Args, Parameters…): highlight name + type, filter against signature.
	--     Type group: DocstringTypeMatch/Mismatch when signature annotation available.
	-- 3b) Type sections (Returns, Raises…): the leading identifier IS a type → DocstringType.
	--     No filtering against signature.
	do
		local col, pend, has_type = parse_param(line)
		if col then
			local sec = ctx.section
			local in_param = not ctx.is_function or (sec ~= nil and param_sections[sec] == true)
			local in_type_sec = sec ~= nil and type_sections[sec] == true

			if in_param then
				-- Extract the bare param name (strip leading */**)
				local prefix_end = line:find("[%w_]", col + 1)
				local raw = prefix_end and line:sub(prefix_end, pend):match("^([%w_]+)") or nil
				local kwarg_section = sec == "Keyword Args" or sec == "Keyword Arguments"
				local known = ctx.known_params == nil
					or (kwarg_section and ctx.has_var_keyword)
					or (raw ~= nil and ctx.known_params[raw] == true)
				if known then
					set_hl(bufnr, row, remap(col), remap(pend), "DocstringParam")
					if has_type then
						local ps, pe = line:find("%b()", pend + 1)
						if ps then
							local type_group = "DocstringType"
							if raw and ctx.param_annotations then
								local sig_type = ctx.param_annotations[raw]
								if sig_type then
									local doc_type = line:sub(ps + 1, pe - 1):match("^%s*(.-)%s*$")
									type_group = (doc_type == sig_type) and "DocstringTypeMatch"
										or "DocstringTypeMismatch"
								end
							end
							set_hl(bufnr, row, remap(ps), remap(pe - 1), type_group)
						end
						return
					end
				end
			elseif in_type_sec then
				-- "    bool: description" or "    ExcType: description" → leading word is a type
				-- "    value (bool): description" → name + type
				if has_type then
					-- name (type): format — highlight name as DocstringParam, type as DocstringType
					set_hl(bufnr, row, remap(col), remap(pend), "DocstringParam")
					local ps, pe = line:find("%b()", pend + 1)
					if ps then
						set_hl(bufnr, row, remap(ps), remap(pe - 1), "DocstringType")
					end
					return
				else
					-- type: description format — highlight leading word as DocstringType
					set_hl(bufnr, row, remap(col), remap(pend), "DocstringType")
				end
			end
		end
	end

	-- 4) Inline code ``text`` (double) or `text` (single) — double takes priority
	local pos = 1
	while pos <= #line do
		local cs2, ce2 = line:find("``[^`]+``", pos)
		local cs1, ce1 = line:find("`[^`]+`", pos)
		local cs, ce
		if cs2 and (not cs1 or cs2 <= cs1) then
			cs, ce = cs2, ce2
		elseif cs1 then
			cs, ce = cs1, ce1
		else
			break
		end
		set_hl(bufnr, row, remap(cs - 1), remap(ce), "DocstringInlineCode")
		pos = ce + 1
	end
end

local function refresh(bufnr)
	vim.api.nvim_buf_clear_namespace(bufnr, ns, 0, -1)

	local ok, parser = pcall(vim.treesitter.get_parser, bufnr, "python")
	if not ok or not parser then
		return
	end

	local trees = parser:parse()
	if not trees or not trees[1] then
		return
	end

	local qok, query = pcall(vim.treesitter.query.parse, "python", query_str)
	if not qok then
		return
	end

	for _, node in query:iter_captures(trees[1]:root(), bufnr) do
		local sr, _, er, _ = node:range()

		-- Apply docstring background if configured
		if config.bg then
			for row = sr, er do
				pcall(vim.api.nvim_buf_set_extmark, bufnr, ns, row, 0, {
					end_row = row + 1,
					hl_group = "DocstringBackground",
					hl_eol = true,
					priority = config.priority - 3,
				})
			end
		end

		local func_node = find_function_ancestor(node)
		local func_info = func_node and get_function_params(bufnr, func_node)

		local lines = vim.api.nvim_buf_get_lines(bufnr, sr, er + 1, false)
		---@type string|nil
		local current_section = nil
		---@type DocstringLineCtx
		local ctx = {
			section = nil,
			known_params = func_info and func_info.params or nil,
			param_annotations = func_info and func_info.annotations or nil,
			has_var_keyword = func_info and func_info.has_var_keyword or false,
			is_function = func_node ~= nil,
		}
		for i, line in ipairs(lines) do
			local sec = detect_section_name(line)
			if sec then
				current_section = sec
			end
			ctx.section = current_section
			highlight_line(bufnr, sr + i - 1, line, ctx)
		end
		-- Highlight fenced code blocks (```python ... ```)
		codeblocks.highlight(bufnr, ns, sr, er)
	end
end

--- Apply docstring highlighting to a hover/float window buffer without treesitter.
--- All lines are processed; fenced code blocks (``` delimiters) are skipped.
---@param bufnr number
local function refresh_hover(bufnr)
	vim.api.nvim_buf_clear_namespace(bufnr, ns, 0, -1)
	local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
	local in_fenced = false
	local current_section = nil
	---@type DocstringLineCtx
	local ctx = {
		section = nil,
		known_params = nil,
		param_annotations = nil,
		has_var_keyword = false,
		is_function = false,
	}
	for i, line in ipairs(lines) do
		if line:match("^%s*```") then
			in_fenced = not in_fenced
		end
		if not in_fenced then
			local clean, col_map = strip_md_escapes(line)
			local sec = detect_section_name(clean)
			if sec then
				current_section = sec
			end
			ctx.section = current_section
			highlight_line(bufnr, i - 1, clean, ctx, col_map)
		end
	end
end

---@type table<number, uv.uv_timer_t>
-- Debounce per buffer
local timers = {}

local function schedule(bufnr)
	if timers[bufnr] then
		timers[bufnr]:stop()
		if not timers[bufnr]:is_closing() then
			timers[bufnr]:close()
		end
	end
	local timer = assert(vim.uv.new_timer())
	timer:start(
		config.debounce,
		0,
		vim.schedule_wrap(function()
			if not timer:is_closing() then
				timer:close()
			end
			timers[bufnr] = nil
			if vim.api.nvim_buf_is_valid(bufnr) then
				refresh(bufnr)
			end
		end)
	)
	timers[bufnr] = timer
end

local function detach(bufnr)
	if timers[bufnr] then
		timers[bufnr]:stop()
		timers[bufnr]:close()
		timers[bufnr] = nil
	end
end

local function attach(bufnr)
	schedule(bufnr)
	vim.api.nvim_buf_attach(bufnr, false, {
		on_lines = function(_, buf)
			schedule(buf)
		end,
		on_detach = function(_, buf)
			detach(buf)
		end,
	})
end

local function define_highlights()
	for group, def in pairs(config.hl) do
		vim.api.nvim_set_hl(0, group, def)
	end
	if config.bg then
		vim.api.nvim_set_hl(0, "DocstringBackground", { bg = config.bg })
	end
end

---@param opts? config
function M.setup(opts)
	config.setup(opts)
	build_regexes()

	define_highlights()

	local augroup = vim.api.nvim_create_augroup("DocstringHighlight", { clear = true })
	vim.api.nvim_create_autocmd("FileType", {
		group = augroup,
		pattern = "python",
		callback = function(ev)
			attach(ev.buf)
		end,
	})

	vim.api.nvim_create_autocmd("ColorScheme", {
		group = augroup,
		callback = function()
			define_highlights()
			codeblocks.clear_cache()
		end,
	})

	vim.api.nvim_create_autocmd("BufWinEnter", {
		group = augroup,
		callback = function(ev)
			local bufnr = ev.buf
			if vim.bo[bufnr].buftype ~= "nofile" then
				return
			end
			local win = vim.fn.bufwinid(bufnr)
			if win == -1 then
				return
			end
			local wincfg = vim.api.nvim_win_get_config(win)
			if wincfg.relative == "" then
				return
			end
			if vim.bo[bufnr].filetype ~= "markdown" then
				return
			end

			-- wincfg.win is the anchor window the float was opened relative to.
			local anchor_win = wincfg.win
			if not anchor_win or not vim.api.nvim_win_is_valid(anchor_win) then
				return
			end
			local src_buf = vim.api.nvim_win_get_buf(anchor_win)
			if vim.bo[src_buf].filetype ~= "python" then
				return
			end
			refresh_hover(bufnr)
		end,
	})

	-- Attach to already-open Python buffers
	for _, buf in ipairs(vim.api.nvim_list_bufs()) do
		if vim.api.nvim_buf_is_loaded(buf) and vim.bo[buf].filetype == "python" then
			attach(buf)
		end
	end
end

-- Expose internals for testing
M._highlight_line = highlight_line
M._refresh = refresh
M._ns = ns
M._get_function_params = get_function_params
M._detect_section_name = detect_section_name
M._strip_md_escapes = strip_md_escapes

return M

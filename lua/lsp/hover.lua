---@namespace Ozay_hover
--- Slightly *fancier* LSP hover handler.
local lsp_hover = {}

---@class opts
---
---@field border_hl string Highlight group for the window borders.
---@field name_hl? string Highlight group for the `name`. Defaults to `border_hl`.
---@field name string
---
---@field min_width integer
---@field max_width integer
---
---@field min_height integer
---@field max_height integer

--- Configuration for lsp_hovers from different
--- servers.
---
---@type { default: opts, [string]: Partial<opts> }
lsp_hover.config = {
	default = {
		border_hl = "@comment",
		name = "󰗊 LSP/Hover",

		min_width = 20,
		max_width = math.floor(vim.o.columns * 0.75),

		min_height = 1,
		max_height = math.floor(vim.o.lines * 0.5),
	},

	["^lua_ls"] = {
		name = " LuaLS",
		border_hl = "@function",
	},

	["^emmylua"] = {
		name = " Emmylua",
		border_hl = "@comment",
	},
}

--- Finds matching configuration.
--- NOTE: The output is the merge of the {config} and {default}.
---@param str string
---@return opts
local get_config = function(str)
	local default = vim.deepcopy(lsp_hover.config.default)

	for name, config in pairs(lsp_hover.config) do
		if name ~= "default" and string.match(str, name) then
			---@cast config opts
			return vim.tbl_deep_extend("force", default, config)
		end
	end
	return default
end

--- Get which quadrant to open the window on.
---
--- ```txt
---    top, left ↑ top, right
---            ← █ →
--- bottom, left ↓ bottom, right
--- ```
---@param w integer
---@param h integer
---@return [ "left" | "right" | "center", "top" | "bottom" | "center" ]
local function get_quadrant(w, h)
	local window = vim.api.nvim_get_current_win()
	local src_c = vim.api.nvim_win_get_cursor(window)

	---@type {row: integer, col: integer, endcol: integer, curscol: integer}
	local scr_p = vim.fn.screenpos(window, src_c[1], src_c[2])

	---@type integer, integer Vim's width & height.
	local vW, vH = vim.o.columns, vim.o.lines - (vim.o.cmdheight or 0)
	---@type "left" | "right", "top" | "bottom"
	local x, y

	if scr_p.curscol - w <= 0 then
		--- Not enough spaces on `left`.
		if scr_p.curscol + w >= vW then
			--- Not enough space on `right`.
			return { "center", "center" }
		else
			--- Enough spaces on `right`.
			x = "right"
		end
	else
		--- Enough space on `left`.
		x = "left"
	end

	if scr_p.row + h >= vH then
		--- Not enough spaces on `top`.
		if scr_p.row - h <= 0 then
			--- Not enough spaces on `bottom`.
			return { "center", "center" }
		else
			y = "top"
		end
	else
		y = "bottom"
	end

	return { x, y }
end

local function is_markdown_block(line)
	local trimmed = line:match("^%s*(.-)%s*$")

	return trimmed:match("^#") -- headings
		or trimmed:match("^[-*+] ") -- bullet list
		or trimmed:match("^%d+%. ") -- ordered list
		or trimmed:match("^>") -- blockquote
		or trimmed:match("^```") -- fenced code
		or trimmed:match("^~~~") -- fenced code alt
		or trimmed:match("^|") -- tables
		or trimmed:match("^%-%-%-$") -- horizontal rule
		or trimmed:match("^%*%*%*$")
		or trimmed:match("^<.+>$") -- HTML block-ish
end

local function ends_sentence(line)
	return line:match("[%.%!%?%;:]%s*$") ~= nil
end

local function join_sentence_lines(lines)
	local result = {}
	local current = ""

	for _, line in ipairs(lines) do
		local blank = line:match("^%s*$")

		-- séparation forte
		if blank then
			if current ~= "" then
				table.insert(result, current)
				current = ""
			end
			table.insert(result, "")
		elseif is_markdown_block(line) then
			-- flush avant balise MD
			if current ~= "" then
				table.insert(result, current)
				current = ""
			end
			table.insert(result, line)
		else
			if current == "" then
				current = line
			else
				current = current .. " " .. line:gsub("^%s+", "")
			end

			if ends_sentence(line) then
				table.insert(result, current)
				current = ""
			end
		end
	end

	if current ~= "" then
		table.insert(result, current)
	end

	return result
end

---@param text_list string[]
---@param width integer
---@param opts? { linebreak?: boolean, breakat?: string }
local function wrap_string(text_list, width, opts)
	opts = opts or {}

	local linebreak = opts.linebreak ~= false
	local breakat = opts.breakat or " \t!@*-+;:,./?"

	local lines = {}

	-- crée un set rapide pour breakat
	local breakset = {}
	for c in breakat:gmatch(".") do
		breakset[c] = true
	end

	for _i, text in ipairs(text_list) do
		local pos = 1
		while pos <= #text do
			-- portion candidate
			local chunk = text:sub(pos, pos + width - 1)

			if #chunk < width then
				table.insert(lines, chunk)
				break
			end

			local break_pos = nil

			if linebreak then
				-- cherche le dernier char autorisé
				for i = #chunk, 1, -1 do
					local ch = chunk:sub(i, i)
					if breakset[ch] then
						break_pos = i
						break
					end
				end
			end

			-- fallback: coupe brut
			if not break_pos then
				break_pos = width
			end

			table.insert(lines, chunk:sub(1, break_pos))

			-- skip espaces après break
			pos = pos + break_pos
			while text:sub(pos, pos):match("%s") do
				pos = pos + 1
			end
		end
	end

	return lines
end

---@param ss string[]
---@param max_width integer
local function format_string(ss, max_width)
	local trim = vim.trim
	local wraped_string = wrap_string(join_sentence_lines(ss), max_width)

	local formated_strings = {}
	for i, s in ipairs(wraped_string) do
		if trim(s) == "" and (trim(ss[i + 1] or "") == "" or (ss[i + 1] or ""):find("^---$")) then
			goto continue
		end

		local line = s
			:gsub("&nbsp;", " ") -- HTML entity
			:gsub("\u{00A0}", " ") -- vrai NBSP
			:gsub("\u{202F}", " ") -- narrow NBSP
		if line:find("^---$") then
			line = "___"
		elseif not line:find("^```") then
			line = " " .. line
		end
		table.insert(formated_strings, line)
		::continue::
	end

	if formated_strings[#formated_strings] ~= "" then
		table.insert(formated_strings, " ")
	end
	return formated_strings
end

-- LSP hover window.

--- Initializes the hover buffer & window.
---@param config Partial<snacks.win.Config>
lsp_hover.__init = function(config)
	if not lsp_hover.window then
		lsp_hover.window = Snacks.win.new(config)
		lsp_hover.window:scratch()
	else
		lsp_hover.window.opts = vim.tbl_deep_extend("force", lsp_hover.window.opts, config)
	end
end

--- Custom hover function.
---@param error? table Error.
---@param result table Result of the hover.
---@param context table Context for this hover.
---@param _ table Hover config(we won't use this).
lsp_hover.hover = function(error, result, context, _)
	if error then
		--- Emit error message.
		vim.api.nvim_echo({
			{ "  Lsp hover: ", "DiagnosticVirtualTextError" },
			{ " " },
			{ error.message, "Comment" },
		}, true, {})
	end

	if vim.api.nvim_get_current_buf() ~= context.bufnr then
		--- Buffer was changed before the request was resolved.
		return
	end

	if not result or not result.contents then
		--- No result.
		vim.api.nvim_echo({
			{ "  Lsp hover: ", "DiagnosticVirtualTextInfo" },
			{ " " },
			{ "No information available!", "Comment" },
		}, true, {})
		return
	end

	---@type string | table
	local content = result.contents

	---@type string[]
	local lines = {}
	local ft

	--[[
		NOTE: LSP hover contents can be any of the followings,

		1. Literal string.
		2. A table(`{ kind = ..., value = ... }`).
		3. A list(`{ kind = ..., value = ... }[]`).
	]]
	if type(content) == "string" then
		lines = vim.split(content or "", "\n", { trimempty = true })
		ft = "markdown"
	else
		content = vim.islist(content) and content[1] or content

		lines = vim.split(content.value or "", "\n", { trimempty = true })
		ft = content.kind
	end

	---@type integer LSP client ID.
	local client_id = context.client_id
	---@type { name: string } LSP client info.
	local client = vim.lsp.get_client_by_id(client_id) or { name = "Unknown" }
	local config = get_config(client.name)

	local w = config.min_width or 20
	local h = config.min_height or 1

	local max_height = config.max_height or 10
	local max_width = config.max_width or 60

	lines = format_string(lines, config.max_width - 2)

	for _, line in ipairs(lines) do
		if vim.fn.strdisplaywidth(line) >= max_width then
			w = max_width
			break
		elseif vim.fn.strdisplaywidth(line) + 1 > w then
			w = vim.fn.strdisplaywidth(line) + 1
		end
	end

	h = math.max(math.min(#lines, max_height), h)

	---@type Partial<snacks.win.Config>
	local snacks_win = {
		show = false,
		fixbuf = true,
		position = "float",
		enter = false,
		ft = ft,
		scratch_ft = ft,
		relative = "cursor",
		row = 1,
		col = 0,
		backdrop = false,

		resize = true,
		min_height = h,
		min_width = w,
		height = h,
		width = w,
		wo = {
			conceallevel = 3,
			concealcursor = "n",
			signcolumn = "no",
			wrap = true,
			-- linebreak = true,
			-- statuscolumn = utils.statuscolumn,
		},

		max_height = max_height,
		max_width = max_width,

		footer = {
			{ "╼ ", config.border_hl or "FloatBorder" },
			{ config.name, config.name_hl or config.border_hl or "FloatBorder" },
			{ " ╾", config.border_hl or "FloatBorder" },
		},
		footer_pos = "right",

		keys = {
			["q"] = function(self)
				self:hide()
			end,
		},
	}

	--- Window borders.
	local border = {
		{ "╭", config.border_hl or "FloatBorder" },
		{ "─", config.border_hl or "FloatBorder" },
		{ "╮", config.border_hl or "FloatBorder" },

		{ "│", config.border_hl or "FloatBorder" },
		{ "╯", config.border_hl or "FloatBorder" },
		{ "─", config.border_hl or "FloatBorder" },

		{ "╰", config.border_hl or "FloatBorder" },
		{ "│", config.border_hl or "FloatBorder" },
	}

	--- Which quadrant to open the window on.
	---@type [ "left" | "right" | "center", "top" | "bottom" | "center" ]
	local quad = get_quadrant(w + 2, h + 2)

	if quad[1] == "left" then
		snacks_win.col = (w * -1) - 1
	elseif quad[1] == "right" then
		snacks_win.col = 0
	else
		snacks_win.relative = "editor"
		snacks_win.col = math.ceil((vim.o.columns - w) / 2)
	end

	if quad[2] == "top" then
		snacks_win.row = (h * -1) - 2

		if quad[1] == "left" then
			border[5][1] = "┤"
		else
			border[7][1] = "├"
		end
	elseif quad[2] == "bottom" then
		snacks_win.row = 1

		if quad[1] == "left" then
			border[3][1] = "┤"
		else
			border[1][1] = "├"
		end
	else
		snacks_win.relative = "editor"
		snacks_win.row = math.ceil((vim.o.lines - h) / 2)
	end

	snacks_win.border = border

	lsp_hover.__init(snacks_win)
	if lsp_hover.window.buf then
		vim.api.nvim_buf_set_lines(lsp_hover.window.buf, 0, -1, false, lines)
	end

	lsp_hover.window:show()
	if package.loaded["markview"] and package.loaded["markview"].render then
		--- If markview is available use it to render stuff.
		--- This is for `v25`.
		require("markview").render(lsp_hover.window.buf, { enable = true, hybrid_mode = false })
	end
end

--- Setup function.
---@param config? { default?: Partial<opts>, [string]: Partial<opts> } | nil
lsp_hover.setup = function(config)
	if config then
		---@diagnostic disable-next-line
		lsp_hover.config = vim.tbl_deep_extend("force", lsp_hover.config, config)
	end

	if vim.fn.has("nvim-0.11") == 1 then
		vim.api.nvim_create_autocmd("LspAttach", {
			callback = function(ev)
				vim.api.nvim_buf_set_keymap(ev.buf, "n", "K", "", {
					callback = function()
						local window = vim.api.nvim_get_current_win()

						if lsp_hover.window and not lsp_hover.window.closed then
							print("focus")
							lsp_hover.window:focus()
						else
							print("lsp hover request")
							vim.lsp.buf_request(
								0,
								"textDocument/hover",
								vim.lsp.util.make_position_params(window, "utf-8"),
								lsp_hover.hover
							)
						end
					end,
				})
			end,
		})
	end

	--- TODO, maybe we should remove this.
	--- Set-up the new provider.
	vim.lsp.handlers["textDocument/hover"] = lsp_hover.hover

	vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
		callback = function(event)
			if not lsp_hover.window then
				return
			end
			if event.buf == lsp_hover.window.buf then
				--- Don't do anything if the current buffer
				--- is the hover buffer.
				return
			elseif not lsp_hover.window.closed then
				lsp_hover.window:hide()
			end
		end,
	})
end

return lsp_hover

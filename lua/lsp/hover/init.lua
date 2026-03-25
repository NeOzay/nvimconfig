---@namespace Ozay.Hover
--- Slightly *fancier* LSP hover handler.
local hover_config = require("lsp.hover.config")
local format = require("lsp.hover.format")
local position = require("lsp.hover.position")
local hover_hl = require("lsp.hover.highlight")

local lsp_hover = {}

lsp_hover.config = hover_config.config

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

--- Parse hover result contents into lines and filetype.
---@param content string|table
---@return string[] lines
---@return string ft
local function parse_content(content)
	if type(content) == "string" then
		return vim.split(content or "", "\n", { trimempty = true }), "markdown"
	end

	content = vim.islist(content) and content[1] or content
	return vim.split(content.value or "", "\n", { trimempty = true }), content.kind
end

--- Compute dimensions from formatted lines.
---@param lines string[]
---@param config opts
---@return integer w, integer h
local function compute_dimensions(lines, config)
	local w = config.min_width or 20
	local max_width = config.max_width or 60
	local max_height = config.max_height or 10

	for _, line in ipairs(lines) do
		local lw = vim.fn.strdisplaywidth(line)
		if lw >= max_width then
			w = max_width
			break
		elseif lw + 1 > w then
			w = lw + 1
		end
	end

	local h = math.max(math.min(#lines, max_height), config.min_height or 1)
	return w, h
end

--- Custom hover function.
---@param error? table Error.
---@param result table Result of the hover.
---@param context table Context for this hover.
---@param _ table Hover config(we won't use this).
lsp_hover.hover = function(error, result, context, _)
	if error then
		vim.api.nvim_echo({
			{ "  Lsp hover: ", "DiagnosticVirtualTextError" },
			{ " " },
			{ error.message, "Comment" },
		}, true, {})
	end

	if vim.api.nvim_get_current_buf() ~= context.bufnr then
		return
	end

	if not result or not result.contents then
		vim.api.nvim_echo({
			{ "  Lsp hover: ", "DiagnosticVirtualTextInfo" },
			{ " " },
			{ "No information available!", "Comment" },
		}, true, {})
		return
	end

	local lines, ft = parse_content(result.contents)

	local client_id = context.client_id
	local client = vim.lsp.get_client_by_id(client_id) or { name = "Unknown" }
	local config = hover_config.get_config(client.name)

	lines = format.format_string(lines, config.max_width - 2)
	local w, h = compute_dimensions(lines, config)

	local border_hl = config.border_hl or "FloatBorder"

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
		zindex = 100,

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
		},

		max_height = config.max_height,
		max_width = config.max_width,

		footer = {
			{ "╼ ", border_hl },
			{ config.name, config.name_hl or border_hl },
			{ " ╾", border_hl },
		},
		footer_pos = "right",

		keys = {
			["q"] = function(self)
				self:hide()
			end,
		},
	}

	local border = position.build_border(border_hl)
	position.apply_position(snacks_win, border, w, h)

	lsp_hover.__init(snacks_win)
	if lsp_hover.window.buf then
		vim.api.nvim_buf_set_lines(lsp_hover.window.buf, 0, -1, false, lines)
	end

	lsp_hover.window:show()
	if package.loaded["markview"] and package.loaded["markview"].render then
		require("markview.actions").render(lsp_hover.window.buf, { enable = true, hybrid_mode = false }, {
			markdown = {
				block_quotes = { enable = false },
			},
			markdown_inline = {
				inline_codes = { padding_right = "", padding_left = "" },
			},
		})
	end

	local removed = hover_hl.apply(lsp_hover.window.buf)
	if removed > 0 then
		local new_h = math.max(h - removed, config.min_height or 1)
		vim.api.nvim_win_set_height(lsp_hover.window.win, new_h)
	end
end

--- Setup function.
---@param config? { default?: Partial<opts>, [string]: Partial<opts> } | nil
lsp_hover.setup = function(config)
	if config then
		---@diagnostic disable-next-line
		lsp_hover.config = vim.tbl_deep_extend("force", lsp_hover.config, config)
		hover_config.config = lsp_hover.config
	end

	if vim.fn.has("nvim-0.11") == 1 then
		vim.api.nvim_create_autocmd("LspAttach", {
			callback = function(ev)
				vim.api.nvim_buf_set_keymap(ev.buf, "n", "K", "", {
					callback = function()
						local window = vim.api.nvim_get_current_win()

						if lsp_hover.window and not lsp_hover.window.closed then
							lsp_hover.window:focus()
						else
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

	vim.lsp.handlers["textDocument/hover"] = lsp_hover.hover

	vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
		callback = function(event)
			if not lsp_hover.window then
				return
			end
			if event.buf == lsp_hover.window.buf then
				return
			elseif not lsp_hover.window.closed then
				lsp_hover.window:hide()
			end
		end,
	})
end

return lsp_hover

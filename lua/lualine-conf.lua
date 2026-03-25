local M = {}

---@param winid integer? Window ID to check, if nil it will check the global width
---@param min integer Minimum width to compare against
local function check_win_width(winid, min)
	if winid then
		return vim.api.nvim_win_get_width(winid) > min
	end
	return vim.o.columns > 100
end

function M.setup()
	vim.opt_global.laststatus = 2
	local colors = require("base46").get_theme_tb("base_30") ---@as Base30Table
	local bg = colors.statusline_bg

	local theme = {
		normal = {
			a = { fg = colors.black, bg = colors.nord_blue, gui = "bold" },
			b = { fg = colors.white, bg = colors.lightbg },
			c = { fg = colors.light_grey, bg = bg },
		},
		insert = {
			a = { fg = colors.black, bg = colors.dark_purple, gui = "bold" },
			b = { fg = colors.white, bg = colors.lightbg },
			c = { fg = colors.light_grey, bg = bg },
		},
		visual = {
			a = { fg = colors.black, bg = colors.cyan, gui = "bold" },
			b = { fg = colors.white, bg = colors.lightbg },
			c = { fg = colors.light_grey, bg = bg },
		},
		replace = {
			a = { fg = colors.black, bg = colors.orange, gui = "bold" },
			b = { fg = colors.white, bg = colors.lightbg },
			c = { fg = colors.light_grey, bg = bg },
		},
		command = {
			a = { fg = colors.black, bg = colors.green, gui = "bold" },
			b = { fg = colors.white, bg = colors.lightbg },
			c = { fg = colors.light_grey, bg = bg },
		},
		terminal = {
			a = { fg = colors.black, bg = colors.green, gui = "bold" },
			b = { fg = colors.white, bg = colors.lightbg },
			c = { fg = colors.light_grey, bg = bg },
		},
		inactive = {
			a = { fg = colors.light_grey, bg = bg },
			b = { fg = colors.light_grey, bg = bg },
			c = { fg = colors.light_grey, bg = bg },
		},
	}

	local mode_map = {
		["n"] = "NORMAL",
		["no"] = "NORMAL",
		["v"] = "VISUAL",
		["V"] = "V-LINE",
		[string.char(22)] = "V-BLOCK",
		["i"] = "INSERT",
		["ic"] = "INSERT",
		["R"] = "REPLACE",
		["Rv"] = "V-REPLACE",
		["c"] = "COMMAND",
		["t"] = "TERMINAL",
		["nt"] = "NTERMINAL",
		["s"] = "SELECT",
		["S"] = "S-LINE",
	}

	local diagnostics = {
		"diagnostics",
		symbols = { error = " ", warn = " ", hint = "󰛩 ", info = "󰋼 " },
		colored = true,
		always_visible = false,
	}

	---@type Partial<LualineComponentOptions>
	local lsp_name = {
		function()
			local clients = vim.lsp.get_clients({ bufnr = 0 })
			if #clients == 0 then
				return ""
			end
			local names = {}
			for _, client in ipairs(clients) do
				table.insert(names, client.name)
			end
			return "   LSP ~ " .. table.concat(names, ", ") .. " "
		end,
		color = { fg = colors.nord_blue, bg = bg },
		---@param ctx LualineContext
		cond = function(ctx)
			return check_win_width(ctx.winid, 100)
		end,
	}

	---@type Partial<LualineComponentOptions>[]
	local file_status = {
		{
			function()
				return " "
			end,
			cond = function()
				return vim.bo.modified
			end,
			color = function(ctx)
				return { fg = ctx.is_focused and colors.blue or colors.grey_fg }
			end,
			padding = { left = 0, right = 0 },
		},
		{
			function()
				vim.b.lockable = true
				if vim.bo.modifiable == false or vim.bo.readonly == true then
					return "󰍁 "
				end
				return "󰿇 "
			end,
			cond = function()
				return vim.bo.modifiable == false or vim.bo.readonly == true or vim.b.lockable
			end,
			---@param ctx LualineContext
			color = function(ctx)
				if not ctx.is_focused then
					return { fg = colors.grey_fg }
				end

				if vim.bo.modifiable == false or vim.bo.readonly == true then
					return { fg = colors.red }
				else
					return { fg = colors.blue }
				end
			end,
			on_click = function(_, _, _, ctx)
				if vim.b[ctx.bufnr].lockable == nil then
					return
				end

				local bo = vim.bo[ctx.bufnr]

				if bo.modifiable == false or vim.bo.readonly == true then
					bo.modifiable = true
					bo.readonly = false
				else
					bo.modifiable = false
					bo.readonly = true
				end
				require("lualine").refresh()
			end,
			padding = { left = 0, right = 0 },
		},
	}

	local cwd = {
		{
			function()
				return "󰉋 "
			end,
			color = { bg = colors.red, fg = bg },
			padding = { left = 0, right = 0 },
		},
		{
			function()
				return vim.fn.fnamemodify(vim.fn.getcwd(), ":t") .. " "
			end,
			color = { fg = colors.white, bg = colors.lightbg },
			cond = function(ctx)
				return check_win_width(ctx.winid, 85)
			end,
			padding = { left = 1, right = 0 },
		},
	}

	local location = {
		{
			function()
				return " "
			end,
			color = { bg = colors.green },
			padding = { left = 0, right = 0 },
		},
		{
			function()
				return vim.fn.line(".") .. "/" .. vim.fn.virtcol(".") .. " "
			end,
			color = { fg = colors.green, bg = colors.lightbg },
			padding = { left = 1, right = 0 },
		},
	}

	require("lualine").setup({
		options = {
			theme = theme,
			section_separators = { left = "", right = "" },
			component_separators = { left = "", right = "" },
			padding = 1,
			globalstatus = false,
			disabled_filetypes = { statusline = { "dashboard", "alpha", "starter", "codediff-explorer" } },
		},
		sections = {
			lualine_a = {
				{
					"mode",
					fmt = function(s)
						return " " .. mode_map[vim.api.nvim_get_mode().mode] or s
					end,
					padding = { left = 1, right = 0 },
					separator = { left = "", right = "" },
				},
				{
					function()
						return ""
					end,
					cond = function()
						return true
					end,
					color = { fg = colors.grey },
					padding = { left = 0, right = 0 },
					separator = { left = "", right = "" },
				},
			},
			lualine_b = {
				{
					function()
						return ""
					end,
					color = { fg = colors.grey },
					padding = { left = 0, right = 0 },
					separator = { left = "", right = "" },
				},
				{
					"filetype",
					colored = true, -- Displays filetype icon in color if set to true
					icon_only = true, -- Display only an icon for filetype
					icon = { align = "left" }, -- Display filetype icon on the right hand side
					-- icon =    {'X', align='right'}
					-- Icon string ^ in table is ignored in filetype component
					padding = { left = 1, right = 0 },
				},
				{
					function()
						local name = vim.fn.expand("%:t")
						local dir = vim.fn.expand("%:p:h:t")
						if dir == "" or dir == "." then
							return ""
						end
						return dir .. "/"
					end,
					color = { fg = colors.grey_fg },
					padding = { left = 0, right = 0 },
				},
				{
					"filename",
					icons_enabled = false,
					path = 0,
					file_status = false,
					padding = { left = 0, right = 1 },
					-- fmt = function(str)
					-- 	return vim.trim(str)
					-- end,
				},
				file_status[1],
				file_status[2],
			},
			lualine_c = {
				{ "branch", icon = "", color = { gui = "bold" } },
				{ "diff", symbols = { added = " ", modified = " ", removed = " " } },
			},
			lualine_x = { diagnostics, lsp_name },
			lualine_y = { cwd[1], cwd[2] },
			lualine_z = { location[1], location[2] },
		},

		inactive_sections = {
			lualine_a = {},
			lualine_b = {},
			lualine_c = { { "filename", file_status = false }, file_status[1], file_status[2] },
			lualine_x = { "location" },
			lualine_y = {},
			lualine_z = {},
		},
	})
end

return M

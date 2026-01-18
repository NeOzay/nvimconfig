-- This file needs to have same structure as nvconfig.lua
-- https://github.com/NvChad/ui/blob/v3.0/lua/nvconfig.lua
-- Please read that file to know all available options :(

---@type ChadrcConfig
local M = {}

local field = "#A6A67C"
-- local class = "#0DB9D7"

---@diagnostic disable-next-line
M.base46 = {
	theme = "sonokai",
	integrations = { "trouble", "telescope", "blankline", "navic" },

	hl_add = {
		["@lsp.typemod.keyword.readonly"] = { fg = "purple", italic = false },
		["@lsp.typemod.class.declaration"] = { italic = true },
		["@lsp.type.keyword.lua"] = { fg = "None" },
		["@lsp.type.operator.lua"] = { fg = "None" },
		["@lsp.mod.documentation.lua"] = { italic = true, fg = "blue" },
		Bold = { bold = true },
		DiagnosticUnderlineError = { sp = "red", undercurl = true },
		-- Rainbow indent colors
		RainbowIndentRed = { fg = { "red", "line", 80 } },
		RainbowIndentYellow = { fg = { "yellow", "line", 80 } },
		RainbowIndentBlue = { fg = { "blue", "line", 80 } },
		RainbowIndentOrange = { fg = { "orange", "line", 80 } },
		RainbowIndentGreen = { fg = { "green", "line", 80 } },
		RainbowIndentViolet = { fg = { "purple", "line", 80 } },
		RainbowIndentCyan = { fg = { "cyan", "line", 80 } },

		RainbowScopeRed = { fg = { "red", "grey", 50 } },
		RainbowScopeYellow = { fg = { "yellow", "grey", 50 } },
		RainbowScopeBlue = { fg = { "blue", "grey", 50 } },
		RainbowScopeOrange = { fg = { "orange", "grey", 50 } },
		RainbowScopeGreen = { fg = { "green", "grey", 50 } },
		RainbowScopeViolet = { fg = { "purple", "grey", 50 } },
		RainbowScopeCyan = { fg = { "cyan", "grey", 50 } },
		CurSearch = { bg = "green", fg = "#2c2e34" },
		SatelliteSearchCurrent = { bg = "green", fg = "#2c2e34" },
		TreesitterContext = { bg = "black" },
		TreesitterContextBottom = { fg = "NONE", bg = "none" },
	},

	---@type Base46HLGroupsList
	hl_override = {
		["Comment"] = { link = "@comment" },
		["@comment"] = { italic = false },
		["@lsp.type.comment"] = { link = "@comment" },
		["@keyword"] = { italic = true, fg = "blue" },
		["@keyword.function"] = { italic = true, fg = "blue" },
		["@keyword.conditional"] = { fg = "red", italic = true },
		["@keyword.return"] = { italic = true, fg = "blue" },
		["@lsp.type.property"] = { fg = field },
		["@property"] = { fg = field },
		["@lsp.type.class"] = { fg = { "blue", -20 } },
		["@type"] = { fg = { "blue", -20 } },
		PmenuSel = { fg = "NONE" },
	},
}

-- M.nvdash = { load_on_startup = true }
M.ui = {
	tabufline = {
		lazyload = false,
	},
	cmp = {
		icons_left = true,
	},
	telescope = {
		style = "bordered",
	},
}

return M

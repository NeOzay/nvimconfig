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

		-- ["@lsp.type.string"] = {},
		["@string.delimitor"] = { link = "@comment" },

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
		["@lsp"] = { fg = "NONE", bg = "NONE" },

		-- Blink.cmp kind colors
		BlinkCmpKindText = { link = "@text" },
		BlinkCmpKindMethod = { link = "@function.method" },
		BlinkCmpKindFunction = { link = "@function" },
		BlinkCmpKindConstructor = { link = "@constructor" },
		BlinkCmpKindField = { link = "@variable.member" },
		BlinkCmpKindVariable = { link = "@variable" },
		BlinkCmpKindClass = { link = "@type" },
		BlinkCmpKindInterface = { link = "@type" },
		BlinkCmpKindModule = { link = "@module" },
		BlinkCmpKindProperty = { link = "@property" },
		BlinkCmpKindUnit = { link = "@number" },
		BlinkCmpKindValue = { link = "@number" },
		BlinkCmpKindEnum = { link = "@type" },
		BlinkCmpKindKeyword = { link = "@keyword" },
		BlinkCmpKindSnippet = { link = "@string" },
		BlinkCmpKindColor = { link = "@constant" },
		BlinkCmpKindFile = { link = "@string.special.path" },
		BlinkCmpKindReference = { link = "@variable.parameter.reference" },
		BlinkCmpKindFolder = { link = "@string.special.path" },
		BlinkCmpKindEnumMember = { link = "@constant" },
		BlinkCmpKindConstant = { link = "@constant" },
		BlinkCmpKindStruct = { link = "@type" },
		BlinkCmpKindEvent = { link = "@type" },
		BlinkCmpKindOperator = { link = "@operator" },
		BlinkCmpKindTypeParameter = { link = "@type" },
		BlinkCmpKindCopilot = { fg = "green" },

		-- DAP (debugger) signs
		DapBreakpoint = { fg = "red" },
		DapBreakpointCondition = { fg = "orange" },
		DapLogPoint = { fg = "blue" },
		DapStopped = { fg = "green" },
		DapBreakpointRejected = { fg = "grey" },
		DapStoppedLine = { bg = { "green", "black", 20 } },
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
		["@lsp.type.namespace"] = { fg = { "blue", -20 } },
		["@type"] = { fg = { "blue", -20 } },
		PmenuSel = { fg = "NONE" },
		["@lsp"] = { fg = "NONE", bg = "NONE" },
	},
}

-- M.nvdash = { load_on_startup = true }
---@diagnostic disable-next-line
M.ui = {
	tabufline = {
		lazyload = false,
		enabled = false,
	},
	-- Ancienne config cmp (commentée pour blink.cmp)
	-- cmp = {
	-- 	icons_left = true,
	-- },
	telescope = {
		style = "bordered",
	},
}

return M

---@diagnostic disable:missing-fields
-- User highlight overrides for base46.
-- Supports: palette names ("blue"), lightness tuples ({ "blue", -20 }),
-- mix tuples ({ "orange", "line", 80 }), and direct hex values.

---@type Base46Config
return {
	theme = "themes.sonokai",
	integrations = "highlights",

	---@type table<string, string|Base46MixedColor>
	---@class (partial) Base46ExtendedPalette
	extended_palette = {
		Type = { "blue", -20 },
		Enum = { { "orange", -15 }, "purple", 60 },
		Field = "#A6A67C",

		CodeDiffLineInsert = { "green", "black", 92 },
		CodeDiffLineDelete = { "red", "black", 92 },
		CodeDiffCharInsert = { "green", "black", 80 },
		CodeDiffCharDelete = { "red", "black", 80 },

		code_bg = { "one_bg2", "black", 50 },
		scratch_desc = { "green", "black2", 85 },
	},

	hl_override = {

		-- LSP semantic overrides
		["@lsp.typemod.keyword.readonly"] = { fg = "purple", italic = false },
		["@lsp.typemod.class.declaration"] = { italic = true },
		["@lsp.type.keyword"] = { fg = "None" },
		["@lsp.type.operator.lua"] = { fg = "None" },
		["@lsp.type.macro"] = { fg = "pink" },
		["@lsp.mod.documentation.lua"] = { italic = true, fg = "blue" },
		["@lsp.mod.defaultLibrary"] = { italic = true },
		["@lsp.type.comment"] = { link = "@comment" },
		["@lsp.type.property"] = { fg = "Field" },
		["@lsp.type.class"] = { fg = "Type" },
		["@lsp.type.namespace"] = { fg = "purple" },
		["@lsp.type.struct"] = { link = "@type" },
		["@lsp.type.typeParameter"] = { fg = "red" },
		["@lsp"] = { fg = "NONE", bg = "NONE" },
		["@lsp.type.variable"] = { link = "@lsp" },
		["@lsp.type.enum"] = { fg = "Enum" },

		-- Syntax overrides
		["Comment"] = { link = "@comment" },
		["@comment"] = { italic = false },
		["@keyword"] = { fg = "blue", italic = true },
		["@keyword.function"] = { fg = "blue", italic = true },
		["@keyword.conditional"] = { fg = "red", italic = true },
		["@keyword.return"] = { fg = "blue", italic = true },
		["@keyword.exception"] = { fg = "blue", italic = true },
		["@property"] = { fg = "Field" },
		["@variable.member"] = { fg = "Field" },
		["@type"] = { fg = "Type" },
		["@string.delimitor"] = { link = "@comment" },
		["@string.documentation"] = { link = "@comment" },
		PmenuSel = { fg = "NONE" },
		Bold = { bold = true },
		DiagnosticUnderlineError = { sp = "red", undercurl = true },

		-- Rainbow indent colors
		RainbowIndentGray = { fg = "line" },
		RainbowIndentRed = { fg = { "red", "line", 80 } },
		RainbowIndentYellow = { fg = { "yellow", "line", 80 } },
		RainbowIndentBlue = { fg = { "blue", "line", 80 } },
		RainbowIndentOrange = { fg = { "orange", "line", 80 } },
		RainbowIndentGreen = { fg = { "green", "line", 80 } },
		RainbowIndentViolet = { fg = { "purple", "line", 80 } },
		RainbowIndentCyan = { fg = { "cyan", "line", 80 } },

		RainbowScopeGray = { fg = "grey" },
		RainbowScopeRed = { fg = { "red", "grey", 50 } },
		RainbowScopeYellow = { fg = { "yellow", "grey", 50 } },
		RainbowScopeBlue = { fg = { "blue", "grey", 50 } },
		RainbowScopeOrange = { fg = { "orange", "grey", 50 } },
		RainbowScopeGreen = { fg = { "green", "grey", 50 } },
		RainbowScopeViolet = { fg = { "purple", "grey", 50 } },
		RainbowScopeCyan = { fg = { "cyan", "grey", 50 } },

		-- Search
		CurSearch = { bg = "green", fg = "#2c2e34" },
		SatelliteSearchCurrent = { bg = "green", fg = "#2c2e34" },

		-- Treesitter context
		TreesitterContext = { bg = "black" },
		TreesitterContextBottom = { fg = "NONE", bg = "none" },

		-- DAP (debugger) signs
		DapBreakpoint = { fg = "red" },
		DapBreakpointCondition = { fg = "orange" },
		DapLogPoint = { fg = "blue" },
		DapStopped = { fg = "green" },
		DapBreakpointRejected = { fg = "grey" },
		DapStoppedLine = { bg = { "green", "black", 20 } },
	},
}

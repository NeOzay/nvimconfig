-- User highlight overrides for base46.
-- Supports: palette names ("blue"), lightness tuples ({ "blue", -20 }),
-- mix tuples ({ "orange", "line", 80 }), and direct hex values.

local field = "#A6A67C"

---@type Base46Config
return {
	theme = "sonokai",
	integrations = "highlights",

	hl_override = {
		-- indent-blankline
		IblChar = { fg = "line" },
		IblScopeChar = { fg = "grey" },

		-- LSP semantic overrides
		["@lsp.typemod.keyword.readonly"] = { fg = "purple", italic = false },
		["@lsp.typemod.class.declaration"] = { italic = true },
		["@lsp.type.keyword.lua"] = { fg = "None" },
		["@lsp.type.operator.lua"] = { fg = "None" },
		["@lsp.mod.documentation.lua"] = { italic = true, fg = "blue" },
		["@lsp.type.comment"] = { link = "@comment" },
		["@lsp.type.property"] = { fg = field },
		["@lsp.type.class"] = { fg = { "blue", -20 } },
		["@lsp.type.namespace"] = { fg = { "blue", -20 } },
		["@lsp"] = { fg = "NONE", bg = "NONE" },

		-- Syntax overrides
		["Comment"] = { link = "@comment" },
		["@comment"] = { italic = false },
		["@keyword"] = { italic = true, fg = "blue" },
		["@keyword.function"] = { italic = true, fg = "blue" },
		["@keyword.conditional"] = { fg = "red", italic = true },
		["@keyword.return"] = { italic = true, fg = "blue" },
		["@property"] = { fg = field },
		["@variable.member"] = { fg = field },
		["@type"] = { fg = { "blue", -20 } },
		["@string.delimitor"] = { link = "@comment" },
		["@string.documentation"] = { link = "@comment" },
		PmenuSel = { fg = "NONE" },
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

		-- Search
		CurSearch = { bg = "green", fg = "#2c2e34" },
		SatelliteSearchCurrent = { bg = "green", fg = "#2c2e34" },

		-- Treesitter context
		TreesitterContext = { bg = "black" },
		TreesitterContextBottom = { fg = "NONE", bg = "none" },

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
}

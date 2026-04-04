---@type LazySpec
return {
	"lukas-reineke/indent-blankline.nvim",
	event = "User FilePost",
	-- enabled = false,
	---@type ibl.config
	opts = {
		indent = {
			char = "▎",
			tab_char = "▎",
			smart_indent_cap = true,
			highlight = {
				"RainbowIndentGray",
				"RainbowIndentRed",
				"RainbowIndentYellow",
				"RainbowIndentBlue",
				"RainbowIndentOrange",
				"RainbowIndentGreen",
				"RainbowIndentViolet",
				"RainbowIndentCyan",
			},
		},
		scope = {
			char = "▎",
			priority = 70,
			enabled = true,
			show_start = true,
			highlight = {
				"RainbowScopeGray",
				"RainbowScopeRed",
				"RainbowScopeYellow",
				"RainbowScopeBlue",
				"RainbowScopeOrange",
				"RainbowScopeGreen",
				"RainbowScopeViolet",
				"RainbowScopeCyan",
			},
			include = { node_type = { lua = { "return_statement", "table_constructor" } } },
		},
	},
	config = function(_, opts)
		require("ibl").setup(opts)
		require("ibl.highlights").setup()
	end,
}

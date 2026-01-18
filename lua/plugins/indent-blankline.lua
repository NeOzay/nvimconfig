---@type LazySpec
return {
	"lukas-reineke/indent-blankline.nvim",
	event = "User FilePost",
	---@type ibl.config
	opts = {
		indent = {
			char = "▎",
			tab_char = "▎",
			smart_indent_cap = true,
			highlight = {
				"IblChar",
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
			enabled = true,
			show_start = true,
			highlight = {
				"IblScopeChar",
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
		dofile(vim.g.base46_cache .. "blankline")
		require("ibl").setup(opts)
		dofile(vim.g.base46_cache .. "blankline")
		require("ibl.highlights").setup()
	end,
}

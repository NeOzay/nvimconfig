local M = {}

---@type ibl.config
M.opts = {
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
}

M.config = function(_, opts)
	dofile(vim.g.base46_cache .. "blankline")

	-- local hooks = require("ibl.hooks")
	-- hooks.register(hooks.type.WHITESPACE, hooks.builtin.hide_first_space_indent_level)
	-- hooks.register(hooks.type.WHITESPACE, hooks.builtin.hide_first_tab_indent_level)
	require("ibl").setup(opts)

	dofile(vim.g.base46_cache .. "blankline")
	require("ibl.highlights").setup()
end

return M

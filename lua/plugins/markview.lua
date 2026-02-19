---@type LazySpec
return {
	"OXY2DEV/markview.nvim",
	lazy = false,
	---@type markview.config
	opts = {
		preview = {
			filetypes = { "markdown", "Avante", "codecompanion" },
			ignore_buftypes = {},
			enable = true,
		},
	},
}

---@type LazyPluginSpec
return {
	"OXY2DEV/markview.nvim",
	lazy = false,
	-- enabled = false,
	dev = true,
	ft = { "markdown", "Avante", "codecompanion", "snacks_notif" },
	---@type markview.config
	opts = {
		preview = {
			filetypes = { "markdown", "Avante", "codecompanion", "snacks_notif" },
			-- ignore_buftypes = {},
		},
		experimental = { fancy_comments = true },
		markdown = { block_quotes = { enable = true }, code_blocks = { style = "simple" } },
		markdown_inline = { inline_codes = { padding_left = "", padding_right = "" } },
	},
	config = true,
}

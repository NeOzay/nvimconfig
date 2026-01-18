---@type LazySpec
return {
	"stevearc/conform.nvim",
	event = "BufWritePre",
	opts = {
		formatters_by_ft = {
			lua = { "stylua" },
			python = { "ruff_format", "ruff_organize_imports" },
		},

		format_on_save = {
			timeout_ms = 500,
			lsp_fallback = true,
		},

		formatters = {
			ruff_format = {
				command = "ruff",
				args = { "format", "--stdin-filename", "$FILENAME", "-" },
			},
			ruff_organize_imports = {
				command = "ruff",
				args = { "check", "--select", "I", "--fix", "--stdin-filename", "$FILENAME", "-" },
			},
		},
	},
}

---@type vim.lsp.Config
return {
	filetypes = { "rust" },

	root_dir = function(bufnr, on_dir)
		local root = vim.fs.root(bufnr, { "Cargo.toml", "Cargo.lock", ".git" })
		on_dir(root or vim.fn.getcwd())
	end,

	settings = {
		["rust-analyzer"] = {
			checkOnSave = true,
			check = {
				command = "clippy",
			},
			inlayHints = {
				bindingModeHints = { enable = false },
				chainingHints = { enable = true },
				closingBraceHints = { enable = true, minLines = 25 },
				closureReturnTypeHints = { enable = "never" },
				lifetimeElisionHints = { enable = "never" },
				parameterHints = { enable = true },
				typeHints = { enable = true },
			},
			procMacro = {
				enable = true,
			},
		},
	},
}

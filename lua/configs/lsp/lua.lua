---@type vim.lsp.Config
local M = {}

M.name = "emmylua_ls"

M.filetypes = { "lua" }

M.settings = {
	Lua = {
		runtime = { version = "LuaJIT" },
		workspace = {
			library = {
				vim.fn.expand("$VIMRUNTIME/lua"),
				vim.fn.stdpath("data") .. "/lazy/ui/nvchad_types",
				vim.fn.stdpath("data") .. "/lazy/lazy.nvim/lua/lazy",
				"${3rd}/luv/library",
			},
			checkThirdParty = false,
			workspaceRoots = {
				vim.fn.getcwd(),
			},
			ignoreDir = {},
		},
		diagnostics = {
			enable = true,
			globals = { "vim" },
		},
	},
}

return M

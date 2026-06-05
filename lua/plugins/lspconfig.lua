---@type LazySpec
return {
	"neovim/nvim-lspconfig",
	event = "VeryLazy",
	config = function()
		require("lsp").setup()
	end,
}

---@type LazySpec
return {
	"neovim/nvim-lspconfig",
	lazy = false,
	config = function()
		require("lsp").setup()
	end,
}

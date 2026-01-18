---@type LazySpec
return {
	"nvim-treesitter/nvim-treesitter",
	branch = "main",
	lazy = false,
	build = ":TSUpdate",
	opts = function() end,
	config = function()
		require("nvim-treesitter").setup()
	end,
}

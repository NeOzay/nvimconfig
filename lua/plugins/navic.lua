---@type LazySpec
return {
	"SmiteshP/nvim-navic",
	lazy = false,
	opts = { highlight = true },
	config = function(_, opts)
		dofile(vim.g.base46_cache .. "navic")
		require("nvim-navic").setup(opts)
	end,
}

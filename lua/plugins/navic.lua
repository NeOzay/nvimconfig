---@type LazySpec
return {
	"SmiteshP/nvim-navic",
	lazy = false,
	opts = { highlight = true },
	config = function(_, opts)
		require("nvim-navic").setup(opts)
	end,
}

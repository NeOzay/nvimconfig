---@type LazySpec
return {
	"NeOzay/lualine.nvim",
	dependencies = { "nvim-tree/nvim-web-devicons" },
	dev = true,
	event = "VeryLazy",
	config = function()
		require("lualine-conf").setup()
	end,
}

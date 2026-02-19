---@type LazySpec
return {
	{
		"yetone/avante.nvim",
		build = "make",
		enabled = false,
		event = "VeryLazy",
		version = false,
		---@module 'avante'
		---@type avante.Config
		opts = {
			provider = "copilot",
			providers = {
				copilot = {
					model = "gpt-5",
				},
			},
			-- web_search_engine = {
			-- 	-- provider = "google", -- tavily, serpapi, google, kagi, brave, or searxng
			-- },
		},
		dependencies = {
			"nvim-lua/plenary.nvim",
			"MunifTanjim/nui.nvim",
			"nvim-treesitter/nvim-treesitter",
			"zbirenbaum/copilot.lua",
			{ "HakonHarnes/img-clip.nvim", event = "VeryLazy", opts = {} },
		},
	},
}

Userautocmd("FileType", {
	pattern = "codecompanion",
	callback = function()
		vim.defer_fn(function()
			vim.cmd("Markvie attach")
		end, 10)
	end,
})

---@type LazySpec
return {
	{
		"olimorris/codecompanion.nvim",
		dependencies = {
			"nvim-lua/plenary.nvim",
			"nvim-treesitter/nvim-treesitter",
			"zbirenbaum/copilot.lua",
		},
		cmd = {
			"CodeCompanion",
			"CodeCompanionChat",
			"CodeCompanionActions",
			"CodeCompanionCmd",
		},
		keys = {
			{
				"<leader>ca",
				"<cmd>CodeCompanionChat Toggle<cr>",
				mode = { "n", "v" },
				desc = "CodeCompanion - Toggle Chat",
			},
			{
				"<leader>cp",
				"<cmd>CodeCompanionActions<cr>",
				mode = { "n", "v" },
				desc = "CodeCompanion - Actions Palette",
			},
			{ "<leader>ci", "<cmd>CodeCompanionChat Add<cr>", mode = "v", desc = "CodeCompanion - Add to Chat" },
		},
		opts = {
			display = {
				action_palette = {
					width = 95,
					height = 10,
					prompt = "Prompt ", -- Prompt used for interactive LLM calls
					provider = "snacks", -- Can be "default", "telescope", "fzf_lua", "mini_pick" or "snacks". If not specified, the plugin will autodetect installed providers.
					opts = {
						show_preset_actions = true, -- Show the preset actions in the action palette?
						show_preset_prompts = true, -- Show the preset prompts in the action palette?
						title = "CodeCompanion actions", -- The title of the action palette
					},
				},
			},
			adapters = {
				copilot = function()
					return require("codecompanion.adapters").extend("copilot", {
						schema = {
							model = {
								default = "gpt-5-codex",
							},
						},
					})
				end,
			},
			strategies = {
				chat = {
					adapter = "copilot",
				},
				inline = {
					adapter = "copilot",
				},
				cmd = {
					adapter = "copilot",
				},
			},
		},
	},
}

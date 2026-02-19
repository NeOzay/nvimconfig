---@type LazySpec
return {
	{
		"CopilotC-Nvim/CopilotChat.nvim",
		enabled = false,
		dependencies = {
			"zbirenbaum/copilot.lua",
			"nvim-lua/plenary.nvim",
		},
		cmd = {
			"CopilotChat",
			"CopilotChatOpen",
			"CopilotChatToggle",
			"CopilotChatExplain",
			"CopilotChatReview",
			"CopilotChatFix",
			"CopilotChatOptimize",
			"CopilotChatDocs",
			"CopilotChatTests",
			"CopilotChatCommit",
		},
		keys = {
			{ "<leader>ca", "<cmd>CopilotChatToggle<cr>", desc = "CopilotChat - Toggle" },
			{
				"<leader>ce",
				"<cmd>CopilotChatExplain<cr>",
				mode = { "n", "v" },
				desc = "CopilotChat - Explain",
			},
			{
				"<leader>cr",
				"<cmd>CopilotChatReview<cr>",
				mode = { "n", "v" },
				desc = "CopilotChat - Review",
			},
			{
				"<leader>cf",
				"<cmd>CopilotChatFix<cr>",
				mode = { "n", "v" },
				desc = "CopilotChat - Fix",
			},
		},
		opts = {},
	},
}

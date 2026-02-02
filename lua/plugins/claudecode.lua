---@type LazyPluginSpec
return {
	"coder/claudecode.nvim",
	-- enabled = false,
	dependencies = { "folke/snacks.nvim" },
	lazy = false,
	config = function()
		require("claudecode").setup({
			terminal = {
				provider = "snacks",
				snacks_win_opts = {
					position = "float",
					width = 0.8,
					height = 0.8,
					border = "rounded",
				},
			},
		})
	end,
	keys = {
		{ "<leader>ac", "<cmd>ClaudeCode<cr>", desc = "Toggle Claude Code" },
		{ "<leader>as", "<cmd>ClaudeCodeSend<cr>", mode = "v", desc = "Send to Claude Code" },
	},
}

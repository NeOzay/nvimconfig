local opts = {
	terminal = {
		provider = "snacks",
		-- provider = "none",
		---@type snacks.win.Config|{}
		snacks_win_opts = {
			position = "right",
			width = 0.4,
			height = 0.8,
			border = "rounded",
			keys = {
				hide = {
					"<A-c>",
					function(self)
						self:hide()
					end,
					mode = "t",
				},
				term_normal = {
					"<esc>",
					function(self)
						self.esc_timer = self.esc_timer or vim.uv.new_timer()
						if self.esc_timer:is_active() then
							self.esc_timer:stop()
							vim.cmd("stopinsert")
						else
							self.esc_timer:start(200, 0, function() end)
							return "<esc>"
						end
					end,
					mode = "t",
					expr = true,
					desc = "Double escape to normal mode",
				},
			},
		},
	},
	diff_opts = {
		layout = "vertical", -- "vertical" (default), "horizontal", or "unified"
		-- "unified": VS Code-style unified diff in a single buffer with deleted
		--   (red/strikethrough) and added (green) lines interleaved. Requires
		--   Neovim >= 0.9.0. Highlight groups are customizable: ClaudeCodeInlineDiffAdd,
		--   ClaudeCodeInlineDiffDelete, ClaudeCodeInlineDiffAddSign, ClaudeCodeInlineDiffDeleteSign.
		open_in_new_tab = true,
		keep_terminal_focus = false, -- If true, moves focus back to terminal after diff opens
		hide_terminal_in_new_tab = false,
		auto_resize_terminal = true, -- Let the plugin manage the terminal width across the diff lifecycle; set false to own it via the User autocmds below
		-- on_new_file_reject = "keep_empty", -- "keep_empty" or "close_window"

		-- Legacy aliases (still supported):
		-- vertical_split = true,
		-- open_in_current_tab = true,
	},
}
---@type LazyPluginSpec
return {
	"coder/claudecode.nvim",
	-- enabled = false,
	lazy = false,
	opts = opts,
	keys = {
		{ "<leader>a", nil, desc = "AI/Claude Code" },
		{ "<A-c>", "<cmd>ClaudeCode<cr>", desc = "Toggle Claude Code" },
		-- { "<leader>ac", "<cmd>ClaudeCode<cr>", desc = "Toggle Claude" },
		-- { "<leader>af", "<cmd>ClaudeCodeFocus<cr>", desc = "Focus Claude" },
		-- { "<leader>ar", "<cmd>ClaudeCode --resume<cr>", desc = "Resume Claude" },
		-- { "<leader>aC", "<cmd>ClaudeCode --continue<cr>", desc = "Continue Claude" },
		{ "<leader>am", "<cmd>ClaudeCodeSelectModel<cr>", desc = "Select Claude model" },
		{ "<leader>ab", "<cmd>ClaudeCodeAdd %<cr>", desc = "Add current buffer" },
		{ "<leader>as", "<cmd>ClaudeCodeSend<cr>", mode = "v", desc = "Send to Claude" },
		{
			"<leader>as",
			"<cmd>ClaudeCodeTreeAdd<cr>",
			desc = "Add file",
			ft = { "NvimTree", "neo-tree", "oil", "minifiles", "netrw" },
		},
		-- Diff management
		{ "<leader>aa", "<cmd>ClaudeCodeDiffAccept<cr>", desc = "Accept diff" },
		{ "<leader>ad", "<cmd>ClaudeCodeDiffDeny<cr>", desc = "Deny diff" },
	},
}

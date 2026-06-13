---@type LazyPluginSpec[]
return {
	{
		"zbirenbaum/copilot.lua",
		cmd = "Copilot",
		event = "InsertEnter",
		build = function()
			require("utils.copilot_termux_patch").patch()
		end,
		dependencies = {
			{
				"copilotlsp-nvim/copilot-lsp",
				init = function()
					vim.g.copilot_nes_debounce = 500
					vim.lsp.enable("copilot_ls")
					vim.keymap.set("n", "<tab>", function()
						local bufnr = vim.api.nvim_get_current_buf()
						if vim.b[bufnr].nes_state then
							local nes = require("copilot-lsp.nes")
							return nes.walk_cursor_start_edit()
								or (nes.apply_pending_nes() and nes.walk_cursor_end_edit())
								or nil
						end
						return "<C-i>"
					end, { desc = "Accept Copilot NES suggestion", expr = true })
				end,
			},
		},
		opts = {
			suggestion = {
				panel = { enabled = false },
				enabled = true,
				auto_trigger = true,
				keymap = {
					accept = "<tab>",
					accept_word = "<S-Right>",
					accept_line = "<C-Right>",
					next = "<C-Up]>",
					prev = "<C-Down>",
					dismiss = "<esc>",
				},
			},
			panel = { enabled = false },
			nes = {
				enabled = true,
				auto_trigger = true,
				keymap = {
					accept_and_goto = false,
					accept = false,
					dismiss = "<C-Esc>",
				},
			},
		},
		config = function(_, opts)
			require("copilot").setup(opts)
			vim.api.nvim_create_autocmd("User", {
				pattern = "BlinkCmpMenuOpen",
				callback = function() vim.b.copilot_suggestion_hidden = true end,
			})
			vim.api.nvim_create_autocmd("User", {
				pattern = "BlinkCmpMenuClose",
				callback = function() vim.b.copilot_suggestion_hidden = false end,
			})
		end,
	},
	{
		"giuxtaposition/blink-cmp-copilot",
		dependencies = { "zbirenbaum/copilot.lua" },
		event = "InsertEnter",
	},
}

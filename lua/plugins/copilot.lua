-- ===== ANCIEN CODE (commenté) =====
--[[
local function on_menu_opened()
	vim.b.copilot_suggestion_hidden = true
end

local function on_menu_closed()
	vim.b.copilot_suggestion_hidden = false
end

local function copilot_config()
	require("copilot").setup()
	local cmp = require("cmp")
	cmp.event:on("menu_opened", on_menu_opened)
	cmp.event:on("menu_closed", on_menu_closed)
end

local function copilot_cmp_config()
	require("copilot_cmp").setup()
end

---@type LazySpec[]
return {
	{
		"zbirenbaum/copilot.lua",
		cmd = "Copilot",
		event = "InsertEnter",
		config = copilot_config,
	},
	{
		"zbirenbaum/copilot-cmp",
		dependencies = { "zbirenbaum/copilot.lua" },
		event = "InsertEnter",
		config = copilot_cmp_config,
	},
}
--]]

local function setup(_, opts)
	require("copilot").setup(opts)

	vim.api.nvim_create_autocmd("User", {
		pattern = "BlinkCmpMenuOpen",
		callback = function()
			vim.b.copilot_suggestion_hidden = true
		end,
	})

	vim.api.nvim_create_autocmd("User", {
		pattern = "BlinkCmpMenuClose",
		callback = function()
			vim.b.copilot_suggestion_hidden = false
		end,
	})
end

---@type LazyPluginSpec[]
return {
	{
		"zbirenbaum/copilot.lua",
		cmd = "Copilot",
		event = "InsertEnter",
		dependencies = {
			{
				"copilotlsp-nvim/copilot-lsp",
				init = function()
					vim.g.copilot_nes_debounce = 500
					vim.lsp.enable("copilot_ls")
					vim.keymap.set("n", "<tab>", function()
						local bufnr = vim.api.nvim_get_current_buf()
						local state = vim.b[bufnr].nes_state
						if state then
							local _ = require("copilot-lsp.nes").walk_cursor_start_edit()
								or (
									require("copilot-lsp.nes").apply_pending_nes()
									and require("copilot-lsp.nes").walk_cursor_end_edit()
								)
							return nil
						else
							return "<C-i>"
						end
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
				enabled = false,
				auto_trigger = true,
				keymap = {
					accept_and_goto = false,
					accept = false,
					dismiss = "<C-Esc>",
				},
			},
		},
		config = setup,
	},
	{
		"giuxtaposition/blink-cmp-copilot",
		dependencies = { "zbirenbaum/copilot.lua" },
		event = "InsertEnter",
	},
}

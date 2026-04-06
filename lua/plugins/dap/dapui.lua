-- Alternative désactivée : rcarriga/nvim-dap-ui
-- Pour réactiver, commenter dap-view.lua et décommenter ce require dans init.lua.

---@type LazySpec
return {
	"rcarriga/nvim-dap-ui",
	dependencies = { "nvim-neotest/nvim-nio" },
	keys = {
		{
			"<leader>du",
			function()
				require("dapui").toggle()
			end,
			desc = "DAP UI Toggle",
		},
		{
			"<leader>de",
			function()
				require("dapui").eval()
			end,
			desc = "DAP Eval",
			mode = { "n", "v" },
		},
	},
	config = function()
		local dap = require("dap")
		local dapui = require("dapui")

		---@diagnostic disable-next-line
		dapui.setup({
			controls = {
				element = "watches",
				enabled = true,
				icons = {
					disconnect = "",
					pause = "",
					play = "",
					run_last = "",
					step_back = "",
					step_into = "",
					step_out = "",
					step_over = "",
					terminate = "",
				},
			},
			icons = { expanded = "▾", collapsed = "▸", current_frame = "▸" },
			mappings = {
				expand = { "<CR>", "<2-LeftMouse>" },
				open = "o",
				remove = "d",
				edit = "e",
				repl = "r",
				toggle = "t",
			},
			layouts = {
				{
					elements = {
						{ id = "scopes", size = 0.25 },
						{ id = "breakpoints", size = 0.25 },
						{ id = "stacks", size = 0.25 },
						{ id = "watches", size = 0.25 },
					},
					position = "left",
					size = 30,
				},
				-- {
				-- 	elements = {
				-- 		{ id = "repl", size = 0.5 },
				-- 		{ id = "console", size = 0.5 },
				-- 	},
				-- 	position = "bottom",
				-- 	size = 10,
				-- },
			},
			floating = {
				border = "rounded",
				mappings = {
					close = { "q", "<Esc>" },
				},
			},
		})

		dap.listeners.after.event_initialized["dapui_config"] = function()
			dapui.open()
		end
		dap.listeners.before.event_terminated["dapui_config"] = function()
			dapui.close()
		end
		dap.listeners.before.event_exited["dapui_config"] = function()
			dapui.close()
		end
	end,
}

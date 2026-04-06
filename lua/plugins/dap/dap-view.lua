---@diagnostic disable: missing-fields
---@type LazyPluginSpec
return {
	"igorlfs/nvim-dap-view",

	---@type dapview.Config
	opts = {
		auto_toggle = true,
		winbar = {
			controls = {
				enabled = true,
			},
		},
		windows = {
			position = "below",
			size = 0.2,
			terminal = {
				position = "below",
				size = 0.4,
				hide = { "debugpy" },
			},
		},
	},

	keys = {
		{
			"<leader>du",
			function()
				require("dap-view").toggle()
			end,
			desc = "DAP View Toggle",
		},
		{
			"<leader>de",
			function()
				require("dap-view").add_expr()
			end,
			desc = "DAP Watch Expression",
			mode = { "n", "v" },
		},
	},
}

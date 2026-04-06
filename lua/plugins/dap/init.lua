local breakpoints = require("plugins.dap.breakpoints")

local function init()
	-- Signes pour les breakpoints (définis au démarrage pour statuscol)
	vim.fn.sign_define("DapBreakpoint", { text = "●", texthl = "DapBreakpoint", linehl = "", numhl = "" })
	vim.fn.sign_define(
		"DapBreakpointCondition",
		{ text = "◐", texthl = "DapBreakpointCondition", linehl = "", numhl = "" }
	)
	vim.fn.sign_define("DapLogPoint", { text = "◆", texthl = "DapLogPoint", linehl = "", numhl = "" })
	vim.fn.sign_define("DapStopped", { text = "▶", texthl = "DapStopped", linehl = "DapStoppedLine", numhl = "" })
	vim.fn.sign_define(
		"DapBreakpointRejected",
		{ text = "○", texthl = "DapBreakpointRejected", linehl = "", numhl = "" }
	)

	-- Autocmds pour la persistance des breakpoints
	local augroup = vim.api.nvim_create_augroup("DapBreakpointsPersistence", { clear = true })

	vim.api.nvim_create_autocmd("VimLeavePre", {
		group = augroup,
		callback = breakpoints.save,
	})

	vim.api.nvim_create_autocmd("BufReadPost", {
		group = augroup,
		callback = function()
			-- Délai pour s'assurer que dap est chargé
			vim.defer_fn(breakpoints.load_for_buffer, 100)
		end,
	})
end

local function config()
	local dap = require("dap")

	-- Configuration Python via nvim-dap-python (debugpy installé via Mason)
	require("dap-python").setup(vim.fn.stdpath("data") .. "/mason/packages/debugpy/venv/bin/python")
	-- uv crée .venv/ dans le projet → détecté automatiquement par nvim-dap-python

	-- Configuration de l'adaptateur pour Neovim (one-small-step-for-vimkind)
	dap.adapters.nlua = function(callback, conf)
		callback({
			type = "server",
			host = conf.host or "127.0.0.1",
			port = conf.port or 8086,
		})
	end

	dap.configurations.lua = {
		{
			type = "nlua",
			request = "attach",
			name = "Attach to running Neovim instance",
		},
	}
end

---@type "igorlfs/nvim-dap-view"|"rcarriga/nvim-dap-ui"
local DEBUGUI = "rcarriga/nvim-dap-ui"

---@type LazySpec
return {
	DEBUGUI == "igorlfs/nvim-dap-view" and require("plugins.dap.dap-view")
		or DEBUGUI == "rcarriga/nvim-dap-ui" and require("plugins.dap.dapui"), -- alternative désactivée
	{
		"mfussenegger/nvim-dap",
		dependencies = {
			"mfussenegger/nvim-dap-python",
			"jbyuki/one-small-step-for-vimkind",
			DEBUGUI,
		},
		init = init,
		keys = {
			-- Contrôles de débogage
			{
				"<F5>",
				function()
					require("dap").continue()
				end,
				desc = "DAP Continue",
			},
			{
				"<F10>",
				function()
					require("dap").step_over()
				end,
				desc = "DAP Step Over",
			},
			{
				"<F11>",
				function()
					require("dap").step_into()
				end,
				desc = "DAP Step Into",
			},
			{
				"<F12>",
				function()
					require("dap").step_out()
				end,
				desc = "DAP Step Out",
			},
			{
				"<leader>db",
				function()
					require("dap").toggle_breakpoint()
				end,
				desc = "DAP Toggle Breakpoint",
			},
			{
				"<leader>dB",
				function()
					require("dap").set_breakpoint(vim.fn.input("Breakpoint condition: "))
				end,
				desc = "DAP Conditional Breakpoint",
			},
			{
				"<leader>dl",
				function()
					require("dap").set_breakpoint(nil, nil, vim.fn.input("Log point message: "))
				end,
				desc = "DAP Log Point",
			},
			{
				"<leader>dr",
				function()
					require("dap").repl.open()
				end,
				desc = "DAP Open REPL",
			},
			{
				"<leader>dL",
				function()
					require("dap").run_last()
				end,
				desc = "DAP Run Last",
			},
			-- Commandes spécifiques pour déboguer Neovim
			{
				"<leader>ds",
				function()
					require("osv").launch({ port = 8086 })
				end,
				desc = "DAP Start Neovim Server (debuggee)",
			},
			{
				"<leader>dS",
				function()
					require("osv").run_this()
				end,
				desc = "DAP Run current file in debuggee",
			},
			-- Python (nvim-dap-python)
			{
				"<leader>dpm",
				function()
					require("dap-python").test_method()
				end,
				desc = "DAP Python: test method",
				ft = "python",
			},
			{
				"<leader>dpc",
				function()
					require("dap-python").test_class()
				end,
				desc = "DAP Python: test class",
				ft = "python",
			},
			{
				"<leader>dps",
				function()
					require("dap-python").debug_selection()
				end,
				desc = "DAP Python: debug selection",
				ft = "python",
				mode = "v",
			},
		},
		config = config,
	},
}

local DapDisabledBreakpoints = require("shared_data").DapDisabledBreakpoints
local disabled_ns = require("shared_data").disabled_ns

---@namespace Ozay
---============================================================================
--- Persistance des breakpoints DAP par workspace
---============================================================================
---
--- Structure de sauvegarde (JSON):
--- {
---   "active": {
---     "/chemin/fichier.lua": {
---       "10": { "condition": null, "hit_condition": null, "log_message": null },
---       "25": { "condition": "x > 5", ... }
---     }
---   },
---   "disabled": { ... même structure ... }
--- }
---
--- Fichiers stockés dans: ~/.local/share/nvim/dap_breakpoints/<hash>.json
--- où <hash> est un hash SHA256 tronqué du chemin du workspace.

---@class Dap.BreakpointOpts
---@field condition? string Condition pour déclencher le breakpoint
---@field hit_condition? string Condition sur le nombre de hits
---@field log_message? string Message à logger au lieu de s'arrêter

---@alias Dap.FileBreakpoints table<string, Dap.BreakpointOpts> { [line_str]: opts }
---@alias Dap.BreakpointsStore table<string, Dap.FileBreakpoints?> { [filepath]: { [line]: opts } }

---@class Dap.SavedData
---@field active Dap.BreakpointsStore Breakpoints actifs
---@field disabled Dap.BreakpointsStore Breakpoints désactivés

--- Retourne le chemin du fichier de sauvegarde pour le workspace courant.
--- Crée le répertoire parent si nécessaire.
---@return string filepath Chemin absolu du fichier JSON
local function get_workspace_breakpoints_file()
	local cwd = vim.fn.getcwd()
	local hash = vim.fn.sha256(cwd):sub(1, 12)
	local dir = vim.fn.stdpath("data") .. "/dap_breakpoints"
	vim.fn.mkdir(dir, "p")
	return dir .. "/" .. hash .. ".json"
end

--- Lit et parse le fichier de breakpoints du workspace courant.
---@return Dap.SavedData data Structure avec les breakpoints actifs et désactivés
local function read_breakpoints_file()
	local file = io.open(get_workspace_breakpoints_file(), "r")
	if not file then
		return { active = {}, disabled = {} }
	end
	local content = file:read("*a")
	file:close()
	local ok, data = pcall(vim.fn.json_decode, content)
	if ok and data then
		return data ---@as any
	end
	return { active = {}, disabled = {} }
end

--- Sauvegarde tous les breakpoints (actifs et désactivés) dans le fichier du workspace.
--- Fusionne avec les données existantes pour conserver les breakpoints des fichiers non ouverts.
local function save_breakpoints()
	local breakpoints = require("dap.breakpoints")
	local all_bps = breakpoints.get()
	local saved = read_breakpoints_file()

	-- Mettre à jour les breakpoints actifs pour les fichiers ouverts
	for bufnr, bps in pairs(all_bps) do
		local filepath = vim.api.nvim_buf_get_name(bufnr)
		if filepath ~= "" then
			saved.active[filepath] = {}
			for _, bp in ipairs(bps) do
				saved.active[filepath][tostring(bp.line)] = {
					condition = bp.condition,
					hit_condition = bp.hitCondition,
					log_message = bp.logMessage,
				}
			end
			if vim.tbl_isempty(saved.active[filepath]) then
				saved.active[filepath] = nil
			end
		end
	end

	-- Supprimer les entrées des fichiers ouverts qui n'ont plus de breakpoints
	for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
		if vim.api.nvim_buf_is_loaded(bufnr) then
			local filepath = vim.api.nvim_buf_get_name(bufnr)
			if filepath ~= "" and not all_bps[bufnr] then
				saved.active[filepath] = nil
			end
		end
	end

	-- Copier les breakpoints désactivés depuis la variable globale
	saved.disabled = vim.deepcopy(DapDisabledBreakpoints)

	local file = io.open(get_workspace_breakpoints_file(), "w")
	if file then
		file:write(vim.fn.json_encode(saved))
		file:close()
	end
end

--- Charge les breakpoints (actifs et désactivés) pour le buffer courant.
--- Appelé automatiquement via autocmd BufReadPost.
--- Ignore les lignes qui dépassent la taille actuelle du fichier.
local function load_breakpoints_for_buffer()
	local saved = read_breakpoints_file()
	local current_file = vim.fn.expand("%:p")
	local bufnr = vim.api.nvim_get_current_buf()
	local line_count = vim.api.nvim_buf_line_count(bufnr)
	local old_cursor = vim.api.nvim_win_get_cursor(0)

	-- Charger les breakpoints actifs
	local file_bps = saved.active[current_file]
	if file_bps then
		local dap = require("dap")
		for line_str, opts in pairs(file_bps) do
			local line = tonumber(line_str)
			if line and line <= line_count then
				vim.api.nvim_win_set_cursor(0, { math.floor(line), 0 })
				dap.set_breakpoint(opts.condition, opts.hit_condition, opts.log_message)
			end
		end
	end

	-- Charger les breakpoints désactivés et afficher leurs signes
	local disabled_bps = saved.disabled[current_file]
	if disabled_bps then
		DapDisabledBreakpoints[current_file] = DapDisabledBreakpoints[current_file] or {}
		for line_str, opts in pairs(disabled_bps) do
			local line = tonumber(line_str)
			if line and line <= line_count then
				DapDisabledBreakpoints[current_file][line_str] = opts
				vim.api.nvim_buf_set_extmark(bufnr, disabled_ns, math.floor(line) - 1, 0, {
					sign_text = "○",
					sign_hl_group = "DapBreakpointRejected",
					priority = 11,
				})
			end
		end
	end
	vim.api.nvim_win_set_cursor(0, old_cursor)
end

local function config()
	local dap = require("dap")
	local dapui = require("dapui")

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

	-- Configuration de dap-ui
	---@diagnostic disable-next-line
	dapui.setup({
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
				size = 40,
			},
			{
				elements = {
					{ id = "repl", size = 0.5 },
					{ id = "console", size = 0.5 },
				},
				position = "bottom",
				size = 10,
			},
		},
		floating = {
			border = "rounded",
			mappings = {
				close = { "q", "<Esc>" },
			},
		},
	})

	-- Ouvrir/fermer automatiquement dap-ui
	dap.listeners.after.event_initialized["dapui_config"] = function()
		dapui.open()
	end
	dap.listeners.before.event_terminated["dapui_config"] = function()
		dapui.close()
	end
	dap.listeners.before.event_exited["dapui_config"] = function()
		dapui.close()
	end
end

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

	-- Sauvegarder les breakpoints à la fermeture
	vim.api.nvim_create_autocmd("VimLeavePre", {
		group = augroup,
		callback = save_breakpoints,
	})

	-- Charger les breakpoints quand un buffer est lu
	vim.api.nvim_create_autocmd("BufReadPost", {
		group = augroup,
		callback = function()
			-- Délai pour s'assurer que dap est chargé
			vim.defer_fn(load_breakpoints_for_buffer, 100)
		end,
	})
end

---@type LazySpec
return {
	"mfussenegger/nvim-dap",
	dependencies = {
		-- Interface utilisateur
		{
			"rcarriga/nvim-dap-ui",
			dependencies = { "nvim-neotest/nvim-nio" },
		},
		-- Adaptateur pour déboguer Neovim
		"jbyuki/one-small-step-for-vimkind",
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
		-- Contrôles dap-ui
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
	},
	config = config,
}

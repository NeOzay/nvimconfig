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

local M = {}

--- Sauvegarde tous les breakpoints (actifs et désactivés) dans le fichier du workspace.
--- Fusionne avec les données existantes pour conserver les breakpoints des fichiers non ouverts.
function M.save()
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
function M.load_for_buffer()
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

return M

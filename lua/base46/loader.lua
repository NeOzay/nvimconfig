-- Chargement dynamique des intégrations base46.
-- Utilise require("base46") en lazy (dans les corps de fonctions) pour éviter la circularité.

local M = {}

---@class Base46Integrations
---@field user string[] Noms d'intégrations définies par l'utilisateur (sans extension)
---@field base46 string[] Noms d'intégrations fournies par base46 (sans extension)

---@type Base46Integrations?
local _cache

-- ── Utilitaires ─────────────────────────────────────────────────────

--- Scanne un répertoire et retourne les noms de fichiers .lua (sans extension).
---@param dir string
---@param exclude? table<string, boolean>
---@return string[]
local function scan_dir(dir, exclude)
	local names = {}
	for file in vim.fs.dir(dir) do
		if file:match("%.lua$") and not (exclude and exclude[file]) then
			names[#names + 1] = file:sub(1, -5) -- remove .lua
		end
	end
	return names
end

-- ── API publique ─────────────────────────────────────────────────────

--- Retourne les intégrations disponibles (cache après premier appel).
---@return Base46Integrations
function M.get_integrations()
	if _cache then
		return _cache
	end
	local b46 = require("base46")
	local config_dir = vim.fn.stdpath("config") .. "/lua/"
	_cache = {
		user = scan_dir(config_dir .. b46.config.integrations, { ["init.lua"] = true }),
		base46 = scan_dir(config_dir .. "base46/integrations", { ["init.lua"] = true }),
	}
	return _cache
end

--- Invalide le cache des intégrations.
function M.reset_cache()
	_cache = nil
end

--- Charge et applique une intégration par nom.
--- Cherche d'abord dans le dossier user, puis dans base46/integrations.
---@param name string Nom sans extension (ex: "trouble", "snacks")
function M.load_integration(name)
	local b46 = require("base46")
	local config = b46.config

	-- 1. User integration (prioritaire)
	local ok_user, hl = pcall(require, config.integrations .. "." .. name)

	-- 2. Fallback base46 integration
	local ok_default
	if not ok_user then
		ok_default, hl = pcall(require, "base46.integrations." .. name)
	end

	if not (ok_default or ok_user) or type(hl) ~= "table" then
		return
	end

	-- Merge polish_hl du thème pour cette catégorie
	local polish_hl = b46.get_theme_tb("polish_hl")
	if polish_hl and polish_hl[name] then
		local merge_logic = ok_user and "keep" or "force"
		hl = vim.tbl_deep_extend(merge_logic, hl, polish_hl[name])
	end

	b46.loaded_integrations[name] = ok_user and "user" or "base46"

	local palette = require("base46.palette").get_palette()
	hl = require("base46.palette").resolve(hl, palette)
	for group, opts in pairs(hl) do
		vim.api.nvim_set_hl(0, group, opts)
	end
end

--- Match un nom de plugin contre les intégrations disponibles et charge les matches.
---@param plugin_name string
function M.load_matching(plugin_name)
	local integrations = M.get_integrations()
	local escape = require("utils").escape_pattern
	for _, list in pairs(integrations) do
		for _, name in ipairs(list) do
			if plugin_name:find(escape(name)) then
				M.load_integration(name)
			end
		end
	end
end

--- Enregistre les autocmds pour le chargement automatique des intégrations.
--- Idempotente : vide l'augroup avant de recréer les autocmds.
---@param config Base46Config
function M.setup_autocmds(config)
	local group = vim.api.nvim_create_augroup("Base46Integrations", { clear = true })

	-- VeryLazy : charger les intégrations pour les plugins déjà chargés
	vim.api.nvim_create_autocmd("User", {
		group = group,
		pattern = "VeryLazy",
		once = true,
		callback = function()
			for _, plugin in ipairs(require("lazy").plugins()) do
				if plugin._.loaded then
					M.load_matching(plugin.name)
				end
			end
		end,
	})

	-- LazyLoad : charger l'intégration quand un plugin se charge
	vim.api.nvim_create_autocmd("User", {
		group = group,
		pattern = "LazyLoad",
		callback = vim.schedule_wrap(function(ev)
			M.load_matching(ev.data)
		end),
	})

	-- Hot-reload : recharger à la sauvegarde d'un fichier d'intégration user
	local user_dir = vim.fn.stdpath("config") .. "/lua/" .. config.integrations
	vim.api.nvim_create_autocmd("BufWritePost", {
		group = group,
		pattern = user_dir .. "/*.lua",
		callback = function(ev)
			local name = vim.fs.basename(ev.match):gsub("%.lua$", "")
			if name == "init" then
				return
			end
			-- Invalider le cache require pour forcer le rechargement
			package.loaded[config.integrations .. "." .. name] = nil
			M.load_integration(name)
			vim.notify("Integration rechargée: " .. name, vim.log.levels.INFO)
		end,
	})
end

return M

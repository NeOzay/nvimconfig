-- base46 theme manager.
-- Forked from nvchad/base46 — no cache/compilation, direct highlight application.

---@class Base46Config
---@field theme string
---@field transparency? boolean
---@field hl_override? Base46HLTable
---@field integrations? string Module path pour les intégrations user (ex: "highlights")

---@class Base46
---@field config Base46Config
---@field loaded_integrations table<string, "user"|"base46">
local M = {}

--- Intégrations actuellement chargées (nom → source).
M.loaded_integrations = {}

---@type Base46Config
M.config = {
	theme = "sonokai",
	transparency = false,
	integrations = "highlights",
}

local colors = require("base46.colors")
local set_hl = vim.api.nvim_set_hl

---@param tb_type keyof Base46Theme
---@return table|string|nil
---@overload fun(tb_type: "base_30"): Base30Table
---@overload fun(tb_type: "base_16"): Base16Table
---@overload fun(tb_type: "base_16_terminal"): Base16TerminalTable?
---@overload fun(tb_type: "polish_hl"): table<string, Base46HLTable>?
---@overload fun(tb_type: "type"): "dark"|"light"
function M.get_theme_tb(tb_type)
	return require("themes.sonokai")[tb_type]
end

--- Résout la syntaxe spéciale de couleurs dans les tables de highlights.
--- - `"blue"` → valeur hex depuis la palette
--- - `{ "blue", -20 }` → changement de luminosité
--- - `{ "orange", "line", 80 }` → fusion de 2 couleurs
---@param tb Base46HLTable
---@return table<string, vim.api.keyset.highlight>
function M.resolve_palette_colors(tb)
	local palette = vim.tbl_extend("force", M.get_theme_tb("base_30"), M.get_theme_tb("base_16"))
	local change_lightness = colors.change_hex_lightness
	local mix = colors.mix
	local byte = string.byte
	local color_keys = { "fg", "bg", "sp" }
	local result = {}

	for group, hlgroups in pairs(tb) do
		-- Shallow copy : les valeurs sont scalaires ou des tuples qu'on remplace (jamais mutés)
		local copy = {}
		for k, v in pairs(hlgroups) do
			copy[k] = v
		end

		for i = 1, 3 do
			local key = color_keys[i]
			local val = copy[key]
			if val ~= nil then
				local valtype = type(val)
				if valtype == "string" then
					if byte(val, 1) ~= 35 and val ~= "none" and val ~= "NONE" then -- 35 = '#'
						copy[key] = palette[val]
					end
				elseif valtype == "table" then
					local n = #val
					if n == 2 then
						copy[key] = change_lightness(palette[val[1]], val[2])
					elseif n == 3 then
						copy[key] = mix(palette[val[1]], palette[val[2]], val[3])
					end
				end
			end
		end

		result[group] = copy
	end

	return result
end

-- ── Integration system ──────────────────────────────────────────────

---@class Base46Integrations
---@field user string[] Noms des intégrations user (depuis config.integrations)
---@field base46 string[] Noms des intégrations base46 (depuis base46/integrations/)

---@type Base46Integrations?
local _integrations_cache

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

--- Retourne les intégrations disponibles (cache après premier appel).
---@return Base46Integrations
function M.get_integrations()
	if _integrations_cache then
		return _integrations_cache
	end

	local config_dir = vim.fn.stdpath("config") .. "/lua/"
	_integrations_cache = {
		user = scan_dir(config_dir .. M.config.integrations, { ["init.lua"] = true }),
		base46 = scan_dir(config_dir .. "base46/integrations", { ["init.lua"] = true }),
	}
	return _integrations_cache
end

--- Charge et applique une intégration par nom.
--- Cherche d'abord dans le dossier user, puis dans base46/integrations.
---@param name string Nom sans extension (ex: "trouble", "snacks")
function M.load_integration(name)
	-- 1. User integration (prioritaire)
	local ok_user, hl = pcall(require, M.config.integrations .. "." .. name)

	-- 2. Fallback base46 integration
	local ok_default
	if not ok_user then
		ok_default, hl = pcall(require, "base46.integrations." .. name)
	end

	if not (ok_default or ok_user) or type(hl) ~= "table" then
		return
	end

	-- Merge polish_hl du thème pour cette catégorie
	local polish_hl = M.get_theme_tb("polish_hl")
	if polish_hl and polish_hl[name] then
		local merge_logic = ok_user and "keep" or "force" -- Si user integration existe, garder ses valeurs en cas de conflit, sinon écraser avec la default
		hl = vim.tbl_deep_extend(merge_logic, hl, polish_hl[name])
	end

	M.loaded_integrations[name] = ok_user and "user" or "base46"

	for group, opts in pairs(hl) do
		set_hl(0, group, opts)
	end
end

--- Match un nom de plugin contre les intégrations disponibles et charge les matches.
---@param plugin_name string
local function load_matching(plugin_name)
	local integrations = M.get_integrations()
	for _, list in pairs(integrations) do
		for _, name in ipairs(list) do
			local pattern = require("utils").escape_pattern(name)
			if plugin_name:find(pattern) then
				M.load_integration(name)
			end
		end
	end
end

--- Enregistre les autocmds pour le chargement automatique des intégrations.
local function setup_autocmds()
	-- VeryLazy : charger les intégrations pour les plugins déjà chargés
	vim.api.nvim_create_autocmd("User", {
		pattern = "VeryLazy",
		once = true,
		callback = function()
			for _, plugin in ipairs(require("lazy").plugins()) do
				if plugin._.loaded then
					load_matching(plugin.name)
				end
			end
		end,
	})

	-- LazyLoad : charger l'intégration quand un plugin se charge
	vim.api.nvim_create_autocmd("User", {
		pattern = "LazyLoad",
		callback = vim.schedule_wrap(function(ev)
			load_matching(ev.data)
		end),
	})

	-- Hot-reload : recharger à la sauvegarde d'un fichier d'intégration user
	local user_dir = vim.fn.stdpath("config") .. "/lua/" .. M.config.integrations
	vim.api.nvim_create_autocmd("BufWritePost", {
		pattern = user_dir .. "/*.lua",
		callback = function(ev)
			local name = vim.fs.basename(ev.match):gsub("%.lua$", "")
			if name == "init" then
				return
			end
			-- Invalider le cache require pour forcer le rechargement
			package.loaded[M.config.integrations .. "." .. name] = nil
			M.load_integration(name)
			vim.notify("Integration rechargée: " .. name, vim.log.levels.INFO)
		end,
	})
end

-- ── Setup ───────────────────────────────────────────────────────────

--- Configure et applique le thème, enregistre les autocmds d'intégrations.
---@param opts? Partial<Base46Config>
function M.setup(opts)
	M.config = vim.tbl_deep_extend("force", M.config, opts or {})

	vim.o.termguicolors = true
	vim.o.background = M.get_theme_tb("type") or "dark"

	-- 1. Intégrations de base (defaults + syntax + treesitter + lsp + git)
	---@type Base46HLTable
	local all_hl = require("base46.integrations.defaults")

	-- 2. polish_hl du thème (overrides par catégorie)
	local polish_hl = M.get_theme_tb("polish_hl")
	if polish_hl then
		for _, category_hl in pairs(polish_hl) do
			all_hl = vim.tbl_deep_extend("force", all_hl, category_hl)
		end
	end

	-- 3. Overrides utilisateur (syntaxe base46 : noms palette, tuples lightness/mix)
	if M.config.hl_override then
		all_hl = vim.tbl_deep_extend("force", all_hl, M.config.hl_override)
	end

	all_hl = M.resolve_palette_colors(all_hl)

	-- Appliquer tous les highlights
	for group, hl_opts in pairs(all_hl) do
		set_hl(0, group, hl_opts)
	end

	-- Couleurs terminal ANSI
	local terminal = M.get_theme_tb("base_16_terminal")
	if terminal then
		for i = 0, 15 do
			vim.g["terminal_color_" .. i] = terminal[i]
		end
	end

	-- Enregistrer les autocmds pour le chargement des intégrations per-plugin
	setup_autocmds()
end

vim.api.nvim_create_user_command("Base46Integrations", function()
	local loaded = M.loaded_integrations
	if vim.tbl_isempty(loaded) then
		vim.notify("Aucune intégration chargée", vim.log.levels.INFO)
		return
	end
	local lines = {}
	for name, source in vim.spairs(loaded) do
		lines[#lines + 1] = ("  [%s] %s"):format(source, name)
	end
	vim.notify("Intégrations chargées :\n" .. table.concat(lines, "\n"), vim.log.levels.INFO)
end, { desc = "Lister les intégrations base46 chargées" })

return M

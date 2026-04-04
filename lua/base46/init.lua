-- base46 theme manager.
-- Forked from nvchad/base46 — no cache/compilation, direct highlight application.

---@class Base46Config
---@field theme string
---@field transparency boolean
---@field hl_override Base46HLTable
---@field integrations string Module path pour les intégrations user (ex: "highlights")
---@field extended_palette table<string, string|Base46MixedColor>

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
	hl_override = {},
	integrations = "highlights",
	extended_palette = {},
}

local set_hl = vim.api.nvim_set_hl

---@param tb_type keyof Base46Theme
---@return table|string|nil
---@overload fun(tb_type: "base_30"): Base30Table
---@overload fun(tb_type: "base_16"): Base16Table
---@overload fun(tb_type: "base_16_terminal"): Base16TerminalTable?
---@overload fun(tb_type: "extended_palette"): table<string, string>?
---@overload fun(tb_type: "polish_hl"): table<string, Base46HLTable>?
---@overload fun(tb_type: "type"): "dark"|"light"
function M.get_theme_tb(tb_type)
	return require("themes.sonokai")[tb_type]
end

---@return Base46ExtendedTable
function M.get_palette()
	return require("base46.palette").get_palette()
end

--- Résout la syntaxe spéciale de couleurs dans une table de highlights.
---@param tb Base46HLTable
---@return table<string, vim.api.keyset.highlight>
function M.resolve_palette_colors(tb)
	local palette = require("base46.palette").get_palette()
	return require("base46.palette").resolve(tb, palette)
end

-- ── Setup ───────────────────────────────────────────────────────────

--- Configure et applique le thème, enregistre les autocmds d'intégrations.
---@param opts? Partial<Base46Config>
function M.setup(opts)
	M.config = vim.tbl_deep_extend("force", M.config, require("base46.config"), opts or {})

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
	all_hl = vim.tbl_deep_extend("force", all_hl, M.config.hl_override)

	all_hl = M.resolve_palette_colors(all_hl)
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

	require("base46.loader").setup_autocmds(M.config)
end

-- ── Reload ──────────────────────────────────────────────────────────

--- Vide tous les caches et recharge l'ensemble des highlights + intégrations.
function M.reload()
	local loader = require("base46.loader")
	local integrations = loader.get_integrations()

	-- Invalider les caches require des intégrations
	for _, name in ipairs(integrations.user) do
		package.loaded[M.config.integrations .. "." .. name] = nil
	end
	for _, name in ipairs(integrations.base46) do
		package.loaded["base46.integrations." .. name] = nil
	end
	package.loaded["base46.integrations.defaults"] = nil
	package.loaded["base46.config"] = nil

	-- Reset état
	loader.reset_cache()
	M.loaded_integrations = {}

	-- Réappliquer via setup (highlights + autocmds idempotents)
	M.setup()

	-- Recharger les intégrations pour les plugins déjà actifs
	for _, plugin in ipairs(require("lazy").plugins()) do
		if plugin._.loaded then
			loader.load_matching(plugin.name)
		end
	end

	vim.notify("Base46: highlights rechargés", vim.log.levels.INFO)
end

-- ── Commandes utilisateur ────────────────────────────────────────────

vim.api.nvim_create_user_command("Base46Reload", M.reload, { desc = "Recharger tous les highlights base46" })

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

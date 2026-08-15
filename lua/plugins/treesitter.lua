-- nvim-treesitter branche `main` : pas de module `highlight`/`fold`/`ensure_installed`.
-- Tout est piloté à la main depuis un unique autocmd FileType (voir `config`).

---@class Ozay.TSInstallInfo
---@field url string
---@field revision? string Commit à checkout ; HEAD si absent.
---@field branch? string Seulement si différente de la branche par défaut.
---@field location? string Sous-répertoire contenant la grammaire.
---@field generate? boolean Le dépôt ne fournit pas `src/parser.c`.
---@field queries? string Répertoire de queries à installer depuis le dépôt.

---@class Ozay.TSParser
---@field install_info Ozay.TSInstallInfo

--- Parsers absents du dépôt nvim-treesitter, ou dont on veut une autre source.
---@type table<string, Ozay.TSParser>
local custom_parsers = {
	-- Fork : les queries maison sont livrées avec la grammaire.
	luadoc = {
		install_info = {
			url = "https://github.com/NeOzay/tree-sitter-luadoc",
			branch = "master",
			queries = "queries",
		},
	},
}

local function init()
	-- nvim-treesitter émet `User TSUpdate` avant de lire sa table de parsers : c'est le
	-- seul point d'accroche pour en ajouter/redéfinir un.
	Userautocmd("User", {
		pattern = "TSUpdate",
		callback = function()
			local parsers = require("nvim-treesitter.parsers")
			for lang, info in pairs(custom_parsers) do
				parsers[lang] = info
			end
		end,
	})
end

local function config()
	local nts = require("nvim-treesitter")
	-- Enregistre `install_dir` dans le runtimepath : indispensable pour que Neovim
	-- trouve les parsers et les queries installés.
	nts.setup({})

	local ts_config = require("nvim-treesitter.config")

	---@type table<string, true>
	local installed = {}
	for _, lang in ipairs(ts_config.get_installed("parsers")) do
		installed[lang] = true
	end

	---@type table<string, true>
	local available = {}
	for _, lang in ipairs(ts_config.get_available()) do
		available[lang] = true
	end
	for lang in pairs(custom_parsers) do
		available[lang] = true
	end

	--- Buffers en attente de l'installation d'un parser, par langage.
	---@type table<string, integer[]>
	local pending = {}

	---@param buf integer
	local function enable(buf)
		if not vim.api.nvim_buf_is_valid(buf) then
			return
		end
		if not pcall(vim.treesitter.start, buf) then
			return
		end
		-- `foldexpr` est window-local-to-buffer : il faut le poser depuis chaque fenêtre
		-- affichant le buffer, d'où nvim_win_call.
		for _, win in ipairs(vim.fn.win_findbuf(buf)) do
			vim.api.nvim_win_call(win, function()
				vim.wo[0][0].foldexpr = "v:lua.vim.treesitter.foldexpr()"
				vim.wo[0][0].foldmethod = "expr"
			end)
		end
	end

	---@param lang string
	---@param buf integer
	local function install_then_enable(lang, buf)
		if pending[lang] then
			table.insert(pending[lang], buf)
			return
		end
		pending[lang] = { buf }

		nts.install(lang):await(function(err)
			local buffers = pending[lang]
			pending[lang] = nil
			if err then
				vim.notify(("treesitter: échec d'installation de %s\n%s"):format(lang, err), vim.log.levels.WARN)
				return
			end
			installed[lang] = true
			vim.schedule(function()
				for _, b in ipairs(buffers) do
					enable(b)
				end
			end)
		end)
	end

	Userautocmd("FileType", {
		callback = function(ev)
			local lang = vim.treesitter.language.get_lang(ev.match)
			if not lang then
				return
			end
			if installed[lang] then
				enable(ev.buf)
			elseif available[lang] then
				install_then_enable(lang, ev.buf)
			end
		end,
	})

	-- Les buffers déjà ouverts au moment du chargement n'émettront pas de FileType.
	for _, buf in ipairs(vim.api.nvim_list_bufs()) do
		local ft = vim.bo[buf].filetype
		local lang = ft ~= "" and vim.treesitter.language.get_lang(ft) or nil
		if lang and installed[lang] then
			enable(buf)
		end
	end
end

---@type LazyPluginSpec
return {
	"nvim-treesitter/nvim-treesitter",
	branch = "main",
	lazy = false,
	build = ":TSUpdate",
	init = init,
	config = config,
}
